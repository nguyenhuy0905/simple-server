STDIN equ 0
STDOUT equ 1
STDERR equ 2

SYS_write = 1
SYS_close = 3

macro write fd, buf, len {
  mov rax, SYS_write
  mov rdi, fd
  mov rsi, buf
  mov rdx, len
  syscall
}

macro close fd {
  mov rax, SYS_close
  mov rdi, fd
  syscall
}

; MUST BE LINKED WITH printf
macro call_printf fd*, buf*, len*, [va_arg] {
  reverse
    match any, va_arg \{ push va_arg \}
  common
    mov rdi, fd
    mov rsi, buf
    mov rdx, len
    call printf
  forward pop rdi
}
