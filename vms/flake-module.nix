{inputs, lib, ...}: {
  flake.nixosConfigurations = let
    system = "x86_64-linux";
  in {
    emacs-vm = lib.nixosSystem {
      inherit system;
      modules = [
        (import ./emacs {inherit (inputs) microvm;})
      ];
    };
  };
}
