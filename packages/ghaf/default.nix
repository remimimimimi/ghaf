# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenvNoCC,
  lib,
  python3,
  # python3Packages,
}:
# with python3Packages;
stdenvNoCC.mkDerivation {
  name = "ghaf";
  version = "0.1.0";
  propagatedBuildInputs = [
    (python3.withPackages (pythonPackages:
      with pythonPackages; [
        # consul
        # six
        # requests2
      ]))
  ];
  dontUnpack = true;
  installPhase = "install -Dm755 ${./ghaf.py} $out/bin/ghaf";

  meta = with lib; {
    description = "Application that helps you managing Ghaf.";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
