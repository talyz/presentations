{ pkgs ? (import <nixpkgs> {}) }:

let
  lstnix = {
    pkgs = [
      (pkgs.stdenv.mkDerivation {
        pname = "lstnix";
        version = "1";
        tlType = "run";
        src = builtins.fetchurl {
          url = "https://gist.githubusercontent.com/mbbx6spp/fc29c22c6769372920dddfb68794a73a/raw/476ec5a1b5e28c7a2985b6b2bce71fc901b85312/lstnix.sty";
          sha256 = "1rx9rcjadfja93l6iyfnclx9r1hkhfzn0sb8mjf5wz50sdlvamqc";
        };
        buildCommand = ''
          mkdir -p $out/tex/latex/$pname
          cp $src $out/tex/latex/$pname/$pname.sty
        '';
      })
    ];
  };
  presentationTexlive = with pkgs.texlive;
    (combine {
      inherit scheme-medium wrapfig capt-of lstnix minted
        fvextra upquote xstring framed tcolorbox environ trimspaces;
    });
in
pkgs.stdenv.mkDerivation {
  name = "nixops-presentation-oslo-2020";
  buildInputs = with pkgs; [
    presentationTexlive
    python38Packages.pygments
  ];
  buildCommand = ''
    mkdir -p $out
    cp ${./nixops.org} nixops.org
    ${pkgs.emacs}/bin/emacs ./nixops.org --load=${../org-config.el} --batch --eval '(message (org-beamer-export-to-pdf))';
    mv nixops.pdf $out/
  '';
}
