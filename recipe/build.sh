#!/bin/bash
# Get an updated config.sub and config.guess
# lame ships these as read-only, so force the overwrite.
cp -f $BUILD_PREFIX/share/gnuconfig/config.* .

# lame 3.101's id3tag/utf8 code trips the C diagnostics that GCC 14 (and
# modern clang) promote from warnings to errors by default:
#   * frontend/parse.c calls the id3tag_set_*_ucs2 helpers whose prototypes
#     are hidden by DEPRECATED_OR_OBSOLETE_CODE_REMOVED in lame.h (the symbols
#     are still exported by libmp3lame) -> implicit-function-declaration.
#   * the id3v2 utf8 API types text as `unsigned short const *` in the public
#     header but passes it to `char const *` parameters internally; the pointer
#     value is unchanged, only the element type annotation differs
#     -> incompatible-pointer-types / int-conversion.
# Restore the historical (non-fatal) behaviour so the package builds as it does
# with older toolchains.
export CFLAGS="${CFLAGS} -Wno-implicit-function-declaration -Wno-implicit-int -Wno-incompatible-pointer-types -Wno-int-conversion"

./configure --prefix=$PREFIX \
	    --disable-dependency-tracking \
	    --disable-debug \
	    --enable-nasm

make -j$CPU_COUNT
make install -j$CPU_COUNT

# test
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
  $PREFIX/bin/lame testcase.mp3
fi
