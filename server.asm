format ELF64 executable 3

include "./io.inc"

STDIN equ 0
STDOUT equ 1
STDERR = 2
AF_INET = 2
SOCK_STREAM = 1

SYS_socket = 41
SYS_exit = 60
SYS_write = 1

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

struc string [data] {
  common
  . db data
  .len = $ - .
}

struc arr size {
  repeat size
  db 0
  end repeat
  .len = size
}

segment executable readable
_start:
  ; save stack pointer
  push rbp
  mov rbp, rsp
  ; alloc some stack space. Stack grows down
  sub rsp, 1
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
  leave
  exit r12

segment readable
open_sock_log_msg string "Opening socket...",10
open_sock_err_msg string "Error opening socket!!!",10

segment readable writable
strbuf arr 4096
