# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# General tests for ghaf based on the virtual machine configuration instead of lenovo-x1-carbon-gen11.
{ self, pkgs }:
let
  system = "x86_64-linux";
in
pkgs.nixosTest {
  name = "system-test";
  nodes.ghaf-host =
    { pkgs, lib, ... }:
    {
      imports = [
        # self.inputs.nixos-generators.nixosModules.vm
        self.nixosModules.common
        self.nixosModules.desktop
        self.nixosModules.host
        self.nixosModules.microvm
        self.nixosModules.hw-x86_64-generic
      ];

      boot.zfs.devNodes = "/dev/disk/by-uuid"; # needed because /dev/disk/by-id is empty in qemu-vms
      boot.zfs.forceImportAll = true;

      virtualisation = {
        memorySize = 1024 * 16;
        diskSize = 1024 * 32;

        qemu.options = [
          "-cpu"
          "kvm64,+svm,+vmx"
        ];

        # directBoot.enable = false;
        # fileSystems = lib.mkForce { };

        useEFIBoot = true;
        efi = {
          keepVariables = true;
        };

        tpm.enable = true;

        writableStore = true;
      };

      nixpkgs.hostPlatform.system = "x86_64-linux";

      # nixpkgs.config.allowUnfree = true;
      hardware.enableRedistributableFirmware = true;
      hardware.enableAllFirmware = true;

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
        {
          from = "host";
          host.port = 2000;
          guest.port = 22;
        }
      ];

      ghaf = {
        # hardware.x86_64.common.enable = true;
        virtualization = {
          microvm-host = {
            enable = true;
            networkSupport = true;
          };

          microvm.netvm = {
            enable = true;
            extraModules = [
              (
                { modulesPath, ... }:
                {
                  # # TODO: Understand why this fixes netvm launch.
                  # imports = [
                  #   (modulesPath + "/testing/test-instrumentation.nix")
                  #   (modulesPath + "/profiles/qemu-guest.nix")
                  # ];

                  # systemd.enableStrictShellChecks = true;
                  # boot.initrd.systemd.enableStrictShellChecks = true;
                  # boot.initrd.systemd.additionalUpstreamUnits = ["sysinit.target" "default.target" "rescue.target"];
                  # systemd.additionalUpstreamSystemUnits = ["sysinit.target"];

                  # boot.initrd.systemd.targets.sysinit = {
                  #   enable = true;
                  #   description = "System initialization";
                  #   # unitConfig = {
                  #   #   BindsTo = [ "graphical-session.target" ];
                  #   #   After = [ "graphical-session-pre.target" ];
                  #   #   Wants = [ "graphical-session-pre.target" ];
                  #   # };
                  # };

                  # systemd.targets.sysinit = {
                  #   enable = true;
                  #   description = "System initialization";
                  #   # unitConfig = {
                  #   #   BindsTo = [ "graphical-session.target" ];
                  #   #   After = [ "graphical-session-pre.target" ];
                  #   #   Wants = [ "graphical-session-pre.target" ];
                  #   # };
                  # };

                  # boot.kernelParams = ["systemd.log-level=debug"];
                  # systemd.targets."multi-user".wantedBy = ["default.target"];
                  system.activationScripts.etc.text = lib.mkForce "# Set up the statically computed bits of /etc.\necho \"setting up /etc...\"\n/nix/store/sld9q6acv6jkggmgja8lxknzgspp2si7-perl-5.40.0-env/bin/perl /nix/store/rg5rf512szdxmnj9qal3wfdnpfsx38qi-setup-etc.pl /nix/store/avmfgvb2190rnx3lqixlhp35j9kf42f0-etc/etc\nls -lah /etc/systemd\nls -lah /etc/static/systemd/system\nls -lah /etc/systemd/system/\n";
                }
              )
            ];
          };
        };
        systemd = {
          withHardenedConfigs = lib.mkForce false;
          withAudit = lib.mkForce false;
        };

        host.networking.enable = true;

        # Enable all the default UI applications
        profiles = {
          # applications.enable = true;
          debug.enable = true;
          graphics.renderer = "pixman";
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
