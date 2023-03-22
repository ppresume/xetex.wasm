ROOT_DIR := .
XETEX_ROOT_DIR := $(ROOT_DIR)/xetex
DEPS_ROOT_DIR := $(ROOT_DIR)/deps
WEB2C_SOURCE_DIR := $(XETEX_ROOT_DIR)/source/texk/web2c
WEB2C_BUILD_DIR := $(XETEX_ROOT_DIR)/build/texk/web2c
CC := emcc
CXX := em++
WFLAGS := -Wall \
	-Wunused \
	-Wimplicit \
	-Wreturn-type \
	-Wmissing-prototypes \
	-Wmissing-declarations \
	-Wparentheses \
	-Wswitch \
	-Wtrigraphs \
	-Wpointer-arith \
	-Wcast-qual \
	-Wcast-align \
	-Wwrite-strings \
	-Wdeclaration-after-statement \
	-Wno-parentheses-equality
DFLAGS := -DHAVE_CONFIG_H \
	-DNO_DEBUG \
	-DU_STATIC_IMPLEMENTATION \
	-DGRAPHITE2_STATIC \
	-D__SyncTeX__ \
	'-DSYNCTEX_ENGINE_H="synctex-xetex.h"' 	# note the single quote matters here
IFLAGS := -I$(WEB2C_BUILD_DIR) \
	-I$(WEB2C_BUILD_DIR)/w2c \
	-I$(WEB2C_SOURCE_DIR) \
	-I$(XETEX_ROOT_DIR)/build/texk \
	-I$(XETEX_ROOT_DIR)/source/texk \
	-I$(XETEX_ROOT_DIR)/source/texk/web2c/xetexdir \
	-I$(XETEX_ROOT_DIR)/build/libs/icu/include \
	-I$(XETEX_ROOT_DIR)/build/libs/freetype2/freetype2 \
	-I$(XETEX_ROOT_DIR)/build/libs/teckit/include \
	-I$(XETEX_ROOT_DIR)/build/libs/harfbuzz/include \
	-I$(XETEX_ROOT_DIR)/build/libs/graphite2/include \
	-I$(XETEX_ROOT_DIR)/build/libs/poppler/include \
	-I$(XETEX_ROOT_DIR)/build/libs/libpng/include \
	-I$(XETEX_ROOT_DIR)/build/libs/zlib/include \
	-I$(DEPS_ROOT_DIR)/fontconfig-2.13.1 \
	-I$(WEB2C_SOURCE_DIR)/libmd5 \
	-I$(WEB2C_SOURCE_DIR)/synctexdir
CCFLAGS := $(WFLAGS) \
	$(DFLAGS) \
	$(IFLAGS) \
	-g \
	-O0 \

ICU_TEMP_DIR := $(shell mktemp -d)

