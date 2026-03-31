{
  description = "abcmidi - ABC music notation to/from MIDI conversion tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (system:
        let pkgs = pkgsFor system; in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "abcmidi";
            version = "2026-02-24";
            src = ./.;
            nativeBuildInputs = [ pkgs.autoconf ];
            buildPhase = ''
              ./configure --prefix=$out CFLAGS="-O2 -std=gnu17"
              make
            '';
            installPhase = ''
              make install DESTDIR= prefix=$out
            '';
          };
        }
      );

      devShells = forAllSystems (system:
        let pkgs = pkgsFor system; in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              gcc
              gnumake
              autoconf
            ];
            CFLAGS = "-std=gnu17";
          };
        }
      );
    };
}
