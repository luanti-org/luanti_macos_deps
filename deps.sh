#!/bin/bash -e

download_macos_archive() {
	rm -f $1
	wget -O $1 $2
	checksum=$(shasum -a 256 $1)
	if [[ "$checksum" != "$3  $1" ]]; then
		echo "Downloaded file $1 has unexpected checksum $checksum."
		exit 1
	fi
}

download_macos_deps() {
	echo "Downloading sources..."
	download_macos_archive gettext.tar.gz https://ftp.gnu.org/gnu/gettext/gettext-0.22.5.tar.gz ec1705b1e969b83a9f073144ec806151db88127f5e40fe5a94cb6c8fa48996a0
	download_macos_archive freetype.tar.xz https://downloads.sourceforge.net/project/freetype/freetype2/2.13.3/freetype-2.13.3.tar.xz 0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
	download_macos_archive gmp.tar.xz https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
	download_macos_archive libjpeg-turbo.tar.gz https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.0.3/libjpeg-turbo-3.0.3.tar.gz 343e789069fc7afbcdfe44dbba7dbbf45afa98a15150e079a38e60e44578865d
	download_macos_archive jsoncpp.tar.gz https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.5.tar.gz f409856e5920c18d0c2fb85276e24ee607d2a09b5e7d5f0a371368903c275da2
	download_macos_archive libogg.tar.gz https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.5.tar.gz 0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664
	download_macos_archive libpng.tar.xz https://downloads.sourceforge.net/project/libpng/libpng16/1.6.43/libpng-1.6.43.tar.xz 6a5ca0652392a2d7c9db2ae5b40210843c0bbc081cbd410825ab00cc59f14a6c
	download_macos_archive libvorbis.tar.gz https://github.com/sfence/libvorbis/archive/refs/tags/v1.3.7_macos_apple_silicon.tar.gz 61dd22715136f13317326ea60f9c1345529fbc1bf84cab99d6b7a165bf86a609
	download_macos_archive luajit.zip https://github.com/sfence/LuaJIT/archive/refs/heads/sfence_macos_fix_and_map_jit.zip 54ff78769b99b68570e959256240469b48b08cfd9a74da24c8800a5dc1cbd79b
	download_macos_archive zstd.tar.gz https://github.com/facebook/zstd/archive/refs/tags/v1.5.6.tar.gz 30f35f71c1203369dc979ecde0400ffea93c27391bfd2ac5a9715d2173d92ff7
	download_macos_archive sdl2.tar.gz https://github.com/libsdl-org/SDL/releases/download/release-2.32.0/SDL2-2.32.0.tar.gz f5c2b52498785858f3de1e2996eba3c1b805d08fe168a47ea527c7fc339072d0
	download_macos_archive openal-soft.tar.gz https://github.com/kcat/openal-soft/archive/refs/tags/1.24.3.tar.gz 7e1fecdeb45e7f78722b776c5cf30bd33934b961d7fd2a11e0494e064cc631ce
}

untar_macos_deps() {
	downdir=$1

	echo "Unarchiving sources..."
	tar -xf $downdir/libpng.tar.xz
	tar -xf $downdir/gettext.tar.gz
	tar -xf $downdir/freetype.tar.xz
	tar -xf $downdir/gmp.tar.xz
	tar -xf $downdir/libjpeg-turbo.tar.gz
	tar -xf $downdir/jsoncpp.tar.gz
	tar -xf $downdir/libogg.tar.gz
	tar -xf $downdir/libvorbis.tar.gz
	unzip 	$downdir/luajit.zip
	tar -xf $downdir/zstd.tar.gz
	tar -xf $downdir/sdl2.tar.gz
	tar -xf $downdir/openal-soft.tar.gz
}

check_macos_file() {
	if [ ! -f "$1" ]; then
		echo "File $1 not found"
		exit 1
	fi
}

