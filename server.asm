format ELF64

include "./io.inc"
include "./buff.inc"

AF_INET = 2
SOCK_STREAM = 1

SYS_socket = 41
SYS_exit = 60

macro exit retcode {
  mov rax, SYS_exit
  mov rdi, retcode
  syscall
}

macro close fd {
  mov rax, 3
  mov rdi, fd
  syscall
}

macro socket family, type, prot {
  mov rax, SYS_socket
  mov rdi, family
  mov rsi, type
  mov rdx, prot
  syscall
}

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
  cmp r12, -1
  mov r13, open_sock_err_msg
  mov r14, open_sock_err_msg.len
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
  mov rdi, STDOUT
  mov rsi, printf_test_str
  mov rdx, printf_test_str.len
  ; push some va_args on
  sub rsp, 8
  mov qword [rbp-8], 10
  call printf
  leave
  exit r12

section '.data' writeable
printf_test_str string "Hello\t World\n"
open_sock_log_msg string "Opening socket...",10
open_sock_err_msg string "Error opening socket!!!",10

strbuf arr 1024
