#!/usr/bin/env bash

usage()
{
    echo "Usage: $0 [BuildArch] [UbuntuCodeName]"
    echo "BuildArch can be: arm, armel, arm64, x86"
    echo "UbuntuCodeName - optional, Code name for Ubuntu, can be: trusty(default), vivid, wily, xenial. If BuildArch is armel, jessie(default) or tizen."
    exit 1
}

__CrossDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
__InitialDir=$PWD

# base development support
__UbuntuPackages="build-essential"

# symlinks fixer
__UbuntuPackages+=" symlinks"

# CoreCLR and CoreFX dependencies
__UbuntuPackages+=" gettext"
__UbuntuPackages+=" libcurl4-openssl-dev"
__UbuntuPackages+=" libicu-dev"
__UbuntuPackages+=" libkrb5-dev"
__UbuntuPackages+=" liblttng-ust-dev"
__UbuntuPackages+=" libssl-dev"
__UbuntuPackages+=" libunwind8-dev"
__UbuntuPackages+=" zlib1g-dev"

if [ -z "$LLVM_ARM_HOME" ]; then
    __LLDB_Package="lldb-3.6-dev"
fi
 


__BuildArch=arm
__UbuntuArch=armhf
__UbuntuCodeName=trusty
__UbuntuRepo="http://ports.ubuntu.com/"
__MachineTriple=arm-linux-gnueabihf

__UnprocessedBuildArgs=
for i in "$@" ; do
    lowerI="$(echo $i | awk '{print tolower($0)}')"
    case $lowerI in
        -?|-h|--help)
            usage
            exit 1
            ;;
        arm)
            __BuildArch=arm
            __UbuntuArch=armhf
            __MachineTriple=arm-linux-gnueabihf
            ;;
        arm64)
            __BuildArch=arm64
            __UbuntuArch=arm64
            __MachineTriple=aarch64-linux-gnu
            ;;
        x86)
            __BuildArch=x86
            __UbuntuArch=i386
            __UbuntuRepo="http://archive.ubuntu.com/ubuntu"
            ;;
        armel)
            __BuildArch=armel
            __UbuntuArch=armel
            __UbuntuRepo="http://ftp.debian.org/debian/"
            __MachineTriple=arm-linux-gnueabi
            __UbuntuCodeName=jessie
            ;;
        vivid)
            if [ "$__UbuntuCodeName" != "jessie" ]; then
                __UbuntuCodeName=vivid
            fi
            ;;
        wily)
            if [ "$__UbuntuCodeName" != "jessie" ]; then
                __UbuntuCodeName=wily
            fi
            ;;
        xenial)
            if [ "$__UbuntuCodeName" != "jessie" ]; then
                __UbuntuCodeName=xenial
            fi
            ;;
        jessie)
            __UbuntuCodeName=jessie
            __UbuntuRepo="http://ftp.debian.org/debian/"
            ;;
        tizen)
            if [ "$__BuildArch" != "armel" ]; then
                echo "Tizen is available only for armel"
                usage;
                exit 1;
            fi
            __UbuntuCodeName=
            __UbuntuRepo=
            __Tizen=tizen
            ;;
        *)
            __UnprocessedBuildArgs="$__UnprocessedBuildArgs $i"
            ;;
    esac
done

if [[ "$__BuildArch" == "arm" ]]; then
    __UbuntuPackages+=" ${__LLDB_Package:-}"
fi

if [ "$__BuildArch" == "armel" ]; then  
    __LLDB_Package="lldb-3.5-dev"
    __UbuntuPackages+=" ${__LLDB_Package:-}"
fi 

__RootfsDir="$__CrossDir/rootfs/$__BuildArch"

if [[ -n "$ROOTFS_DIR" ]]; then
    __RootfsDir=$ROOTFS_DIR
fi

umount $__RootfsDir/*
rm -rf $__RootfsDir

if [[ -n $__UbuntuCodeName ]]; then
    qemu-debootstrap --arch $__UbuntuArch $__UbuntuCodeName $__RootfsDir $__UbuntuRepo
    cp $__CrossDir/$__BuildArch/sources.list.$__UbuntuCodeName $__RootfsDir/etc/apt/sources.list
    chroot $__RootfsDir apt-get update
    chroot $__RootfsDir apt-get -f -y install
    chroot $__RootfsDir apt-get -y install $__UbuntuPackages
    chroot $__RootfsDir symlinks -cr /usr
    umount $__RootfsDir/*
elif [ "$__Tizen" == "tizen" ]; then
    ROOTFS_DIR=$__RootfsDir $__CrossDir/$__BuildArch/tizen-build-rootfs.sh
else
    echo "Unsupported target platform."
    usage;
    exit 1
fi
