{
  description = "Ambxst-themed custom OSC for mpv";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    profile = "nix";
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      axosc = pkgs.mpvScripts.buildLua {
        pname = "axosc";
        version = "0.1.0";

        src = ./.;
        scriptPath = "./src";

        meta = with nixpkgs.lib; {
          description = "Ambxst-themed custom OSC for mpv";
          homepage = "https://github.com/Passeriform/axosc";
          license = licenses.mit;
        };
      };

      default = self.packages.${system}.axosc;
    });

    overlays.default = final: prev: {
      mpvScripts =
        (prev.mpvScripts or {})
        // {
          axosc = self.packages.${final.system}.default;
        };
    };

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          statix
          deadnix
          nil
          nixd
        ];

        shellHook = ''
          export VSCODE_PROFILE="${profile}";
        '';
      };
    });
  };
}
