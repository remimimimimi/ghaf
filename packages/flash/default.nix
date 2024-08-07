# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  coreutils,
  writeShellApplication,
  zstd,
}:
writeShellApplication {
  name = "flash-script";
  runtimeInputs = [
    coreutils
    zstd
  ];
  text = builtins.readFile ./flash.sh;
}
