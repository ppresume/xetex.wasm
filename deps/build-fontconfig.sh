EXPAT_SOURCE=expat-2.2.6
FONT_CONFIG_SOURCE=fontconfig-2.13.1

function prepare {
  rm -rf $FONT_CONFIG_SOURCE
  tar xzf $FONT_CONFIG_SOURCE.tar.gz
  cd $FONT_CONFIG_SOURCE
  ./autogen.sh
}

function build_native {
  ./configure
  make -j `nproc`

  # clean up all native mess in order for `build_wasm` to rebuild every '*.o'
  # file again
  make clean
}

function build_wasm {
  # we need to alias `uuid_generate_random` function in order to make the build
  # succeed
  # 
  # ref: https://github.com/emscripten-core/emscripten/issues/12093
  emconfigure ./configure \
    EXPAT_CFLAGS="-I`pwd`/../$EXPAT_SOURCE/lib/" \
    EXPAT_LIBS=`pwd`/../$EXPAT_SOURCE/lib/.libs/libexpat.a \
    FREETYPE_CFLAGS="-I`find $EMSDK -name freetype2`" \
    FREETYPE_LIBS="`find $EMSDK -name libfreetype.a`" \
    CFLAGS="-Duuid_generate_random=uuid_generate" \
    --enable-static

  # We need to src/fcstat.c otherwise it will report a build error.
  # You can check https://github.com/lyze/xetex-js#port-notes for details.
  # 
  # ref: https://github.com/lyze/xetex-js/blob/247b338/fontconfig-fcstat.c.patch
  if ! grep -q 'EMSCRIPTEN' src/fcstat.c; then 
    patch src/fcstat.c ../fontconfig-patches/fontconfig-fcstat.c.patch
  fi

  # note that fontconfig will run some test job to verify the build, however,
  # these test jobs will fail for the wasm build, thus we disabled the test job
  # here by patching Makefile.am
  if grep -q 'po-conf test' Makefile.am; then 
    patch Makefile.am ../fontconfig-patches/Makefile.am.patch
  fi
      
  emmake make -j `nproc`
}

function main {
  prepare

  # note that we need to build_native first before build_wasm, fontconfig rely on
  # one of its own native tool (here is src/fc-case/fc-case) to do some job in
  # order to make to the build succeed.
  #
  # if we don't build native, then `src/fc-case/fc-case` would be a WASM file
  # instead of an executable ELF, thus it will report the following error:
  #
  # ```
  # make[4]: Leaving directory
  # '/home/osboxes/work/xetex.wasm/deps/fontconfig-2.13.1/fc-case' /bin/bash: line
  # 2: ./fc-case: Permission denied
  # ```
  build_native

  build_wasm
}

main