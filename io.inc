macro write fd, buf, len {
  mov rax, SYS_write
  mov rdi, fd
  mov rsi, buf
  mov rdx, len
  syscall
}

