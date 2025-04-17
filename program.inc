SYS_exit = 60

macro exit retcode {
  mov rax, SYS_exit
  mov rdi, retcode
  syscall
}
