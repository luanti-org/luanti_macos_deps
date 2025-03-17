# Group of scripts for build macOS deps

Script `build.sh` is for manual run of build.
Should work for macOS 11 and newer.
Auto download of SDK is supported for macOS 11.3, 12.3, 13.3 and 14.5.

## Common deps

Common deps libpng, gettext, freetype, gpm, libjep-turbo, joncpp, liboff,
libvorbis, luajit, zstd and sdl2 are downloaded and built
by functions in `deps.sh` script.

## ANGLE

ANGLE is cloned and build by functions in `angle.sh` script.

## License

### Source code

BSD 2.0, see LICENSE file when license in not included in file header

