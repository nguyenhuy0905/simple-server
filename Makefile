BUILD_DIR ?= build
OBJ_DIR ?= ${BUILD_DIR}/obj

all: ${BUILD_DIR}/server ${BUILD_DIR}/unit_test

botch:
	find ${BUILD_DIR} -type f -exec rm '{}' ';'
	find ${OBJ_DIR} -type f -exec rm '{}' ';'

${BUILD_DIR}/unit_test: ${OBJ_DIR}/unit_test.o ${OBJ_DIR}/strfmt.o \
	${OBJ_DIR}/printf.o
	ld $^ -o $@

${BUILD_DIR}/server: build/obj/server.o build/obj/printf.o
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
