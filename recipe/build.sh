#!/bin/bash
# Get an updated config.sub and config.guess
# lame ships these as read-only, so force the overwrite.
cp -f $BUILD_PREFIX/share/gnuconfig/config.* .

# lame 3.101's frontend/parse.c calls the id3tag_set_*_ucs2 helpers whose
# prototypes are hidden by DEPRECATED_OR_OBSOLETE_CODE_REMOVED in lame.h.
# The symbols are exported by libmp3lame, so only the compile-time implicit
# declaration is a problem; modern clang promotes it to an error by default.
export CFLAGS="${CFLAGS} -Wno-implicit-function-declaration"

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
