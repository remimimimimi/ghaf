{microvm}: {
  config,
  lib,
  pkgs,
  ...
}: {
  imports = let
    vm = {
      name = "emacs";
      packages = [pkgs.emacs];
      macAddress = "02:00:00:03:50:01";
      ramMb = 1024;
      cores = 1;
      borderColor = "#3E0C5C";
      cid = 50;
    };
    vmName = "${vm.name}-vm";
    index = 0;
  in [
    microvm.nixosModules.microvm
    (import ../../modules/microvm/virtualization/microvm/common/vm-networking.nix {
      inherit config lib vmName;
      inherit (vm) macAddress;
      internalIP = index + 150;
    })
    (import ../../modules/common)
    (_: let
      platform = "x86_64-linux";
      waypipePort = 1100;

      waypipeBorder =
        if vm.borderColor != null
        then "--border \"${vm.borderColor}\""
        else "";
      runWaypipe = pkgs.writeScriptBin "run-waypipe" ''
        #!${pkgs.runtimeShell} -e
        ${pkgs.waypipe}/bin/waypipe --vsock -s ${toString waypipePort} ${waypipeBorder} server "$@"
      '';
    in {
      nixpkgs.buildPlatform.system = platform;
      nixpkgs.hostPlatform.system = platform;

      environment.systemPackages =
        vm.packages
        ++ [
          pkgs.waypipe
          runWaypipe
          pkgs.tpm2-tools
          pkgs.opensc
        ];

      ghaf = {
        users.accounts.enable = true;
        profiles.debug.enable = true;

        # development = {
        #   debug.tools.enable = true;
        #   nix-setup.enable = true;
        # };
      };

      microvm = {
        optimize.enable = false;
        mem = vm.ramMb;
        vcpu = vm.cores;
        hypervisor = "qemu";
        # shares = [
        #   {
        #     tag = "waypipe-ssh-public-key";
        #     source = configHost.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
        #     mountPoint = configHost.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
        #   }
        #   {
        #     tag = "ro-store";
        #     source = "/nix/store";
        #     mountPoint = "/nix/.ro-store";
        #   }
        # ];
        # writableStoreOverlay = if config.ghaf.development.debug.tools.enable "/nix/.rw-store";

        qemu = {
          extraArgs = [
            "-M"
            "accel=kvm:tcg,mem-merge=on,sata=off"
            "-device"
            "vhost-vsock-pci,guest-cid=${toString vm.cid}"
          ];

          machine = "q35";
        };
      };
    })
    # ({
    #   lib,
    #   config,
    #   pkgs,
    #   ...
    # }: let
    #   waypipeBorder =
    #     if vm.borderColor != null
    #     then "--border \"${vm.borderColor}\""
    #     else "";
    #   runWaypipe = pkgs.writeScriptBin "run-waypipe" ''
    #     #!${pkgs.runtimeShell} -e
    #     ${pkgs.waypipe}/bin/waypipe --vsock -s ${toString configHost.ghaf.virtualization.microvm.guivm.waypipePort} ${waypipeBorder} server "$@"
    #   '';
    # in {
    #   ghaf = {
    #     users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
    #     profiles.debug.enable = lib.mkDefault configHost.ghaf.profiles.debug.enable;

    #     development = {
    #       ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
    #       debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
    #       nix-setup.enable = lib.mkDefault configHost.ghaf.development.nix-setup.enable;
    #     };
    #     systemd = {
    #       enable = true;
    #       withName = "appvm-systemd";
    #       withNss = true;
    #       withResolved = true;
    #       withPolkit = true;
    #       withDebug = configHost.ghaf.profiles.debug.enable;
    #       withHardenedConfigs = true;
    #     };
    #   };

    #   # SSH is very picky about the file permissions and ownership and will
    #   # accept neither direct path inside /nix/store or symlink that points
    #   # there. Therefore we copy the file to /etc/ssh/get-auth-keys (by
    #   # setting mode), instead of symlinking it.
    #   environment.etc.${configHost.ghaf.security.sshKeys.getAuthKeysFilePathInEtc} = sshKeysHelper.getAuthKeysSource;
    #   services.openssh = configHost.ghaf.security.sshKeys.sshAuthorizedKeysCommand;

    #   system.stateVersion = lib.trivial.release;

    #   nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
    #   nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

    #   environment.systemPackages = [
    #     pkgs.waypipe
    #     runWaypipe
    #     pkgs.tpm2-tools
    #     pkgs.opensc
    #   ];

    #   security.tpm2 = {
    #     enable = true;
    #     abrmd.enable = true;
    #   };

    #   microvm = {
    #     optimize.enable = false;
    #     mem = vm.ramMb;
    #     vcpu = vm.cores;
    #     hypervisor = "qemu";
    #     shares = [
    #       {
    #         tag = "waypipe-ssh-public-key";
    #         source = configHost.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
    #         mountPoint = configHost.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
    #       }
    #       {
    #         tag = "ro-store";
    #         source = "/nix/store";
    #         mountPoint = "/nix/.ro-store";
    #       }
    #     ];
    #     writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";

    #     qemu = {
    #       extraArgs =
    #         [
    #           "-M"
    #           "accel=kvm:tcg,mem-merge=on,sata=off"
    #           "-device"
    #           "vhost-vsock-pci,guest-cid=${toString cid}"
    #         ]
    #         ++ lib.optionals vm.vtpm.enable [
    #           "-chardev"
    #           "socket,id=chrtpm,path=/var/lib/swtpm/${vm.name}-sock"
    #           "-tpmdev"
    #           "emulator,id=tpm0,chardev=chrtpm"
    #           "-device"
    #           "tpm-tis,tpmdev=tpm0"
    #         ];

    #       machine =
    #         {
    #           # Use the same machine type as the host
    #           x86_64-linux = "q35";
    #           aarch64-linux = "virt";
    #         }
    #         .${configHost.nixpkgs.hostPlatform.system};
    #     };
    #   };
    #   fileSystems."${configHost.ghaf.security.sshKeys.waypipeSshPublicKeyDir}".options = ["ro"];

    #   imports = [../../../common];
    # })
  ];
}
