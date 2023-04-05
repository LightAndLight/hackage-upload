{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    ipso.url = "github:LightAndLight/ipso?tag=v0.5";
  };
  outputs = { self, nixpkgs, flake-utils, nix-filter, ipso }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = import nixpkgs { inherit system; };
        ghcVersion = "927";
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            haskell.packages."ghc${ghcVersion}".ghc
            cabal-install
            (haskell-language-server.override { supportedGhcVersions = [ ghcVersion ]; })
            ipso.defaultPackage.${system}
          ];
        };

        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "hackage-upload";
          
          src = nix-filter.lib {
            root = ./.;
            include = [
              "hackage-upload"
            ];
          };
          
          buildInputs = [
            ipso.defaultPackage.${system}
            pkgs.makeWrapper
          ];
          
          buildPhase = ''
            ipso --check hackage-upload
          '';
          
          installPhase = ''
            mkdir -p $out/bin
            
            cp hackage-upload $out/bin
            chmod +x $out/bin/hackage-upload
            
            wrapProgram $out/bin/hackage-upload \
              --set-default CABAL_EXECUTABLE "${pkgs.cabal-install}/bin/cabal" \
              --set-default GHC_EXECUTABLE "${pkgs.haskell.packages."ghc${ghcVersion}".ghc}/bin/ghc" \
              --set-default FD_EXECUTABLE "${pkgs.fd}/bin/fd"
          '';
        };
      }
    );
}