build_macos_deps() {
	arch=$1
	osver=$2
	xcodever=$3
	installdir=$4
	
	dir=$(pwd)

	# setup environment
	xcodeapp="Xcode.app"
	if [[ -n $xcodever ]]; then
		xcodeapp="Xcode_$xcodever.app"
	fi
	sysroot="/Applications/$xcodeapp/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${osver}.sdk"
	if [ ! -d "$sysroot" ]; then
		echo "SDK not in $sysroot. Try command line tools."
		sysroot="/Library/Developer/CommandLineTools/SDKs/MacOSX${osver}.sdk"
	fi
	if [ ! -d "$sysroot" ]; then
		echo "Requested sysroot SDK does not found MacOSX${osver}.sdk (sysroot = $sysroot)"
		exit 1
	fi
	if [[ -n $xcodever ]]; then
		sudo xcode-select -s /Applications/$xcodeapp/Contents/Developer
	fi

	export MACOSX_DEPLOYMENT_TARGET=$osver
	export MACOS_DEPLOYMENT_TARGET=$osver
	export CMAKE_PREFIX_PATH=$installdir
	export CPPFLAGS="-arch ${arch}"
	export CC="clang -arch ${arch}"
	export CXX="clang++ -arch ${arch} -isysroot $sysroot"
	export LDFLAGS="-arch ${arch}"
	export SDKROOT=$sysroot
	hostdarwin="--host=${arch}-apple-darwin"
	hostmacos="--host=${arch}-apple-macos${osver}"
	hostdarwin_limit="--host=${arch}-apple-darwin"
	if [[ $arch == "arm64" ]]; then
		hostdarwin_limit="--host=arm-apple-darwin"
	fi

	# libpng
	cd libpng-*
	echo "Configuring libpng..."
	./configure "--prefix=$installdir" $hostdarwin --enable-static --disable-shared
	echo "Building libpng..."
	make -j$(sysctl -n hw.logicalcpu)
	make check
	make install
	check_macos_file "$installdir/lib/libpng.a"
	cd $dir

	# freetype
	cd freetype-*
	echo "Configuring freetype..."
	./configure "--prefix=${installdir}" "LIBPNG_LIBS=-L${installdir}/lib -lpng" \
							"LIBPNG_CFLAGS=-I${installdir}/include" $hostdarwin \
							--enable-static --disable-shared \
							--with-harfbuzz=no --with-brotli=no --with-librsvg=no \
							"CC_BUILD=clang -target ${arch}"
	echo "Building freetype..."
	make -j$(sysctl -n hw.logicalcpu)
	make install
	check_macos_file "$installdir/lib/libfreetype.a"
	cd $dir

	# gettext
	cd gettext-*
	echo "Configuring gettext..."
	./configure "--prefix=$installdir" --enable-static --disable-shared \
							--disable-silent-rules --with-included-glib \
							--with-included-libcroco --with-included-libunistring --with-included-libxml \
							--with-emacs --disable-java --disable-csharp --without-git --without-cvs \
							--without-xz --with-included-gettext $hostdarwin
	echo "Building gettext..."
	make -j$(sysctl -n hw.logicalcpu)
	make install
	check_macos_file "$installdir/lib/libintl.a"
	cd $dir

	# gmp
	cd gmp-*
	echo "Configuring gmp..."
	# different Cellar location on Intel and Arm MacOS
	# --disable-assembly can be used for cross build
	assembly=
	if [[ "$(arch)" != "$arch" ]]; then
		assembly=--disable-assembly
	fi
	#./configure "--prefix=$installdir" --with-pic M4=/usr/local/Cellar/m4/1.4.20/bin/m4
	./configure "--prefix=$installdir" --enable-static --disable-shared \
							--with-pic M4=/opt/homebrew/Cellar/m4/1.4.20/bin/m4 \
							$hostdarwin $assembly
	echo "Building gmp..."
	make -j$(sysctl -n hw.logicalcpu)
	make check
	make install
	check_macos_file "$installdir/lib/libgmp.a"
	cd $dir

	# libjpeg-turbo
	cd libjpeg-turbo-*
	echo "Configuring libjpeg-turbo..."
	cmake . "-DCMAKE_INSTALL_PREFIX:PATH=$installdir" \
					-DCMAKE_OSX_ARCHITECTURES=$arch §\
					-DBUILD_SHARED_LIBS=OFF \
					-DCMAKE_INSTALL_NAME_DIR=$installdir/lib
	echo "Building libjpeg-turbo..."
	make -j$(sysctl -n hw.logicalcpu)
	make install "PREFIX=$installdir"
	check_macos_file "$installdir/lib/libjpeg.a"
	cd $dir

	# jsoncpp
	cd jsoncpp-*
	logdir=$(pwd)
	mkdir build
	cd build
	echo "Configuring jsoncpp..."
	cmake .. "-DCMAKE_INSTALL_PREFIX:PATH=$installdir" \
					-DCMAKE_OSX_ARCHITECTURES=$arch \
					-DBUILD_SHARED_LIBS=OFF \
					-DCMAKE_INSTALL_NAME_DIR=$installdir/lib
	echo "Building jsoncpp..."
	make -j$(sysctl -n hw.logicalcpu)
	make install
	check_macos_file "$installdir/lib/libjsoncpp.a"
	cd $dir

	# libogg
	cd libogg-*
	echo "Configuring libogg..."
	./configure "--prefix=$installdir" $hostdarwin_limit --enable-static --disable-shared
	echo "Building libogg..."
	make -j$(sysctl -n hw.logicalcpu)
	make install
	check_macos_file "$installdir/lib/libogg.a"
	cd $dir

	# libvorbis
	cd libvorbis-*
	echo "Configuring libvorbis..."
	./autogen.sh
	OGG_LIBS="-L${installdir}/lib -logg" OGG_CFLAGS="-I${installdir}/include" ./configure "--prefix=$installdir"	\
				$hostdarwin --enable-static --disable-shared
	echo "Building libvorbis..."
	make -j$(sysctl -n hw.logicalcpu)
	make install
	check_macos_file "$installdir/lib/libvorbis.a"
	cd $dir

	# luajit
	cd LuaJIT-*
	echo "Building LuaJIT..."
	jit_flags="-arch $arch -isysroot $sysroot"
	make amalg -j$(sysctl -n hw.logicalcpu) "PREFIX=$installdir" \
				"CFLAGS=$jit_flags" "HOST_CFLAGS=$jit_flags" \
				"TARGET_CFLAGS=$jit_flags"
	make install \
				"CFLAGS=$jit_flags" "HOST_CFLAGS=$jit_flags" \
				"TARGET_CFLAGS=$jit_flags" \
				"PREFIX=$installdir"
	check_macos_file "$installdir/lib/libluajit-5.1.a"
	cd $dir

	# zstd
	cd zstd-*
	logdir=$(pwd)
	cd build/cmake
	echo "Configuring zstd..."
	cmake . "-DCMAKE_INSTALL_PREFIX:PATH=$installdir" \
					-DCMAKE_OSX_ARCHITECTURES=$arch \
					-DBUILD_SHARED_LIBS=OFF \
					-DCMAKE_INSTALL_NAME_DIR=$installdir/lib
	echo "Building zstd..."
	make -j$(sysctl -n hw.logicalcpu)
	make install
	check_macos_file "$installdir/lib/libzstd.a"
	cd $dir
	
	# SDL2
	cd SDL2-*
	logdir=$(pwd)
	rm -fr build
	mkdir build
	cd build
	echo "Configuring SDL2..."
	cmake .. "-DCMAKE_INSTALL_PREFIX:PATH=$installdir" \
					-DCMAKE_OSX_DEPLOYMENT_TARGET=$osver \
					-DCMAKE_OSX_ARCHITECTURES=$arch -DCMAKE_OSX_SYSROOT=$target_sysroot \
					-DBUILD_SHARED_LIBS=OFF \
					-DSDL_OPENGL=0 -DSDL_OPENGLES=0 \
					-DCMAKE_INSTALL_NAME_DIR=$installdir/lib
	echo "Building SDL2..."
	make -j$(sysctl -n hw.logicalcpu)
	make install
	check_macos_file "$installdir/lib/libSDL2.a"
	cd $dir

	# OpenAL-soft
	cd openal-soft-*
	rm -fr build
	mkdir build
	cd build
	echo "Configuring OpenAL-soft..."
	cmake .. "-DCMAKE_INSTALL_PREFIX:PATH=$installdir" \
					-DCMAKE_OSX_DEPLOYMENT_TARGET=$osver \
					-DCMAKE_OSX_ARCHITECTURES=$arch -DCMAKE_OSX_SYSROOT=$target_sysroot \
					-DLIBTYPE=STATIC -DALSOFT_UTILS=OFF -DALSOFT_EXAMPLES=OFF \
					-DCMAKE_INSTALL_NAME_DIR=$installdir/lib
	echo "Building OpenAL-soft..."
	make -j$(sysctl -n hw.logicalcpu)
	make install 2>&1
	cd $dir
}
