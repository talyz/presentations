{ pkgs ? (import <nixpkgs> {}) }:
let
  draculajs = pkgs.fetchFromGitHub {
    owner = "dracula";
    repo = "highlightjs";
    rev = "7e046d97407ba14b3f812b4c23cfc4bd921edc3e";
    hash = "sha256-ViUD/fdL/BVBGQPkS6GuxccZZWiNFa/PaZE9hz4937Y=";
  };
  qrcodejs = pkgs.fetchFromGitHub {
    owner = "davidshimjs";
    repo = "qrcodejs";
    rev = "04f46c6a0708418cb7b96fc563eacae0fbf77674";
    hash = "sha256-VcBRW13Ps5fOY4kQ1FXg2Nx7ZtT1M8i4xdcC8SUDPcw=";
  };
  org-config = pkgs.writeText "org-config.el" ''
    (load-library "ox-reveal")
    (setq org-reveal-root "file://${pkgs.nodePackages."reveal.js"}/lib/node_modules/reveal.js/")
    (setq org-reveal-highlight-css "${draculajs}/dracula.css")
    (require 'ox-extra)
    (setq org-reveal-head-preamble "<script type=\"text/javascript\" src=\"${qrcodejs}/qrcode.js\"></script>")
    (setq org-reveal-extra-script "
    var qrcodes = document.getElementsByClassName(\"qrcode\");
    for (let i = 0; i < qrcodes.length; i++) {
      new QRCode(qrcodes[i], {
        width : 300,
        height : 300
      }).makeCode(qrcodes[i].id);
    };
    ")
  '';
in
pkgs.stdenv.mkDerivation {
  name = "impermanence-nixcon-2023";
  buildInputs = with pkgs; [
    ((emacsPackagesFor emacs).emacsWithPackages (p: with p; [ ox-reveal org-contrib ]))
  ];
  buildCommand = ''
    mkdir -p $out
    cp ${./impermanence.org} impermanence.org
    emacs impermanence.org --load=${org-config} --batch --eval '(message (org-reveal-export-to-html))';
    mv impermanence.html $out/
    cp ${./local.css} $out/local.css
    cp ${./cat.jpeg} $out/cat.jpeg
  '';
}
