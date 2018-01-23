#!/bin/sh

if [ ! -f CONFIG ]; then
	cp -f CONFIG.def CONFIG
fi
. ./CONFIG
. ./build.sh
. ./publish.sh

[ -z "$EDITOR" ] && EDITOR=vim

release_all() {
	download radare2
	download_others

	# docker_linux_build x86 static
	# TODO: dockerify
	android_build x86
	android_build mips
	android_build arm
	android_build aarch64

	docker_linux_build x86
	docker_linux_build x64
	docker_linux_build mipsel
	docker_linux_build armv5

	# rpi? must test
	#docker_linux_build armv6
	#docker_linux_build armv7
	#docker_linux_build armv64
	#docker_linux_build mipsel
	docker_linux_build mipsel static

	w32_build x86
	#w64_build x64
	msvc32_build
	msvc64_build
	msvc32_installer
	msvc64_installer
	docker_windows_build x86_64-w64-mingw32.static-gcc
	# docker_windows_build i686-w64-mingw32.static-gcc

	case "`uname`" in
	Darwin)
		osx_build
		ios_build arm
		ios_build arm64
		ios_appstore arm
		ios_appstore arm64
		;;
	Linux)
		# linux_build
		:
		;;
	esac

	publish_checksums

	### populate all binaries
	publish_cydia
	publish_out
	publish_android

	### announce
	publish_irc
	publish_www
	# publish_twitter
	# publish_telegram
	# publish_blog
}

case "$1" in
-r2frida)
        docket_linux_r2frida_build x64
	;;
-armv5)
        docker_linux_build armv5
	;;
-mipsel)
        docker_linux_build mipsel $2
	;;
-l)
	echo "
android:
	x86
	mips
	arm
	aarch64

linux:
	armv5
	armv6
	armv7
	arm64
	mipsel

osx:
	x86_64
	i686
	ppc

windows:
	x86
	x64
	msvc32
	msvc64
	msvc32_installer
	msvc64_installer

ios:
	armv7
	arm64
"
	;;
-js)
	download radare2
	docker_asmjs_build
	exit 0
	;;
-wasm)
	download radare2
	docker_wasm_build
	;;
-deb)
	docker_linux_build x86
	docker_linux_build x64
	;;
-ios)
	download radare2
	ios_build arm
	ios_build arm64
	ios_appstore arm
	ios_appstore arm64
	exit 0
	;;
-ios-sdk)
	ios_appstore arm
	ios_appstore arm64
	exit 0
	;;
-w32)
	download radare2
	w32_build x86
	exit 0
	;;
-w64)
	download radare2
	docker_windows_build x86_64-w64-mingw32.static-gcc
	;;
-msvc32_installer)
	msvc32_installer
	exit 0
	;;
-msvc64_installer)
	msvc64_installer
	exit 0
	;;
-msvc32)
	msvc32_build
	exit 0
	;;
-msvc64)
	msvc64_build
	exit 0
	;;
-osx)
	download radare2
	osx_build
	exit 0
	;;
-lin)
	download radare2
	docker_linux_build x86
	docker_linux_build x64
	exit 0
	;;
-lin32)
	download radare2
	docker_linux_build x86 $2
	exit 0
	;;
-lin64)
	download radare2
	docker_linux_build x64 $2
	exit 0
	;;
-x)
	if [ -z "$2" ]; then
		cat build.sh | grep '()' | grep build | awk -F '_build' '{print $1}'
	else
		target=`echo "$2" | sed -e s,-,_,g`
		${target}_build $3 $4
	fi
	exit 0
	;;
-n|-notes|--notes)
	cd release-notes
	$EDITOR config.json
	make | tee notes.txt
	echo "See notes.txt"
	;;
-pi)
	publish_irc
	;;
-pc)
	publish_cydia
	;;
-pw)
	publish_checksums
	#publish_www
	;;
-p|-pub)
	publish_out
	;;
-pa|-pub-and|-andpub|--pub-and|--and-pub)
	publish_android
	;;
-a)
	release_all
	;;
-h|help|'')
	echo "Usage: ./main.sh [release|init|...]"
	echo " -a                          release all default targets"
	echo " -p                          publish out directory"
	echo " -pa,--pub-and               publish android builds in the radare2-bin repo"
	echo " -n, -notes                  generate release notes"
	echo " -pw                         publish into radare.org"
	echo " -pi                         update IRC title"
	echo " -l                          list build targets usable via -x"
	echo " -ll                         list arch targets"
	echo " -x [target] [arch] [mode]   run the build.sh target for given"
	echo " -js, -ios, -osx, -and, -lin build for asmjs, iOS/OSX/Linux/Andrdo .. (EXPERIMENTAL)"
	echo " -armv5 -mipsel              build armv5 linux debian packages"
	echo " -msvc64_installer, -msvc64  windows (msvc) specific things"
	echo " -w64, -w32                  windows-specific things"
	echo " -wasm                       build for web assembly (EXPERIMENTAL)"
	echo " -r2frida                    build r2frida plugin for Debian (EXPERIMENTAL)"
	echo
	echo "Android NDK for ARM shell"
	echo "  ./main.sh -x docker_android arm shell"
	echo "Emscripten shell:"
	echo " ./main.sh -x docker_asmjs - shell"
	exit 0
	;;
*)
	target=`echo "$1" | sed -e s,-,_,g`
	${target}_build $2 $3
	;;
esac

