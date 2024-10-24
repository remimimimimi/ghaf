# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# General tests for ghaf based on the virtual machine configuration instead of lenovo-x1-carbon-gen11.
{ pkgs, self }:
let
  testConfig = "vm-debug";
  system = "x86_64-linux";
  expectedHostname = "ghaf-host";

  cfg = self.nixosConfigurations.${testConfig};

  testingConfig = cfg.extendModules {
    modules = [
      (cfg._module.specialArgs.modulesPath + "/testing/test-instrumentation.nix")
      (cfg._module.specialArgs.modulesPath + "/profiles/qemu-guest.nix")
      (_: {
        testing.initrdBackdoor = true;
        services.openssh.enable = true;
        # https://github.com/nix-community/disko/blob/e55f9a8678adc02024a4877c2a403e3f6daf24fe/lib/interactive-vm.nix#L63
        boot.zfs.devNodes = "/dev/disk/by-uuid"; # needed because /dev/disk/by-id is empty in qemu-vms
        boot.zfs.forceImportAll = true;
      })
    ];
  };

  # FIXME: Only one attribute supported. What about ISO?
  imagePath = testingConfig.config.system.build.diskoImages + "/disk1.raw.zst";
  targetPath = "/dev/vdb";
  installScript = pkgs.callPackage ../../packages/installer { };
  installerInput = pkgs.lib.strings.escapeNixString "${targetPath}\ny\ny\n";
in
pkgs.nixosTest {
  name = "system-test";
  nodes.ghaf-host = {pkgs, ...}: {
    imports = [
      self.nixosModules.common
      self.nixosModules.desktop
      self.nixosModules.host
      self.nixosModules.microvm
      self.nixosModules.hw-x86_64-generic
    ];

    virtualisation = {
      memorySize = 1024 * 16;

      useEFIBoot = true;
      efi = {
        keepVariables = true;
      };

      tpm.enable = true;
    };

    nixpkgs.hostPlatform.system = "x86_64-linux";

    # # Increase the support for different devices by allowing the use
    # # of proprietary drivers from the respective vendors
    # nixpkgs.config = {
    #   allowUnfree = true;
    #   permittedInsecurePackages = [
    #     "jitsi-meet-1.0.8043"
    #   ];
    # };

    # nixpkgs.config.allowUnfree = true;
    # hardware.enableRedistributableFirmware = true;
    # hardware.enableAllFirmware = true;

    boot = {
      # Enable normal Linux console on the display
      kernelParams = [ "console=tty0" ];

      # To enable installation of ghaf into NVMe drives
      initrd.availableKernelModules = [
        "nvme"
        "uas"
      ];
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };

      # TODO the kernel latest is currently broken for zfs.
      # try to fix on the next update.
      kernelPackages = pkgs.linuxPackages;
    };

    virtualisation.forwardPorts = [
     { from = "host"; host.port = 2000; guest.port = 22; }
   ];

    ghaf = {
      # hardware.x86_64.common.enable = true;
      virtualization = {
        microvm-host = {
          enable = true;
          networkSupport = true;
        };

        microvm.netvm.enable = true;
      };

      host.networking.enable = true;

      # Enable all the default UI applications
      profiles = {
        # applications.enable = true;
        debug.enable = true;
        # graphics.renderer = "pixman";
      };
    };
  };

  testScript = ''
    ghaf_host.succeed("lsblk >&2")
    print(ghaf_host.succeed("tty"))
    # ghaf_host.switch_root()
    breakpoint()
    ghaf_host.shutdown()
  '';
}
// {
  inherit testingConfig;
}