prepare:
	# build native xetex, this step will generate some code and also build 
	# some native tools which is needed for wasm build
	cd xetex && ./build.sh

	# xetex files
	cp $(WEB2C_SOURCE_DIR)/xetexdir/xetexextra.c $(WEB2C_BUILD_DIR)/xetexdir/
	cp $(WEB2C_SOURCE_DIR)/synctexdir/synctex.c $(WEB2C_BUILD_DIR)/synctexdir/

	# libmd5 files
	cp $(WEB2C_SOURCE_DIR)/libmd5/md5.c $(WEB2C_BUILD_DIR)/libmd5/

	# lib/lib.a files
	cp $(WEB2C_SOURCE_DIR)/lib/*.c $(WEB2C_BUILD_DIR)/lib/
	cp $(WEB2C_SOURCE_DIR)/lib/*.h $(WEB2C_BUILD_DIR)/lib/

	# libxetex files
	cp $(WEB2C_SOURCE_DIR)/xetexdir/*.h $(WEB2C_BUILD_DIR)/xetexdir/
	cp $(WEB2C_SOURCE_DIR)/xetexdir/*.c $(WEB2C_BUILD_DIR)/xetexdir/
	cp $(WEB2C_SOURCE_DIR)/xetexdir/*.cpp $(WEB2C_BUILD_DIR)/xetexdir/
	cp -r $(WEB2C_SOURCE_DIR)/xetexdir/image $(WEB2C_BUILD_DIR)/xetexdir/

	# build fontconfig and expat libraries to wasm
	make -C deps fontconfig

xetex_sources = $(WEB2C_BUILD_DIR)/xetexdir/xetexextra.c \
	$(WEB2C_BUILD_DIR)/synctexdir/synctex.c \
	$(WEB2C_BUILD_DIR)/xetexini.c \
	$(WEB2C_BUILD_DIR)/xetex0.c \
	$(WEB2C_BUILD_DIR)/xetex-pool.c

xetex_objects = $(xetex_sources:.c=.o)

$(xetex_objects): %.o: %.c
	$(CC) $(CCFLAGS) -c -o $@ $<

libmd5_sources = $(WEB2C_BUILD_DIR)/libmd5/md5.c

libmd5_objects = $(libmd5_sources:.c=.o)

$(libmd5_objects): %.o: %.c
	$(CC) $(CCFLAGS) -c -o $@ $<

liba_sources = $(WEB2C_BUILD_DIR)/lib/alloca.c \
	$(WEB2C_BUILD_DIR)/lib/coredump.c \
	$(WEB2C_BUILD_DIR)/lib/fprintreal.c \
	$(WEB2C_BUILD_DIR)/lib/inputint.c \
	$(WEB2C_BUILD_DIR)/lib/printversion.c \
	$(WEB2C_BUILD_DIR)/lib/setupvar.c \
	$(WEB2C_BUILD_DIR)/lib/uexit.c \
	$(WEB2C_BUILD_DIR)/lib/version.c \
	$(WEB2C_BUILD_DIR)/lib/basechsuffix.c \
	$(WEB2C_BUILD_DIR)/lib/chartostring.c \
	$(WEB2C_BUILD_DIR)/lib/eofeoln.c \
	$(WEB2C_BUILD_DIR)/lib/input2int.c \
	$(WEB2C_BUILD_DIR)/lib/openclose.c \
	$(WEB2C_BUILD_DIR)/lib/usage.c \
	$(WEB2C_BUILD_DIR)/lib/zround.c

liba_objects = $(liba_sources:.c=.o)

$(liba_objects): %.o: %.c
	$(CC) $(CCFLAGS) -c -o $@ $<

libxetex_cc_sources := $(WEB2C_BUILD_DIR)/xetexdir/XeTeX_ext.c \
	$(WEB2C_BUILD_DIR)/xetexdir/XeTeX_pic.c \
	$(WEB2C_BUILD_DIR)/xetexdir/trans.c \
	$(WEB2C_BUILD_DIR)/xetexdir/image/bmpimage.c \
	$(WEB2C_BUILD_DIR)/xetexdir/image/jpegimage.c \
	$(WEB2C_BUILD_DIR)/xetexdir/image/mfileio.c \
	$(WEB2C_BUILD_DIR)/xetexdir/image/numbers.c \
	$(WEB2C_BUILD_DIR)/xetexdir/image/pngimage.c

libxetex_cc_objects := $(libxetex_cc_sources:.c=.o)

$(libxetex_cc_objects): %.o: %.c
	$(CC) $(CCFLAGS) -c -o $@ $<

libxetex_cpp_sources := $(WEB2C_BUILD_DIR)/xetexdir/XeTeXFontInst.cpp \
	$(WEB2C_BUILD_DIR)/xetexdir/XeTeXFontMgr.cpp \
	$(WEB2C_BUILD_DIR)/xetexdir/XeTeXLayoutInterface.cpp \
	$(WEB2C_BUILD_DIR)/xetexdir/XeTeXOTMath.cpp \
	$(WEB2C_BUILD_DIR)/xetexdir/hz.cpp \
	$(WEB2C_BUILD_DIR)/xetexdir/pdfimage.cpp \
	$(WEB2C_BUILD_DIR)/xetexdir/XeTeXFontMgr_FC.cpp

libxetex_cpp_objects := $(libxetex_cpp_sources:.cpp=.o)

$(libxetex_cpp_objects): %.o: %.cpp
	$(CXX) $(CCFLAGS) -c -o $@ $<

libxetex_objects := $(libxetex_cc_objects) $(libxetex_cpp_objects)

harfbuzz: icu graphite2
	cd $(XETEX_ROOT_DIR)/source/libs/harfbuzz && emconfigure ./configure
	cd $(XETEX_ROOT_DIR)/source/libs/harfbuzz && emmake make -j 8
	cp $(XETEX_ROOT_DIR)/source/libs/harfbuzz/libharfbuzz.a \
	   $(XETEX_ROOT_DIR)/build/libs/harfbuzz/

icu:
	# make native version first
	cd $(XETEX_ROOT_DIR)/source/libs/icu && ./configure
	cd $(XETEX_ROOT_DIR)/source/libs/icu && make -j 8

	# save some native binaries for later use
	cp -r $(XETEX_ROOT_DIR)/source/libs/icu/icu-build/bin $(ICU_TEMP_DIR)/
	cp $(XETEX_ROOT_DIR)/source/libs/icu/icu-build/stubdata/libicudata.a \
	   $(ICU_TEMP_DIR)/
	cd $(XETEX_ROOT_DIR)/source/libs/icu && make distclean

	# try to make wasm for the first time
	cd $(XETEX_ROOT_DIR)/source/libs/icu && emconfigure ./configure
	-cd $(XETEX_ROOT_DIR)/source/libs/icu && emmake make -j 8

	# wasm build would fail and we need the native tools back
	cp --preserve=mode $(ICU_TEMP_DIR)/bin/* \
	   $(XETEX_ROOT_DIR)/source/libs/icu/icu-build/bin

	# make wasm for the second time
	cd $(XETEX_ROOT_DIR)/source/libs/icu && emmake make -j 8
	cp $(XETEX_ROOT_DIR)/source/libs/icu/icu-build/lib/libicuuc.a \
	   $(XETEX_ROOT_DIR)/build/libs/icu/icu-build/lib/
	cp $(XETEX_ROOT_DIR)/source/libs/icu/icu-build/stubdata/libicudata.a \
	   $(XETEX_ROOT_DIR)/build/libs/icu/icu-build/lib/

kpathsea:
	cd $(XETEX_ROOT_DIR)/source/texk/kpathsea && emconfigure ./configure
	cd $(XETEX_ROOT_DIR)/source/texk/kpathsea && emmake make -j 8
	cp $(XETEX_ROOT_DIR)/source/texk/kpathsea/.libs/libkpathsea.a \
	   $(XETEX_ROOT_DIR)/build/texk/kpathsea/.libs

graphite2:
	cd $(XETEX_ROOT_DIR)/source/libs/graphite2 && emconfigure ./configure
	cd $(XETEX_ROOT_DIR)/source/libs/graphite2 && emmake make -j 8
	cp $(XETEX_ROOT_DIR)/source/libs/graphite2/libgraphite2.a \
	   $(XETEX_ROOT_DIR)/build/libs/graphite2/

zlib:
	cd $(XETEX_ROOT_DIR)/source/libs/zlib && emconfigure ./configure
	cd $(XETEX_ROOT_DIR)/source/libs/zlib && emmake make -j 8
	cp $(XETEX_ROOT_DIR)/source/libs/zlib/libz.a \
	   $(XETEX_ROOT_DIR)/build/libs/zlib/

poppler: zlib
	cd $(XETEX_ROOT_DIR)/source/libs/poppler && emconfigure ./configure
	cd $(XETEX_ROOT_DIR)/source/libs/poppler && emmake make -j 8
	cp $(XETEX_ROOT_DIR)/source/libs/poppler/libpoppler.a \
	   $(XETEX_ROOT_DIR)/build/libs/poppler/

teckit: zlib
	cd $(XETEX_ROOT_DIR)/source/libs/teckit && emconfigure ./configure
	cd $(XETEX_ROOT_DIR)/source/libs/teckit && emmake make -j 8
	cp $(XETEX_ROOT_DIR)/source/libs/teckit/libTECkit.a \
	   $(XETEX_ROOT_DIR)/build/libs/teckit/

xetex: prepare \
	$(xetex_objects) $(libmd5_objects) $(liba_objects) $(libxetex_objects) \
	harfbuzz kpathsea poppler teckit
	# note that the order of `.a` files matters here, namely, if you put
	# `lib/lib.a` after `libkpathsea.a`, this command will report an error
	$(CXX) \
	-g \
	-o $(WEB2C_BUILD_DIR)/xetex \
	-s USE_LIBPNG=1 \
	-s USE_FREETYPE=1 \
	$(xetex_objects) \
	$(libxetex_objects) \
	$(libmd5_objects) \
	$(liba_objects) \
	$(XETEX_ROOT_DIR)/build/libs/harfbuzz/libharfbuzz.a \
	$(XETEX_ROOT_DIR)/build/libs/graphite2/libgraphite2.a \
	$(XETEX_ROOT_DIR)/build/libs/icu/icu-build/lib/libicuuc.a \
	$(XETEX_ROOT_DIR)/build/libs/icu/icu-build/lib/libicudata.a \
	$(XETEX_ROOT_DIR)/build/libs/teckit/libTECkit.a \
	$(XETEX_ROOT_DIR)/build/libs/poppler/libpoppler.a \
	$(XETEX_ROOT_DIR)/build/texk/kpathsea/.libs/libkpathsea.a \
	$(DEPS_ROOT_DIR)/fontconfig-2.13.1/src/.libs/libfontconfig.a \
	$(DEPS_ROOT_DIR)/expat-2.2.6/lib/.libs/libexpat.a
