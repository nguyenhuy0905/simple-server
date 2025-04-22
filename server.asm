format ELF64

include "./io.inc"
include "./buff.inc"
include "./program.inc"
include "./network.inc"

section '.text' executable
public _start
_start:
  extrn asm_printf
  ; mov rdi, STDOUT
  ; mov rsi, open_sock_log_msg
  ; mov rdx, open_sock_log_msg.len
  ; call asm_printf
  call_printf STDOUT, open_sock_log_msg, open_sock_log_msg.len
  cmp rax, -1
  jg .noprob
  call_printf STDOUT, open_sock_err_msg, open_sock_err_msg.len, rax
  mov r12, 1
  jmp .cleanup
.noprob:
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
  pop rax
  pop rax
  mov r12, 0
.cleanup:
  ; requirements: r12 return code, r13 socket fd.
  ; print random shits
  call_printf STDOUT, printf_test_str, printf_test_str.len, \
  69, -89, -20, 15, 16, 31
  exit r12

section '.data'
printf_test_str string "Hello\t World \n%d%d=%d\n%d+%d=%d\n"
open_sock_log_msg string "Opening socket...\n"
open_sock_err_msg string "Error opening socket (return %d)!!!\n"
server_sockaddr sockaddr_in AF_INET, 6969, 127, 0, 0, 1
sockaddr_fmt string ".sin_port = %d\n.s_addr = %d.%d.%d.%d\n"

section '.bss' writeable
strbuf arr 1024
