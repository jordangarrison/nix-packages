{
  description = "A comprehensive flake for building remote Go repositories";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Import all packages from the packages directory
        packages = {
          # aproxymate - A Kubernetes proxy manager tool
          aproxymate = pkgs.callPackage ./packages/aproxymate { };
        };

        # Create development shells for each package
        devShells = builtins.mapAttrs
          (name: pkg: pkgs.mkShell {
            buildInputs = with pkgs; [
              go
              git
              gnumake
              pkg-config
            ];

            shellHook = ''
              echo "Development shell for ${name}"
              echo "Go version: $(go version)"
              echo "Package info: ${pkg.meta.description or "No description available"}"
            '';
          })
          packages;

      in
      {
        # Export all packages
        packages = packages // {
          # Default package that installs all packages from packages folder
          default = pkgs.symlinkJoin {
            name = "all-packages";
            paths = builtins.attrValues packages;
            meta = with pkgs.lib; {
              description = "All packages from the packages folder";
              platforms = platforms.unix;
            };
          };
        };

        # Export development shells
        devShells = devShells // {
          # Default development shell with all Go tools
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              go
              git
              gnumake
              pkg-config
              gopls
              gotools
              go-tools
              delve
            ];

            shellHook = ''
              echo "🚀 Go development environment ready!"
              echo "Go version: $(go version)"
              echo "Available packages: ${builtins.concatStringsSep ", " (builtins.attrNames packages)}"
            '';
          };
        };

        # Export apps for easy running (excluding default since it's a collection)
        apps = builtins.mapAttrs
          (name: pkg: {
            type = "app";
            program = "${pkg}/bin/${name}";
          })
          (builtins.removeAttrs packages [ "default" ]);

        # Add some useful checks/tests
        checks = {
          # Basic build test for all packages
          build-all = pkgs.runCommand "build-all-packages" { } ''
            echo "Testing all packages build successfully..."
            ${builtins.concatStringsSep "\n" (builtins.map (name: "echo 'Package ${name}: ${packages.${name}}'") (builtins.attrNames packages))}
            touch $out
          '';
        };
      });
}
