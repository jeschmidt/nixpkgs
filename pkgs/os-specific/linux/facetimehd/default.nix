{ stdenv, lib, fetchFromGitHub, kernel }:

# facetimehd is not supported for kernels older than 3.19";
assert stdenv.lib.versionAtLeast kernel.version "3.19";

let
  # Note: When updating this revision:
  # 1. Also update pkgs/os-specific/linux/firmware/facetimehd-firmware/
  # 2. Test the module and firmware change via:
  #    a. Give some applications a try (Skype, Hangouts, Cheese, etc.)
  #    b. Run: journalctl -f
  #    c. Then close the lid
  #    d. Then open the lid (and maybe press a key to wake it up)
  #    e. see if the module loads back (apps using the camera won't
  #       recover and will have to be restarted) and the camera
  #       still works.
  srcParams = if (stdenv.lib.versionAtLeast kernel.version "4.8") then
    { # Use mainline branch
      version = "unstable-2019-12-10";
      rev = "ea832ac486afb6dac9ef59aa37e90f332ab7f05a";
      sha256 = "1dg2i558hjnjnyk53xyg0ayykqaial9bm420v22s9a3khzzjnwq3";
    }
  else
    { # Use master branch (broken on 4.8)
      version = "unstable-2016-05-02";
      rev = "5a7083bd98b38ef3bd223f7ee531d58f4fb0fe7c";
      sha256 = "0d455kajvn5xav9iilqy7s1qvsy4yb8vzjjxx7bvcgp7aj9ljvdp";
    }
  ;
in

stdenv.mkDerivation rec {
  name = "facetimehd-${version}-${kernel.version}";
  version = srcParams.version;

  src = fetchFromGitHub {
    owner = "patjak";
    repo = "bcwc_pcie";
    inherit (srcParams) rev sha256;
  };

  preConfigure = ''
    export INSTALL_MOD_PATH="$out"
  '';

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  preBuild = lib.optionalString (stdenv.lib.versionAtLeast kernel.version "5.6")
  ''
    sed -i 's/ioremap_nocache/ioremap_cache/g' fthd_drv.c
  '';

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  meta = with stdenv.lib; {
    homepage = https://github.com/patjak/bcwc_pcie;
    description = "Linux driver for the Facetime HD (Broadcom 1570) PCIe webcam";
    license = licenses.gpl2;
    maintainers = with maintainers; [ womfoo grahamc kraem ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
