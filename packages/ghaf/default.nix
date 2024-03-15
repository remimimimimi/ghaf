# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  substituteAll,
  lib,
  python3,
  targetName,
  ghafSource,
  configPath,
}:
# with python3Packages;
substituteAll {
  dir = "bin";
  isExecutable = true;

  name = "ghaf";
  pname = "ghaf";
  src = ./ghaf.py;

  inherit python3 targetName ghafSource configPath;

  meta = with lib; {
    description = "Application that helps you managing Ghaf.";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
