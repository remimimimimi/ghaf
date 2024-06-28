<!--
    Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
    SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Overview

This branch contains experiment on running virtual machine from the different partition. It works like that:

+ We build installed image which contains virtual machines that we want to instsall on different partition.
+ During the installation process it copies all required files to run vm on `/vm_storage` partition.
+ After installation we boot regularly in ghaf and get into ghaf-host using ssh.
+ Then we mount `/vm_storage/nix` directory on top of `/nix` via overlay file system. So original `/nix` directory is read only, it's files are merged with files in `/vm_storage/nix` and every attempt to write into `/nix` will rederect requests to `/vm_storage/nix`. 
+ After that action we can run our virtual machine, in our case this is `emacs-vm`, so just execute `/vm_storage/emacs-vm-run` using `sudo`.

# Testing pipeline

+ Build installer image `nix build .#lenovo-x1-carbon-gen11-debug-installer`;
+ Flash it to your drive;
+ Follow regular installation process;
+ Boot into newly installed ghaf;
+ Run terminal and connect to ghaf host using following command: `ssh ghaf@ghaf-host-debug` (password is `ghaf` as well);
+ Make working directory `sudo mkdir /vm_storage/work`;
+ Merge `/nix` directories via `sudo mount -t overlay overlay -olowerdir=/nix,upperdir=/vm_storage/nix,workdir=/vm_storage_work /nix`
+ Run virtual machine: `sudo /vm_storage/emacs-vm-run`;
+ Login using `ghaf` user and `ghaf` password;
+ Run emacs (`emacs` command)!

