#!/bin/bash -e

clone_macos_angle() {
	datadir=$1

	depot_hash="2960e876ad78502c616e27e1a89b9e01ca77ca7e"
	angle_hash="f5a720128fb8fe77829889903007891ffc1837ec"

	git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git depot_tools
	git -C depot_tools fetch --depth 1 origin $depot_hash
	git -C depot_tools checkout $depot_hash

	DEPOT_TOOLS_PATH="$(realpath $PWD/depot_tools)"
	echo "DEPOT_TOOLS_PATH=$DEPOT_TOOLS_PATH"
	export PATH="$DEPOT_TOOLS_PATH:$PATH"
	export VPYTHON_BYPASS="dev"

	mkdir angle
	cd angle
	fetch --nohooks angle
	VPYTHON_BYPASS="dev" gclient sync --no-history --revision angle@$angle_hash
	cd ..


	# angle
	cd angle
	python3 scripts/bootstrap.py

	cd ..
}

build_macos_angle() {
	arch=$1
	osver=$2
	xcodever=$3
	installdir=$4
	datadir=$5
	
	echo "Building deps with params:"
	echo "arch = $arch"
	echo "osver = $osver"
	echo "xcodever = $xcodever"
	echo "installdir = $installdir"
	echo "datadir = $datadir"

	DEPOT_TOOLS_PATH="$(realpath depot_tools)"
	echo "DEPOT_TOOLS_PATH=$DEPOT_TOOLS_PATH"
	export PATH="$DEPOT_TOOLS_PATH:$PATH"
	export VPYTHON_BYPASS="dev"
	# export PATH=$PWD/depot_tools:$PATH

	xcodeapp="Xcode.app"
	if [[ -n "$xcodever" ]]; then
		xcodeapp="Xcode_$xcodever.app"
		sudo xcode-select -s /Applications/$xcodeapp/Contents/Developer
	fi

	# angle
	cd angle
	echo "Configuring angle..."
	gn gen out
	cp $datadir/args.gn out
	# Update macos_sdk_version in the file
	sed -i.bak "s/^mac_sdk_min = .*/mac_sdk_min = \"$osver\"/" "out/args.gn"
	gn gen out
	echo "Building angle..."
	ninja -j 6 -C out
	mkdir -p $installdir/lib
	mkdir -p $installdir/include
	install_name_tool -id @rpath/libGLESv2.dylib out/libGLESv2.dylib
	install_name_tool -id @rpath/libEGL.dylib out/libEGL.dylib
	cp out/libGLESv2.dylib $installdir/lib
	cp out/libEGL.dylib $installdir/lib
	xcodebuild -create-xcframework -library out/libGLESv2.dylib -output $installdir/lib/libGLESv2.xcframework
	xcodebuild -create-xcframework -library out/libEGL.dylib -output $installdir/lib/libEGL.xcframework
	cp -r include $installdir/include/ANGLE
	filecheck="$installdir/lib/libGLESv2.dylib"
	if [ ! -f $filecheck ]; then
		echo "File $filecheck not found"
		exit 1
	fi
	cd $dir
}

