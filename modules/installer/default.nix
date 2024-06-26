# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.ghaf.installer = {
    storage = let
      filesOption = mkOption {
        type = types.listOf types.package;
        default = [];
        description = ''
          Files under derivation output directory will be copied to the corresponding storage partition.
        '';
      };
    in {
      vm = filesOption;
      gp = filesOption;
    };
  };
}
