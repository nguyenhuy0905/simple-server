format ELF64

include "./io.inc"
include "./buff.inc"
include "./program.inc"
include "./network.inc"

section '.text' executable
public _start
_start:
  extrn printf
  ; save stack pointer
  push rbp
  mov rbp, rsp
  ; alloc some stack space. Stack grows down
  write STDOUT, open_sock_log_msg, open_sock_log_msg.len
  socket AF_INET, SOCK_STREAM, 0
  mov r12, rax
  mov r13, open_sock_err_msg
  mov r14, open_sock_err_msg.len
  cmp r12, -1
  jg .noprob
.error:
  ; requirements: r12 return code, r13 message addr, r14 msg len
  write STDOUT, r13, r14
  jmp .cleanup
.noprob:
  mov r12, 0
.cleanup:
  ; requirements: r12 return code, r13 socket fd.
  ; print random shits
  ; push some va_args on
  push -20
  push -89
  push 69
  mov rdi, STDOUT
  mov rsi, printf_test_str
  mov rdx, printf_test_str.len
  call printf
  leave
  exit r12

section '.data' writeable
printf_test_str string "Hello\t World \n%d%d=%d\n"
open_sock_log_msg string "Opening socket...",10
open_sock_err_msg string "Error opening socket!!!",10

strbuf arr 1024
