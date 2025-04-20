BUILD_DIR ?= build
OBJ_DIR ?= ${BUILD_DIR}/obj

all: ${BUILD_DIR}/server ${BUILD_DIR}/unit_test

.PHONY: ref
ref: ${BUILD_DIR}/ref

.PHONY: capi
capi: ${BUILD_DIR}/capi

${BUILD_DIR}/ref: ref.c
	$(CC) $^ -o $@ -std=c23 -fsanitize=address -g -Wall -Werror -Wextra -Wno-unused

botch:
	find ${BUILD_DIR} -type f -exec rm '{}' ';'
	find ${OBJ_DIR} -type f -exec rm '{}' ';'

${BUILD_DIR}/capi: ${OBJ_DIR}/capi.o ${OBJ_DIR}/printf.o ${OBJ_DIR}/strfmt.o
	ld $^ -o $@

${OBJ_DIR}/capi.o: capi.c ${OBJ_DIR}
	gcc -c capi.c -o $@

${BUILD_DIR}/unit_test: ${OBJ_DIR}/unit_test.o ${OBJ_DIR}/strfmt.o \
	${OBJ_DIR}/printf.o
	ld $^ -o $@

${BUILD_DIR}/server: ${OBJ_DIR}/server.o ${OBJ_DIR}/printf.o \
	${OBJ_DIR}/strfmt.o
	ld $^ -o $@

${OBJ_DIR}/unit_test.o: unit_test.asm buff.inc io.inc ${OBJ_DIR}
	fasm unit_test.asm $@

${OBJ_DIR}/server.o: server.asm io.inc buff.inc network.inc program.inc \
	${OBJ_DIR}
	fasm server.asm $@

${OBJ_DIR}/printf.o: printf.asm io.inc buff.inc ${OBJ_DIR}
	fasm printf.asm $@

${OBJ_DIR}/strfmt.o: strfmt.asm buff.inc ${OBJ_DIR}
	fasm strfmt.asm $@

${OBJ_DIR}: ${BUILD_DIR}
	mkdir -p $@

${BUILD_DIR}:
	mkdir -p $@
