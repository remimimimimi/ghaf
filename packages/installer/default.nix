# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  stdenvNoCC,
  makeWrapper,
  diskoInstall,
  target,
  targetName,
  ghafSource,
  diskName,
}: let
  name = "ghaf-installer";
  vmStorageDrvs = target.config.ghaf.installer.storage.vm;
  # By convention this derivation contains file structure (e.g /nix/store prefix).
  vmStoragePaths = map (drv: drv.outPath) vmStorageDrvs;
  # TODO: Copy files from all provided derivations.
  vmStoragePath = builtins.head vmStoragePaths;
in
  stdenvNoCC.mkDerivation {
    inherit name;
    src = ./.;
    nativeBuildInputs = [
      makeWrapper
    ];
    installPhase = ''
      mkdir -p $out/bin
      cp ${name}.sh $out/bin/${name}.sh
      chmod 755 $out/bin/${name}.sh
      wrapProgram $out/bin/${name}.sh \
        --set GHAF_SOURCE "${ghafSource}" \
        --set TARGET_NAME "${targetName}" \
        --set DISKO_DISK_NAME "${diskName}" \
        --set VM_STORAGE_SOURCE_PATH "${vmStoragePath}" \
        --prefix PATH : ${lib.makeBinPath [diskoInstall]}
    '';
  }
