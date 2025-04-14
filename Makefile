all: server

server: server.o printf.o
	ld server.o printf.o -o server

server.o: server.asm io.inc buff.inc
	fasm server.asm

printf.o: printf.asm io.inc buff.inc
	fasm printf.asm
