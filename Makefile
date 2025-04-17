all: server unit_test

unit_test: unit_test.o strfmt.o printf.o
	ld $^ -o unit_test

server: server.o printf.o
	ld server.o printf.o -o server

unit_test.o: unit_test.asm buff.inc io.inc
	fasm unit_test.asm

server.o: server.asm io.inc buff.inc network.inc program.inc
	fasm server.asm

printf.o: printf.asm io.inc buff.inc
	fasm printf.asm

strfmt.o: strfmt.asm buff.inc
	fasm strfmt.asm
