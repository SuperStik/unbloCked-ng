CC ?= cc
EXE := unbloCked
SRC_DIR := src
SRC_DIRS := $(shell find ${SRC_DIR}/ -type d)
# TODO: figure out how to make this one command
SRC_C := $(shell find ${SRC_DIR}/ -type f -name '*.c')
SRC_M := $(shell find ${SRC_DIR}/ -type f -name '*.m')
RES := resources
# TODO: make sure the base name has at least one character
RES_SRC := $(shell find ${RES}/ -name '*.*')

SHDR_SRC := ${SRC_DIR}/metal/shaders
SHDR_METAL := $(wildcard ${SHDR_SRC}/*.metal)

OBJ_DIR = ${OUT_DIR}/objects
OBJ_C = $(patsubst src/%.c,${OBJ_DIR}/%.c.o,${SRC_C})
OBJ_M = $(patsubst src/%.m,${OBJ_DIR}/%.m.o,${SRC_M})
OBJ_DIRS = $(patsubst ${SRC_DIR}/%,${OBJ_DIR}/%,${SRC_DIRS})
RES_DIR = ${OUT_DIR}/resources
RES_OUT = $(patsubst ${RES}/%,${RES_DIR}/%,${RES_SRC})

SHDR_AIR_OUT = $(patsubst ${SHDR_SRC}/%.metal,${OBJ_DIR}/%.air,${SHDR_METAL})
SHDR_OUT = ${OUT_DIR}/default.metallib

override LIB += m png pthread opus opusfile sdl3 vorbis vorbisfile
override FRAMEWORK += Accelerate AudioToolbox CoreAudio Foundation Metal
override LIB_PATH += /usr/local/lib
override INCL_PATH += ${SRC_DIR} ${SRC_DIR}/shared miniaudio /usr/local/include /usr/local/include/opus

LIB_FL := $(patsubst %,-l%,${LIB})
FRAMEWORK_FL := $(patsubst %, -framework %, ${FRAMEWORK})
LIB_PATH_FL := $(patsubst %, -L%, ${LIB_PATH})
INCL_PATH_FL := $(patsubst %, -I%, ${INCL_PATH})

.PHONY: all clean

OUT_DIR := build
OUT := ${OUT_DIR}/${EXE}

O ?= 2

override CCFLAGS += -flto -funsafe-math-optimizations -fno-math-errno -fvisibility=hidden -DMA_NO_RUNTIME_LINKING

all: ${OBJ_DIRS} ${OUT} ${SHDR_OUT} ${RES_OUT}

${OUT}: ${OBJ_C} ${OBJ_M}
	${CC} $^ -O$O -o $@ ${LIB_PATH_FL} ${LIB_FL} ${FRAMEWORK_FL} ${CCFLAGS}

${OBJ_DIR}/%.c.o: ${SRC_DIR}/%.c ${OBJ_DIRS}
	${CC} $< -O$O -o $@ -c ${INCL_PATH_FL} ${CCFLAGS}

${OBJ_DIR}/%.m.o: ${SRC_DIR}/%.m ${OBJ_DIRS}
	${CC} $< -O$O -o $@ -c ${INCL_PATH_FL} ${CCFLAGS}

${OBJ_DIR}/%.air: ${SHDR_SRC}/%.metal ${OBJ_DIR}
	xcrun metal -O$O -c -o $@ $<

${SHDR_OUT}: ${SHDR_AIR_OUT} ${SHDR_DIR}
	xcrun metal -o $@ ${SHDR_AIR_OUT}

${RES_DIR}/%: ${RES}/% ${RES_DIR}
	@mkdir -p `dirname $@`
	cp -f $< $@

${OBJ_DIRS}:
	mkdir -p $@

${SHDR_DIR}:
	mkdir -p $@

${RES_DIR}:
	mkdir -p $@

${OUT_DIR}:
	mkdir $@

clean:
	rm -fr ${OUT_DIR}
