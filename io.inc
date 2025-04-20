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
  common
    local .rspsub, subamount
    subamount = 0
    .rspsub:
    match any, va_arg \{
      subamount = subamount + 8
    \}
  common
    if subamount mod 16 ; SysV ABI requiring 16-byte stack alignment.
      sub rsp, 8
      subamount = subamount + 8
    end if
  reverse
      match any, va_arg \{ push va_arg \}
  common
    mov rdi, fd
    mov rsi, buf
    mov rdx, len
    call printf
  common
    if subamount > 0
      add rsp, subamount
    end if
}
