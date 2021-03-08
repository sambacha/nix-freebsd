{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  boot.initrd.availableKernelModules = [
    "ahci" "xhci_pci" "mpt3sas" "nvme" "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams =  [ "console=ttyS1,115200n8" ];
  boot.extraModulePackages = [ ];

  hardware.enableAllFirmware = true;

  nix.maxJobs = 56;
}
