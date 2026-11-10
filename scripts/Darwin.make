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

OBJ_DIR := ${OUT_DIR}/objects
OBJ := $(patsubst src/%.c,${OBJ_DIR}/%.c.o,${SRC})
OBJ := $(patsubst src/%.m,${OBJ_DIR}/%.m.o,${OBJ})
OBJ_DIRS := $(patsubst ${SRC_DIR}/%,${OBJ_DIR}/%,${SRC_DIRS})

ifeq (${GL}, metal)
	SHDR_AIR_OUT := $(patsubst ${SHDR_SRC}/%.metal,${OBJ_DIR}/%.air,${SHDR_METAL})
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

all: ${OBJ_DIRS} ${OUT} ${SHDR_OUT}

${OUT}: ${OBJ}
	echo ${OBJ}
	${CC} $^ -o $@ ${LIB_PATH_FL} ${LIB_FL} ${FRAMEWORK_FL} ${CCFLAGS}

${OBJ_DIR}/%.o: ${SRC_DIR}/% ${OBJ_DIRS}
	${CC} $< -o $@ -c ${INCL_PATH_FL} ${CCFLAGS}

${OBJ_DIR}/%.air: ${SHDR_SRC}/%.metal ${OBJ_DIR}
	xcrun metal -O$O -c -o $@ $<

${SHDR_OUT}: ${SHDR_AIR_OUT} ${SHDR_DIR}
	xcrun metal -o $@ ${SHDR_AIR_OUT}

${OBJ_DIRS}:
	mkdir -p $@
