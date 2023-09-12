
{ lib, stdenv, pkgs, fetchFromGitHub, kernel }:

stdenv.mkDerivation rec {
  pname = "gantoninhrlt";
  version = "3.5";

  src = fetchFromGitHub {
    owner = "allanbian1017";
    repo = "i2c-ch341-usb";
    #rev = version;
    rev = "f635589bd0f14fa0ce7f72d3f57d85a77da7a0dc";
    sha256 = "sha256-+ZqUIyNmi2LBHLATINlq/KqiNHBbPqbQe+WciIsagn0=";
    # sha256 = "sha256-DCx4lOD1HnoHNkKvT4JRC+NcuAqca8mDHYcw0Ik0z0Q=";#lib.fakeHash; 
    # "DCx4lOD1HnoHNkKvT4JRC+NcuAqca8mDHYcw0Ik0z0Q";
  };

  setSourceRoot = ''
    export sourceRoot=$(pwd)/source
  '';


  buildInputs = [pkgs.which pkgs.linux.dev ];
  hardeningDisable = [ "pic" "format" ];                                             # 1
  nativeBuildInputs = kernel.moduleBuildDependencies;

	makeFlags = kernel.makeFlags ++ [
		"-C"
		"${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
		"M=$(sourceRoot)"
	];
  # makeFlags = kernel.makeFlags ++ [
  #  "KERNELRELEASE=${kernel.modDirVersion}"                                 # 3
  #   "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"    # 4
  #   "INSTALL_MOD_PATH=$(out)"    
  #    ];

  buildFlags = [ "modules" ];
  installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  installTargets = [ "modules_install" ];

  meta = with lib; {
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    broken = versionOlder kernel.version "4.14";
  };
}