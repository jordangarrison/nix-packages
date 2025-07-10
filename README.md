# Nix Packages

A comprehensive Nix flake for building remote Go repositories with each package living in its own folder under `packages/`.

## 🚀 Quick Start

```bash
# Clone and enter the repository
git clone <your-repo-url>
cd nix-packages

# Build all packages
nix build .

# Enter development shell
nix develop

# Run a specific package
nix run .#aproxymate -- --help
```

## 📁 Structure

```
nix-packages/
├── flake.nix              # Main flake configuration
├── flake.lock             # Lockfile for reproducible builds
├── packages/              # All packages live here
│   └── aproxymate/        # Each package has its own folder
│       └── default.nix    # Package definition
└── README.md              # This file
```

## 🛠️ Available Commands

### Building Packages

```bash
# Build all packages (default)
nix build .

# Build specific package
nix build .#aproxymate

# Check what was built
ls -la result/bin/
```

### Running Packages

```bash
# Run specific package directly
nix run .#aproxymate -- --help

# Get a shell with package available
nix shell .#aproxymate

# Then use the command
aproxymate --help
```

### Development

```bash
# Enter development shell with Go tools
nix develop

# Enter package-specific development shell
nix develop .#aproxymate
```

### Inspection

```bash
# Show all available packages and outputs
nix flake show

# Show package metadata
nix show-derivation .#aproxymate
```

## 📦 Current Packages

### aproxymate

- **Description**: A Kubernetes proxy manager tool
- **Source**: <https://github.com/david-cik/aproxymate>
- **Usage**: `nix run .#aproxymate -- --help`

## ➕ Adding New Packages

### 1. Create Package Directory

```bash
mkdir -p packages/your-package-name
```

### 2. Create Package Definition

Create `packages/your-package-name/default.nix`:

```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "your-package-name";
  version = "1.0.0";  # or use unstable version

  src = fetchFromGitHub {
    owner = "github-owner";
    repo = "repo-name";
    rev = "v${version}";  # or specific commit
    hash = "sha256-PLACEHOLDER";  # Will be updated during build
  };

  vendorHash = "sha256-PLACEHOLDER";  # Will be updated during build

  # Build configuration
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "Your package description";
    homepage = "https://github.com/owner/repo";
    license = licenses.mit;  # Update as needed
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "your-package-name";
  };
}
```

### 3. Update flake.nix

Add your package to the `packages` attribute set:

```nix
packages = {
  # aproxymate - A Kubernetes proxy manager tool
  aproxymate = pkgs.callPackage ./packages/aproxymate { };
  
  # your-package-name - Your package description
  your-package-name = pkgs.callPackage ./packages/your-package-name { };
};
```

### 4. Build and Get Correct Hashes

```bash
# This will fail but give you the correct hash
nix build .#your-package-name --no-link

# Update the hash in your package definition
# Build again to get vendor hash
nix build .#your-package-name --no-link

# Update vendor hash and build successfully
nix build .#your-package-name --no-link
```

### 5. Test Your Package

```bash
# Test the package works
nix run .#your-package-name -- --help

# Verify it's included in the default build
nix build . && ls -la result/bin/
```

## 🎯 Best Practices

### Package Naming

- Use lowercase with hyphens: `my-package-name`
- Match the upstream repository name when possible
- Keep folder names consistent with package names

### Version Management

- Use tagged releases when available: `version = "1.0.0"`
- For untagged repos, use: `version = "0.1.0-unstable-YYYY-MM-DD"`
- Pin to specific commits for reproducibility

### Build Configuration

- Always include `ldflags` for smaller binaries
- Use `subPackages = [ "." ]` for single-binary packages
- Add `checkFlags` to skip problematic tests
- Include shell completions when available

### Metadata

- Provide clear descriptions
- Include upstream homepage
- Set appropriate license
- Specify the main program name

## 🔧 Development Tips

### Hash Updates

When you see hash mismatches, copy the "got" hash into your package definition:

```
error: hash mismatch in fixed-output derivation:
         specified: sha256-PLACEHOLDER
            got:    sha256-ActualHashHere
```

### Debugging Builds

```bash
# Build with verbose output
nix build .#package-name --verbose

# Enter build environment for debugging
nix develop .#package-name
```

### Testing Changes

```bash
# Quick syntax check
nix flake check

# Build all packages to ensure nothing broke
nix build .

# Test specific package
nix run .#package-name -- --version
```

## 📚 Resources

- [Nix Flakes Documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
- [buildGoModule Documentation](https://nixos.org/manual/nixpkgs/stable/#sec-language-go)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)

## 🤝 Contributing

1. Fork the repository
2. Add your package following the structure above
3. Test your changes with `nix build .#your-package`
4. Submit a pull request

## 📄 License

This flake configuration is available under the MIT License. Individual packages retain their original licenses.
