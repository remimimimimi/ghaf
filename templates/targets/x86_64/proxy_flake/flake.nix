# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "PROJ_NAME - Ghaf based configuration";

  nixConfig = {
    substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
      "https://ghaf-dev.cachix.org"
      "https://cache.nixos.org/"
    ];
    extra-trusted-substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
      "https://ghaf-dev.cachix.org"
      "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "cache.vedenemo.dev:8NhplARANhClUSWJyLVk4WMyy1Wb4rhmWW2u8AejH9E="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
      "ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    # Points to the copied sources of ghaf during build time.
    ghaf.url = "path:/nix/store/...-source";
  };

  outputs = {
    self,
    ghaf,
    nixpkgs,
    flake-utils,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
    ];
  in
    nixpkgs.lib.foldr nixpkgs.lib.recursiveUpdate {} [
      (flake-utils.lib.eachSystem systems (system: {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }))

      {
        nixosConfigurations.PROJ_NAME-ghaf-debug = ghaf.nixosConfigurations.generic-x86_64-debug.extendModules {
          modules = [
            ({pkgs, lib, ...}: {
              ghaf.virtualization.microvm.appvm.vms = lib.imap0 (i: {package, memory, cores}: {
                name = package;
                packages = [pkgs.${package}];
                # TODO: Automatically manage mac addresses in module.
                # XXX: Maybe cause collision. Made specifically for current lenovo-x1-carbon-gen11 configuration.
                macAddress = "02:00:00:03:${builtins.toString (8 + i)}:01";
                ramMb = memory;
                inherit cores;
              }) (builtins.fromJSON (builtins.readFile ./auto-appvms.json));
            })
          ];
        };
      }
    ];
}
