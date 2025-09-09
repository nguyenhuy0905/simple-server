format ELF64

include "./io.inc"
include "./buff.inc"
include "./program.inc"
include "./network.inc"

section '.text' executable
public _start
_start:
  extrn asm_printf
  label sock qword at rbp-8
  label newsock qword at rbp-16

  mov rbp, rsp
  sub rsp, 16
  call_printf STDOUT, open_sock_log_msg, open_sock_log_msg.len
  ; This is a manual call compared to the nice macro call_printf
  xor rax, rax
  mov al, byte [server_sockaddr.s_addr+3]
  push rax
  mov al, byte [server_sockaddr.s_addr+2]
  push rax
  xor r9, r9
  mov r9b, byte [server_sockaddr.s_addr+1]
  xor r8, r8
  mov r8b, byte [server_sockaddr.s_addr]
  xor rcx, rcx
  mov cx, word [server_sockaddr.sin_port]
  mov rdi, STDOUT
  mov rsi, sockaddr_fmt
  mov rdx, sockaddr_fmt.len
  call asm_printf

  socket AF_INET, SOCK_STREAM, 0
  mov [sock], rax
  cmp [sock], -1
  je .cleanup
  
  ; dunno why the macro crashes here.
  mov rcx, [sock]
  mov rdi, STDOUT
  mov rsi, open_sock_success_msg
  mov rdx, open_sock_success_msg.len
  call asm_printf

  bind [sock], server_sockaddr, server_sockaddr.len
  cmp rax, -1
  jne @f
  mov rcx, [sock]
  mov rdi, STDOUT
  mov rsi, bind_sock_err_msg
  mov rdx, bind_sock_err_msg.len
  call asm_printf
  jmp .cleanup
@@:

  listen [sock], 1
  cmp rax, -1
  jne @f
  mov rdi, STDOUT
  mov rsi, listen_sock_err_msg
  mov rdx, listen_sock_err_msg.len
  call asm_printf
  mov r12, -1
  jmp .cleanup
@@:
  mov rdi, STDOUT
  mov rsi, listen_sock_success_msg
  mov rdx, listen_sock_success_msg.len
  mov rcx, [sock]
  call asm_printf
  accept [sock], 0, 0
  cmp rax, -1
  jne @f

@@:
  mov [newsock], rax
  xor r12, r12
.cleanup:
  cmp [sock], -1
  je @f
  close rax
@@:
  ; requirements: r12 return code, r13 socket fd.
  ; print random shits
  call_printf STDOUT, printf_test_str, printf_test_str.len, \
  69, -89, -20, 15, 16, 31
  exit r12

section '.data'
printf_test_str string "Hello\t World \n%d%d=%d\n%d+%d=%d\n"
open_sock_log_msg string "Opening socket...\n"
open_sock_success_msg string "Socket %d opened successfully\n"
open_sock_err_msg string "Error opening socket (return %d)!!!\n"
bind_sock_err_msg string "Error binding socket %d!\nstrace to trace!\n"
server_sockaddr sockaddr_in AF_INET, 6969, 127, 0, 0, 1
sockaddr_fmt string ".sin_port = %d\n.s_addr = %d.%d.%d.%d\n"
listen_sock_err_msg string "Error listening socket %d\n"
listen_sock_success_msg string "Listening on socket %d\n"
accept_sock_err_msg string "Error accepting socket\n"

section '.bss' writeable
strbuf arr 1024
