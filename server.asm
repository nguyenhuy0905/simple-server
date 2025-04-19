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
  ; mov rdi, STDOUT
  ; mov rsi, open_sock_log_msg
  ; mov rdx, open_sock_log_msg.len
  ; call printf
  call_printf STDOUT, open_sock_log_msg, open_sock_log_msg.len
  mov r12, rax
  mov r13, open_sock_err_msg
  mov r14, open_sock_err_msg.len
  cmp r12, -1
  jg .noprob
.error:
  ; requirements: r12 return code, r13 message addr, r14 msg len
  call_printf STDOUT, r12, r13, r14
  jmp .cleanup
.noprob:
  mov r12, 0
.cleanup:
  ; requirements: r12 return code, r13 socket fd.
  ; print random shits
  call_printf STDOUT, printf_test_str, printf_test_str.len, 69, -89, -20
  leave
  exit r12

section '.data' writeable
printf_test_str string "Hello\t World \n%d%d=%d\n"
open_sock_log_msg string "Opening socket...\n"
open_sock_err_msg string "Error opening socket!!!\n"

strbuf arr 1024
