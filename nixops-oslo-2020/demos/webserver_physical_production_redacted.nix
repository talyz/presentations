let
  accessKeyId = "XXXXXXXXXXXXXXXXXXXX"; # Symbolic name looked up ~/.aws/credentials, fill in your own.
  region = "eu-north-1"; # You probably want to choose a region listed here: https://nixos.org/nixos/download.html#amazon-ec2
  php-host =
    { resources, lib, ... }:
    {
      deployment.targetEnv = "ec2";

      deployment.ec2 = {
        inherit accessKeyId region;
        ami = "ami-98a9ab98abobc"; # Fill in real ami id or remove if there's an official build for your region
        instanceType = "t3.small";
        ebsInitialRootDiskSize = 10;

        securityGroupIds = with resources.ec2SecurityGroups; [
          public-http-sg.name # Open up for public HTTP and HTTPS access.
          public-ssh-sg.name  # ..and public SSH access. SSH access is required for nixops to do its job.
        ];
        associatePublicIpAddress = true;
        subnetId = resources.vpcSubnets.example-subnet;

        keyPair = resources.ec2KeyPairs.stockholm;
      };

      boot.loader.grub.device = lib.mkForce "/dev/nvme0n1"; # Workaround needed for instances in the eu-north-1 region.
    };
in
{
  resources = {

    # Create an SSH keypair used to access the hosts.
    ec2KeyPairs = {
      stockholm = { inherit accessKeyId region; };
    };

    # Create a new AWS VPC (Virtual Private Cloud) - essentially an
    # entirely new, isolated network setup.
    vpc.example_vpc = {
      inherit accessKeyId region;
      name = "example";
      instanceTenancy = "default";
      enableDnsSupport = true;
      enableDnsHostnames = true;
      tags = {
        Source = "NixOps";
      };
      cidrBlock = "10.1.0.0/16";
    };

    # Create a subnet, where we can put our hosts, in our new VPC.
    vpcSubnets.example-subnet =
      { resources, ... }:
      {
        inherit accessKeyId region;
        vpcId = resources.vpc.example_vpc;
        cidrBlock = "10.1.0.0/24";
        zone = region + "a";
        mapPublicIpOnLaunch = true;
      };

    # Set up security groups, essentially firewall rules, to open up
    # access to our hosts.
    ec2SecurityGroups = {
      public-http-sg =
        { resources, ... }:
        {
          inherit accessKeyId region;
          vpcId = resources.vpc.example_vpc;
          rules = map (port: { fromPort = port; toPort = port; sourceIp = "0.0.0.0/0"; }) [
            80
            443
          ];
        };
      public-ssh-sg =
        { resources, ... }:
        {
          inherit accessKeyId region;
          vpcId = resources.vpc.example_vpc;
          rules = [{ fromPort = 22; toPort = 22; sourceIp = "0.0.0.0/0"; }];
        };
    };

    # Set up a custom route table to be able to associate the internet
    # gateway with the subnet and get internet access.
    vpcRouteTables.example-route-table =
      { resources, ... }:
      {
        inherit accessKeyId region;
        vpcId = resources.vpc.example_vpc;
      };

    # Associate the route table with the subnet.
    vpcRouteTableAssociations.example-route-table-assoc =
      { resources, ... }:
      {
        inherit accessKeyId region;
        subnetId = resources.vpcSubnets.example-subnet;
        routeTableId = resources.vpcRouteTables.example-route-table;
      };

    # Create an internet gateway.
    vpcInternetGateways.example-igw =
      { resources, ... }:
      {
        inherit accessKeyId region;
        vpcId = resources.vpc.example_vpc;
      };

    # Route all IPv4 traffic to the internet gateway. The route table
    # already has implicit local routes which take precedence over
    # this.
    vpcRoutes.example-igw-route =
      { resources, ... }:
      {
        inherit accessKeyId region;
        routeTableId = resources.vpcRouteTables.example-route-table;
        destinationCidrBlock = "0.0.0.0/0";
        gatewayId = resources.vpcInternetGateways.example-igw;
      };

    # Allocate an elastic IP to use with the load balancer. This could
    # be moved to a new host if the need arises.
    elasticIPs =
      {
        load_balancer-ip =
          {
            inherit accessKeyId region;
            vpc = true;
          };
      };
  };

  load_balancer =
    { resources, lib, ... }:
    {
      deployment.targetEnv = "ec2";
      deployment.ec2 =
        {
          inherit accessKeyId region;
          ami = "ami-98a9ab98abobc";
          instanceType = "t3.small";
          ebsInitialRootDiskSize = 10;

          subnetId = resources.vpcSubnets.example-subnet;
          elasticIPv4 = resources.elasticIPs.load_balancer-ip;
          securityGroupIds = with resources.ec2SecurityGroups; [
            public-http-sg.name
            public-ssh-sg.name
          ];
          associatePublicIpAddress = true;

          keyPair = resources.ec2KeyPairs.stockholm;
        };

      # Create a Route 53 DNS record for this host.
      deployment.route53 =
        {
          inherit accessKeyId;
          hostName = "oslodemo.xlnaudio.com";
        };

      boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
    };

  webserver1 = php-host;
  webserver2 = php-host;
}
