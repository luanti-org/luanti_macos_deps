#!/bin/bash

echo "This is script automate Luanti deps build process for macOS."

if [[ $# -ne 7 ]] ; then
	echo "Usage: build.sh where_deps where_install arch osver xcodever with_angle step"
	echo "  arch  - x86_64 or arm64"
	echo "  osver - 18.2 etc."
	echo "  xcodever - 18.2 etc"
	echo "  step  - all|download|untar|build"
	exit 1
fi

RUN_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

where_deps=$1
where_install=$2
arch=$3
osver=$4
xcodever=$5
with_angle=$6
step=$7

if [[ "$arch" != "x86_64" ]] && [[ "$arch" != "arm64" ]]; then
	echo "Unsuported value of arch argument: $arch"
	exit 1
fi

source $SCRIPT_DIR/deps.sh
source $SCRIPT_DIR/angle.sh

mkdir -p $where_deps
mkdir -p $where_install

where_deps=$(realpath "$where_deps")
where_install=$(realpath "$where_install")

echo "Where deps: $where_deps"
echo "Where install: $where_install"

cd $where_deps
if [ $? -ne 0 ]; then
	echo "Bad target directory $where_deps."
	exit 1
fi
DEPS_DIR=$(pwd)

if [[ "$step" == *"all"* ]] || [[ "$step" == *"download"* ]]; then
	download_macos_deps
	if [[ "$with_angle" == "yes" ]]; then
		clone_macos_angle "$SCRIPT_DIR/data"
	fi
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"untar"* ]]; then
	untar_macos_deps "$where_deps"
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"build"* ]]; then
	build_macos_deps "$arch" "$osver" "$xcodever" "$where_install" "$with_angle"
	if [[ "$with_angle" == "yes" ]]; then
		build_macos_angle "$arch" "$osver" "$xcodever" "$where_install" "$SCRIPT_DIR/data"
	fi
fi

cd $RUN_DIR
