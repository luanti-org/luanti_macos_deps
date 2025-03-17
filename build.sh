#!/bin/bash

echo "This is script automate Luanti deps build process for macOS."

if [[ $# -ne 5 ]] ; then
	echo "Usage: macos_build_with_deps.sh where_deps where_install arch osver step"
	echo "  arch  - x86_64 or arm64"
	echo "  osver - 18.2 etc."
	echo "  step  - all|download|untar|clone|build"
	exit 1
fi

RUN_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

where_deps=$1
where_install=$2
arch=$3
osver=$4
step=$5

if [[ "$arch" != "x86_64" ]] && [[ "$arch" != "arm64" ]]; then
	echo "Unsuported value of arch argument: $arch"
	exit 1
fi

source $SCRIPT_DIR/deps.sh
#source $SCRIPT_DIR/angle.sh

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
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"untar"* ]]; then
	untar_macos_deps $where_deps
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"clone"* ]]; then
	echo "no angle now"
	#clone_macos_angle "$SCRIPT_DIR/data"
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"build"* ]]; then
	build_macos_deps $arch $osver "" $where_install
	#build_macos_angle $arch $osver "" $where_install "$SCRIPT_DIR/data"
fi

cd $RUN_DIR
