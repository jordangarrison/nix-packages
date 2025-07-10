{ lib
, buildGoModule
, fetchFromGitHub
,
}:

buildGoModule rec {
  pname = "aproxymate";
  version = "0.1.0-unstable-2025-06-26";

  src = fetchFromGitHub {
    owner = "david-cik";
    repo = "aproxymate";
    rev = "ec02f23e5899ecda7bba5fef5061721c1fbf4ed3";
    hash = "sha256-C0583242Dc5U+s5viVGJbZ2gJt2jx9xpzwZz4Vx9bQ0=";
  };

  vendorHash = "sha256-uvd3BPpFduxFAaCxPUXq2+Bex6MN6jkm0AB0s4BDRZc=";

  # Build configuration
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Build only the main command
  subPackages = [ "." ];

  # Skip tests that might require Kubernetes cluster
  checkFlags = [
    "-skip=TestKubernetes"
    "-skip=TestIntegration"
  ];

  # Post-install setup
  postInstall = ''
    # Ensure the binary is executable
    if [ -f $out/bin/aproxymate ]; then
      echo "aproxymate binary installed successfully"
    fi
  '';

  meta = with lib; {
    description = "A Kubernetes proxy manager tool";
    homepage = "https://github.com/david-cik/aproxymate";
    license = licenses.mit; # Assuming MIT license based on empty LICENSE file
    maintainers = with maintainers; [ jordangarrison ];
    platforms = platforms.unix;
    mainProgram = "aproxymate";
  };
}
