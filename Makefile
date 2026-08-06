export CC ?= cc
export EXE := unbloCked

export SRC := src

export OUT_DIR := build
export OUT := ${OUT_DIR}/${EXE}

# TODO: make sure the base name has at least one character
RES := resources
RES_SRC := $(shell find ${RES}/ -name '*.*')
RES_DIR = ${OUT_DIR}/resources
RES_OUT = $(patsubst ${RES}/%,${RES_DIR}/%,${RES_SRC})

O ?= 2

override CCFLAGS += -flto -funsafe-math-optimizations -fno-math-errno -fvisibility=hidden -DMA_NO_RUNTIME_LINKING -O$O
export CCFLAGS

.PHONY: all clean

all: ${RES_OUT}
	$(MAKE) -f $(shell uname).make

${RES_DIR}/%: ${RES}/% ${RES_DIR}
	@mkdir -p `dirname $@`
	cp -f $< $@

${RES_DIR}:
	mkdir -p $@

clean:
	$(RM) -r ${OUT_DIR}
