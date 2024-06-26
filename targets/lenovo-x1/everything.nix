# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  microvm,
  lanzaboote,
  name,
  system,
  ...
}: let
  lenovo-x1 = generation: variant: extraModules: let
    hostConfiguration = lib.nixosSystem {
      inherit system;
      modules =
        [
          lanzaboote.nixosModules.lanzaboote
          microvm.nixosModules.host
          self.nixosModules.common
          self.nixosModules.desktop
          self.nixosModules.host
          self.nixosModules.lanzaboote
          self.nixosModules.microvm
          self.nixosModules.reference-appvms
          self.nixosModules.reference-programs
          self.nixosModules.installer

          ({pkgs, lib, ...}: {
            ghaf.installer.storage.vm = [
              (let
                drv = self.nixosConfigurations.emacs-vm.config.microvm.declaredRunner;
                closure = pkgs.closureInfo {rootPaths = [drv];};
                # Returns list of strings
                storePaths = lib.strings.splitString "\n" (lib.strings.removeSuffix "\n" (builtins.readFile "${closure}/store-paths"));
                bashArray = lib.strings.escapeShellArgs storePaths;
              in
                pkgs.runCommandLocal "emacs-dependencies" {} ''
                  mkdir -p $out/nix/{var,store}
                  cp -r ${bashArray} $out/nix/store
                  #
                  cp ${drv.outPath + "/bin/microvm-run"} $out/emacs-vm-run
                ''
              )
            ];

            # We need to add service that will mount vm_storage partition nix store to the host nix store to make everything work.
            # TODO: Add one more service to store /var on gp_storage.
            systemd.services = {
              mountVmStorageNixStore = {
                enable = true;
                after = ["zfs.target"];
                wantedBy = ["microvms.target"];
                description = "Mount vm storage nix store to host nix store.";
                serviceConfig = {
                  Type = "simple";
                  ExecStart = let
                    workDir = "/vm_storage/work";
                    hostStore = "/nix/store";
                    vmStore = "/vm_storage/nix";
                  in ''
                    mkdir -p ${workDir} && \
                    ${pkgs.coreutils}/bin/mount -t overlay overlay -olowerdir=${hostStore},upperdir=${vmStore},workdir=${workDir}  ${hostStore}
                  '';
                };

              };

              # mountVar
            };
          })

          ({
            pkgs,
            config,
            ...
          }: let
            powerControl = pkgs.callPackage ../../packages/powercontrol {};
          in {
            security.polkit = {
              enable = true;
              extraConfig = powerControl.polkitExtraConfig;
            };
            time.timeZone = "Asia/Dubai";

            ghaf = {
              # variant type, turn on debug or release
              profiles = {
                debug.enable = variant == "debug";
                release.enable = variant == "release";
              };

              # Hardware definitions
              hardware = {
                inherit generation;
                x86_64.common.enable = true;
                tpm2.enable = true;
                usb.internal.enable = true;
                usb.external.enable = true;
              };

              # Service options
              services = {
                fprint.enable = true;
                dendrite-pinecone.enable = true;
              };

              reference.appvms = {
                enable = true;
                chromium-vm = true;
                gala-vm = true;
                zathura-vm = true;
                element-vm = true;
                appflowy-vm = true;
              };

              # Virtualization options
              virtualization = {
                microvm-host = {
                  enable = true;
                  networkSupport = true;
                };

                microvm = {
                  netvm = {
                    enable = true;
                    extraModules = import ./netvmExtraModules.nix {
                      inherit lib pkgs microvm;
                      configH = config;
                    };
                  };

                  adminvm = {
                    enable = true;
                  };

                  idsvm = {
                    enable = false;
                    mitmproxy.enable = false;
                  };

                  guivm = {
                    enable = true;
                    extraModules =
                      # TODO convert this to an actual module
                      import ./guivmExtraModules.nix {
                        inherit lib pkgs self;
                        configH = config;
                      };
                  };

                  audiovm = {
                    enable = true;
                    extraModules = [
                      config.ghaf.hardware.passthrough.audiovmPCIPassthroughModule
                      config.ghaf.hardware.passthrough.audiovmKernelParams
                    ];
                  };

                  appvm = {
                    enable = true;
                    vms = config.ghaf.reference.appvms.enabled-app-vms;
                  };
                };
              };

              host = {
                networking.enable = true;
                powercontrol.enable = true;
              };

              # UI applications
              profiles = {
                applications.enable = false;
              };

              windows-launcher = {
                enable = true;
                spice = true;
              };
            };
          })
        ]
        ++ extraModules;
    };
  in {
    inherit hostConfiguration;
    name = "${name}-${generation}-${variant}";
    package = hostConfiguration.config.system.build.diskoImages;
  };
in [
  (lenovo-x1 "gen10" "debug" [self.nixosModules.disko-ab-partitions-v1 self.nixosModules.hw-lenovo-x1])
  (lenovo-x1 "gen11" "debug" [self.nixosModules.disko-ab-partitions-v1 self.nixosModules.hw-lenovo-x1])
  (lenovo-x1 "gen10" "release" [self.nixosModules.disko-ab-partitions-v1 self.nixosModules.hw-lenovo-x1])
  (lenovo-x1 "gen11" "release" [self.nixosModules.disko-ab-partitions-v1 self.nixosModules.hw-lenovo-x1])
]
