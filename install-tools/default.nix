{ pkgs ? import <nixpkgs> {}}:
let
  python3 = (pkgs.python3.withPackages (ps: [ ps.requests ]));

  packetconfiggen = pkgs.stdenv.mkDerivation rec {
    name = "packetconfiggen";
    src = ./metadata2hardware.py;

    python = python3;

    buildInputs = [ pkgs.python3Packages.flake8 pkgs.makeWrapper];

    phases = [ "installPhase" ];

    installPhase = ''
      flake8 $src
      mkdir -p $out/bin
      echo "#!${python}/bin/python3" > $out/bin/packet-config-gen
      cat $src >> $out/bin/packet-config-gen
      chmod +x $out/bin/packet-config-gen
      wrapProgram $out/bin/packet-config-gen \
        --prefix PATH : "${pkgs.ethtool}/bin/"
    '';
  };

  dumpkeys = pkgs.stdenv.mkDerivation rec {
    name = "dumpkeys";
    src = ./metadata2hardware.py;

    python = python3;

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      echo "#!${python}/bin/python3" > $out/bin/packet-config-gen
      cat $src >> $out/bin/packet-config-gen
      chmod +x $out/bin/packet-config-gen
    '';
  };
in pkgs.stdenv.mkDerivation {
  name = "installtools";
  src = ./bin;

  inherit (pkgs) coreutils utillinux e2fsprogs zfs kexectools jq;
  inherit packetconfiggen python3;
  phonehomeconf = ./phone-home.nix;
  kexecconfig = ./kexec-config.nix;

  buildPhase = ''
    substituteAllInPlace ./notify.py
    substituteAllInPlace ./dump-keys.py
    substituteAllInPlace ./tools.sh
  '';

  installPhase = ''
    ! grep -r "@" .

    mkdir -p $out/bin
    cp -r . $out/bin
    chmod +x $out/bin/*.sh
    chmod +x $out/bin/*.py
  '';
}
