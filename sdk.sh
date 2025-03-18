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

install_macos_sdk() {
	osver=$1
	xcodever=$2
	downdir=$3

	dir=$(pwd)

	# setup environment
	xcodeapp="Xcode.app"
	if [[ -n $xcodever ]]; then
		xcodeapp="Xcode_$xcodever.app"
	fi
	sysroot="/Applications/$xcodeapp/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${osx}.sdk"
	if [ ! -d "$sysroot" ]; then
		if [ ! -d "/Applications/$xcodeapp/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs" ]; then
			echo "No location for install SDK found. Xcode is probably not installed. (sysroot = $sysroot)"
			exit 1
		fi
		if [[ "$osx" == "11.3" ]]; then
			download_macos_archive $downdir/SDK.tar.bz2 \
					https://github.com/alexey-lysiuk/macos-sdk/releases/download/11.3/MacOSX11.3.tar.bz2 \
					d6604578f4ee3090d1c3efce1e5c336ecfd7be345d046c729189d631ea3b8ec6
			tar -xf $downdir/SDK.tar.bz2
			mv MacOSX11.3.sdk $sysroot
		elif [[ "$osx" == "12.3" ]]; then
			download_macos_archive $downdir/SDK.tar.bz2 \
					https://github.com/alexey-lysiuk/macos-sdk/releases/download/12.3/MacOSX12.3.tar.bz2 \
					91c03be5399be04d8f6b773da13045525e01298c1dfff273b4e1f1e904ee5484
			tar -xf $downdir/SDK.tar.bz2
			mv MacOSX12.3.sdk $sysroot
		elif [[ "$osx" == "13.3" ]]; then
			download_macos_archive $downdir/SDK.tar.bz2 \
					https://github.com/alexey-lysiuk/macos-sdk/releases/download/13.3/MacOSX13.3.tar.bz2 \
					71ae3a78ab1be6c45cf52ce44cb29a3cc27ed312c9f7884ee88e303a862a1404
			tar -xf $downdir/SDK.tar.bz2
			mv MacOSX13.3.sdk $sysroot
		elif [[ "$osx" == "14.5" ]]; then
			download_macos_archive $downdir/SDK.tar.bz2 \
					https://github.com/alexey-lysiuk/macos-sdk/releases/download/14.5/MacOSX14.5.tar.bz2 \
					f6acc6209db9d56b67fcaf91ec1defe48722e9eb13dc21fb91cfeceb1489e57e
			tar -xf $downdir/SDK.tar.bz2
			mv MacOSX14.5.sdk $sysroot
		else
			echo "This SDK target is not supported. (osx = $osx)"
			exit 1
		fi
		echo "SDK downloaded and added to Xcode."
	else
		echo "SDK found in Xcode. (sysroot = $sysroot)"
	fi

}
