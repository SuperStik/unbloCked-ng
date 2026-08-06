GL ?= metal

ifeq (${GL},metal)
override CCFLAGS += -DGL_METAL
else ifeq (${GL},vulkan)
override CCFLAGS += -DGL_VULKAN
else
$(error Bad graphics library given, use 'vulkan' or 'metal')
endif

CLANG_MATRIX ?= 0
ifneq (${CLANG_MATRIX},0)
override CCFLAGS += -DCLANG_MATRIX -fenable-matrix
endif

SRC_DIRS := $(shell find ${SRC}/ -type d)
# TODO: figure out how to make this one command
SRC_C := $(shell find ${SRC}/shared ${SRC}/${GL} -type f -name '*.c')
SRC_M := $(shell find ${SRC}/shared ${SRC}/${GL} -type f -name '*.m')

ifeq (${GL}, metal)
SHDR_SRC := ${SRC}/${GL}/shaders
SHDR_METAL := $(wildcard ${SHDR_SRC}/*.metal)
endif

OBJ_DIR := ${OUT_DIR}/objects
OBJ_C := $(patsubst src/%.c,${OBJ_DIR}/%.c.o,${SRC_C})
OBJ_M := $(patsubst src/%.m,${OBJ_DIR}/%.m.o,${SRC_M})
OBJ_DIRS := $(patsubst ${SRC}/%,${OBJ_DIR}/%,${SRC_DIRS})

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

override LIB_PATH += /usr/local/lib
override INCL_PATH += ${SRC} ${SRC}/shared miniaudio /usr/local/include /usr/local/include/opus

LIB_FL := $(patsubst %,-l%,${LIB})
FRAMEWORK_FL := $(patsubst %,-framework %, ${FRAMEWORK})
LIB_PATH_FL := $(patsubst %,-L%, ${LIB_PATH})
INCL_PATH_FL := $(patsubst %,-I%, ${INCL_PATH})

.PHONY: all clean

all: ${OBJ_DIRS} ${OUT} ${SHDR_OUT}

${OUT}: ${OBJ_C} ${OBJ_M}
	${CC} $^ -o $@ ${LIB_PATH_FL} ${LIB_FL} ${FRAMEWORK_FL} ${CCFLAGS}

${OBJ_DIR}/%.c.o: ${SRC}/%.c ${OBJ_DIRS}
	${CC} $< -o $@ -c ${INCL_PATH_FL} ${CCFLAGS}

${OBJ_DIR}/%.m.o: ${SRC}/%.m ${OBJ_DIRS}
	${CC} $< -o $@ -c ${INCL_PATH_FL} ${CCFLAGS}

${OBJ_DIR}/%.air: ${SHDR_SRC}/%.metal ${OBJ_DIR}
	xcrun metal -O$O -c -o $@ $<

${SHDR_OUT}: ${SHDR_AIR_OUT} ${SHDR_DIR}
	xcrun metal -o $@ ${SHDR_AIR_OUT}

${OBJ_DIRS}:
	mkdir -p $@

${SHDR_DIR}:
	mkdir -p $@
