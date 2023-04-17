{self}: let
  nixpkgs = self.inputs.nixpkgs;
  lib = nixpkgs.lib;
in rec {
  filterBaseModules = filteredBaseModules: let
    baseModulesList = import (nixpkgs + "/nixos/modules/module-list.nix");
    correctedBaseModulesList = (lib.lists.init baseModulesList) ++ [(builtins.head (lib.lists.last baseModulesList).documentation.nixos.extraModules)];
    moduleOk = modulePath: !(builtins.any (filtered: lib.hasSuffix filtered (builtins.toString modulePath)) filteredBaseModules);
  in
    builtins.filter moduleOk correctedBaseModulesList;

  # `nixpkgs.lib.nixosSystem` with ability to filter and replace base modules.
  # Args:
  # - filteredBaseModules: list of base modules path string suffixes.
  # - replacesBaseModules: attrset, in which keys are the names (string) of the baseModules and values are replacement paths to other modules (path).
  #
  # e.g.
  # ```nix
  # nixosSystemMinimal {
  #   filteredModules = ["services/x11/desktop-managers/gnome.nix"];
  #   replacedBaseModules = {
  #     "installer/tools/tools.nix" = ../modules/host/minimal/nix-tools.nix;
  #   };
  # }
  # ```
  nixosSystem = args @ {
    filteredBaseModules ? [],
    replacedBaseModules ? {},
    ...
  }:
    lib.nixosSystem ((builtins.removeAttrs args ["filteredBaseModules" "replacedBaseModules"])
      // {
        baseModules = let
          filteredBaseModules' = filteredBaseModules ++ (builtins.attrNames replacedBaseModules);
          replacedBaseModules' = builtins.attrValues replacedBaseModules;
        in
          (filterBaseModules filteredBaseModules') ++ replacedBaseModules';
      });

  # Same as function above but with some predefined filtered and replaced modules;
  # nixosSystemMinimal = args: nixosSystem
}
