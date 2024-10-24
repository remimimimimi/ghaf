# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ self, ... }:
{
  flake.checks =
    let
      # Required to do this here for `system` test.
      pkgsPerSystem =
        system:
        import self.inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "jitsi-meet-1.0.8043"
            ];
          };
        };
    in
    {
      x86_64-linux =
        let
          pkgs = pkgsPerSystem "x86_64-linux";
        in
        {
          installer = pkgs.callPackage ./installer { inherit self; };
          system = pkgs.callPackage ./system.nix { inherit self; };
        };
    };
}
