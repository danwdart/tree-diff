{ 
  nixpkgs ? import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/haskell-updates.tar.gz") {},
  haskell-tools ? import (builtins.fetchTarball "https://github.com/danwdart/haskell-tools/archive/master.tar.gz") {},
  compiler ? "ghc922"
} :
let
  gitignore = nixpkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ];
  tools = haskell-tools compiler;
  lib = nixpkgs.pkgs.haskell.lib;
  myHaskellPackages = nixpkgs.pkgs.haskell.packages.${compiler}.override {
    overrides = self: super: rec {
      tree-diff = lib.dontHaddock (self.callCabal2nix "tree-diff" (gitignore ./.) {});
      semialign = lib.doJailbreak (
        self.callCabal2nixWithOptions "semialign" (builtins.fetchGit {
          url = "https://github.com/haskellari/these.git";
          rev = "6897306f3d87aa8abd45cacaa3b24f5ab1f045a5";
        }) "--subpath semialign" {}
      );
      charset = lib.doJailbreak (self.callCabal2nix "charset" (builtins.fetchGit {
        url = "https://github.com/ekmett/charset.git";
        rev = "4f456a30513212bcb7c7ec14ab25880a43a3aa18";
      }) {});
      blaze-markup = lib.doJailbreak (super.blaze-markup);
      prettyprinter-ansi-terminal = lib.dontCheck super.prettyprinter-ansi-terminal;
    };
  };
  shell = myHaskellPackages.shellFor {
    packages = p: [
      p.tree-diff
    ];
    shellHook = ''
      gen-hie > hie.yaml
      for i in $(find -type f); do krank $i; done
    '';
    buildInputs = tools.defaultBuildTools;
    withHoogle = false;
  };
  exe = lib.justStaticExecutables (myHaskellPackages.tree-diff);
in
{
  inherit shell;
  inherit exe;
  inherit myHaskellPackages;
  tree-diff = myHaskellPackages.tree-diff;
}

