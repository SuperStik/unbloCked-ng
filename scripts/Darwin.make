GL ?= metal

ifeq (${GL},metal)
override CCFLAGS += -DGL_METAL
else ifeq (${GL},vulkan)
override CCFLAGS += -DGL_VULKAN
else
$(error Bad graphics library given, use 'vulkan' or 'metal')
endif

SRC_DIRS := $(shell find ${SRC_DIR}/ -type d)
SRC := $(shell find ${SRC_DIR}/shared ${SRC_DIR}/${GL} -type f -name '*.[cm]')

ifeq (${GL}, metal)
SHDR_SRC := ${SRC_DIR}/${GL}/shaders
SHDR_METAL := $(wildcard ${SHDR_SRC}/*.metal)
endif

SHDR_DIR := ${OUT_DIR}/objects

ifeq (${GL}, metal)
	SHDR_OUT := ${OUT_DIR}/default.metallib
endif

override LIB += m png pthread opus opusfile sdl3 vorbis vorbisfile
override FRAMEWORK += AudioToolbox CoreAudio
ifeq (${GL}, metal)
override FRAMEWORK += Accelerate Foundation Metal
else ifeq (${GL}, vulkan)
override LIB += vulkan
override FRAMEWORK += CoreFoundation
endif

override LIB_PATH += /usr/local/lib /opt/homebrew/lib
override INCL_PATH += ${SRC_DIR} ${SRC_DIR}/shared miniaudio /usr/local/include /usr/local/include/opus /opt/homebrew/include /opt/homebrew/include/opus

LIB_FL := $(patsubst %,-l%,${LIB})
FRAMEWORK_FL := $(patsubst %,-framework %, ${FRAMEWORK})
LIB_PATH_FL := $(patsubst %,-L%, ${LIB_PATH})
INCL_PATH_FL := $(patsubst %,-I%, ${INCL_PATH})

.PHONY: all clean

all: ${OUT} ${SHDR_OUT}

${OUT}: ${SRC}
	${CC} $^ -o $@ ${LIB_PATH_FL} ${LIB_FL} ${FRAMEWORK_FL} ${CCFLAGS} ${INCL_PATH_FL}


${SHDR_OUT}: ${SHDR_METAL} ${SHDR_DIR}
	xcrun metal -o $@ ${SHDR_METAL}

${SHDR_DIR}:
	mkdir -p $@
