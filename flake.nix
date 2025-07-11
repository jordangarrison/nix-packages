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

        # Function to get all package directories from packages/
        # This automatically discovers any directory in packages/ that contains a default.nix file
        getPackageDirs = dir:
          let
            contents = builtins.readDir dir;
            # Filter to only directories that contain a default.nix file
            packageDirs = builtins.filter
              (name:
                contents.${name} == "directory" &&
                builtins.pathExists "${dir}/${name}/default.nix"
              )
              (builtins.attrNames contents);
          in
          packageDirs;

        # Auto-discover and import all packages from the packages directory
        # Each package's default.nix file is responsible for:
        # - Choosing the appropriate builder (buildGoModule, buildNpmPackage, etc.)
        # - Specifying dependencies and build configuration
        # - Maintaining backward compatibility with existing Go packages
        packageDirs = getPackageDirs ./packages;
        packages = builtins.listToAttrs (builtins.map
          (name: {
            inherit name;
            value = pkgs.callPackage ./packages/${name} { };
          })
          packageDirs);

        # Create development shells for each package
        devShells = builtins.mapAttrs
          (name: pkg: pkgs.mkShell {
            buildInputs = with pkgs; [
              go
              git
              gnumake
              pkg-config
              # Node.js support
              nodejs
              nodePackages.npm
              nodePackages.yarn
              nodePackages.pnpm
            ];

            shellHook = ''
              echo "Development shell for ${name}"
              echo "Go version: $(go version)"
              echo "Node.js version: $(node --version)"
              echo "npm version: $(npm --version)"
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
          # Default development shell with all Go and Node.js tools
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Go tools
              go
              gopls
              gotools
              go-tools
              delve
              # Node.js tools
              nodejs
              nodePackages.npm
              nodePackages.yarn
              nodePackages.pnpm
              nodePackages.typescript
              nodePackages.typescript-language-server
              nodePackages.eslint
              nodePackages.prettier
              # Common tools
              git
              gnumake
              pkg-config
            ];

            shellHook = ''
              echo "🚀 Go & Node.js development environment ready!"
              echo "Go version: $(go version)"
              echo "Node.js version: $(node --version)"
              echo "npm version: $(npm --version)"
              echo "Available packages: ${builtins.concatStringsSep ", " (builtins.attrNames packages)}"
            '';
          };

          # Node.js-specific development shell
          nodejs = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Node.js runtime and package managers
              nodejs
              nodePackages.npm
              nodePackages.yarn
              nodePackages.pnpm

              # Development tools
              nodePackages.typescript
              nodePackages.typescript-language-server
              nodePackages.eslint
              nodePackages.prettier
              nodePackages.nodemon
              nodePackages.ts-node

              # Build tools (only stable ones)
              nodePackages.webpack
              nodePackages.webpack-cli

              # Common utilities
              git
              gnumake
              pkg-config

              # Python for node-gyp builds
              python3
            ];

            shellHook = ''
              echo "🚀 Node.js development environment ready!"
              echo "Node.js version: $(node --version)"
              echo "npm version: $(npm --version)"
              echo "yarn version: $(yarn --version)"
              echo "pnpm version: $(pnpm --version)"
              echo ""
              echo "Available package managers:"
              echo "  - npm: Node Package Manager"
              echo "  - yarn: Fast, reliable package manager"
              echo "  - pnpm: Fast, disk space efficient package manager"
              echo ""
              echo "Development tools available:"
              echo "  - TypeScript: $(tsc --version)"
              echo "  - ESLint: $(eslint --version)"
              echo "  - Prettier: $(prettier --version)"
              echo ""
              echo "To initialize a new Node.js project:"
              echo "  npm init -y"
              echo "  yarn init -y"
              echo "  pnpm init"
            '';

            # Set environment variables for Node.js development
            NODE_ENV = "development";

            # Configure npm to use a local prefix to avoid permission issues
            NPM_CONFIG_PREFIX = "$HOME/.npm-global";
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
