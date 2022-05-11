{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
        {
          packages.ani2ico = pkgs.stdenv.mkDerivation {
            name = "ani2ico";
            
            src = ./ani2ico;

            dontConfigure = true;
            
            installPhase = ''
              mkdir -p $out/bin
              install -m 0755 ani2ico $out/bin/ani2ico
            '';
          };
          packages.cursor-converter = pkgs.stdenv.mkDerivation {
            name = "cursor-converter";
            src = ./.;

            buildInputs = with pkgs; [
              self.packages.${system}.ani2ico
              imagemagick
              xorg.xcursorgen
            ];
            nativeBuildInputs = with pkgs; [
              makeWrapper
            ];

            dontConfigure = true;
            dontBuild = true;
            doCheck = true;

            checkPhase = ''
              ${pkgs.shellcheck}/bin/shellcheck --enable=all $src/convert.sh
            '';

            installPhase = ''
              mkdir -p $out/bin
              install -m 0755 $src/convert.sh $out/bin/cursor-converter
              wrapProgram $out/bin/cursor-converter --prefix PATH : ${pkgs.lib.makeBinPath [ self.packages.${system}.ani2ico pkgs.imagemagick pkgs.xorg.xcursorgen ]}
            '';
          };
          packages.default = self.packages.${system}.ani2ico;

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ shellcheck ];
          };
        }
    );
}
