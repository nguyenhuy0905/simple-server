format ELF64

include "./io.inc"
include "./buff.inc"
include "./program.inc"
include "./network.inc"

extrn asm_printf
section '.text' executable
public _start
_start:
    label sock qword at rbp-8

    mov rbp, rsp
    sub rsp, 16
    mov rdi, STDOUT
    mov rsi, greeting_string
    mov rdx, greeting_string.len
    call asm_printf

    mov rdi, STDOUT
    mov rsi, open_sock_log_msg
    mov rdx, open_sock_log_msg.len
    call asm_printf

    socket AF_INET, SOCK_STREAM, 0
    cmp rax, -1
    jne @f
    mov rdi, STDOUT
    mov rsi, open_sock_err_msg
    mov rdi, open_sock_err_msg.len
    mov rdx, rax
    call asm_printf
    mov r12, rax
    jmp .cleanup
@@:
    mov [sock], rax
    connect [sock], connect_sockaddr, connect_sockaddr.len
    cmp rax, 0
    je @f
    mov r12, rax
    mov rdi, STDOUT
    mov rsi, connect_sock_err_msg
    mov rdx, connect_sock_err_msg.len
    mov rcx, [sock]
    call asm_printf
    jmp .cleanup
@@:
    read [sock], strbuf, strbuf.len
    cmp rax, 0
    jae @f
    mov rdi, STDOUT
    mov rsi, read_sock_err_msg
    mov rdi, read_sock_err_msg.len
    mov rdx, [sock]
    call asm_printf
    mov r12, 1
    jmp .cleanup
@@:
    mov rdi, STDOUT
    mov rsi, strbuf
    mov rdx, rax
    call asm_printf

    xor r12, r12
.cleanup:
    close [sock]
    exit r12

section '.data'
greeting_string string "Hello world, this is client\n"
open_sock_log_msg string "Opening socket...\n"
open_sock_err_msg string "Error opening socket (return %d)!!!\n"
connect_sock_err_msg string "Error connecting socket %d!\n"
read_sock_err_msg string "Error reading from socket %d!\n"
connect_sockaddr sockaddr_in AF_INET, 6969, 127, 0, 0, 1

section '.bss' writeable
strbuf arr 1024
