STDIN equ 0
STDOUT equ 1
STDERR equ 2

SYS_read = 0
SYS_write = 1
SYS_open = 2
SYS_close = 3

macro read fd, buf, len {
  mov rax, SYS_read
  mov rdi, fd
  mov rsi, buf
  mov rdx, len
  syscall
}

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

; MUST BE LINKED WITH asm_printf
macro call_printf fd*, buf*, len*, va_arg_1, va_arg_2, va_arg_3, [va_arg] {
  common
    local subamount
    subamount = 0
  reverse
    ; prep to allocate some stack space
    match any, va_arg \{
      subamount = subamount + 8
    \}
  common
    if ~ subamount mod 16 ; SysV ABI requiring 16-byte stack alignment.
      sub rsp, 8
      subamount = subamount + 8
    end if
    match a3, va_arg_3 \{mov r9, va_arg_3\}
    match a2, va_arg_2 \{mov r8, va_arg_2\}
    match a1, va_arg_1 \{mov rcx, va_arg_1\}
  reverse
      match any, va_arg \{ push va_arg \}
  common
    mov rdi, fd
    mov rsi, buf
    mov rdx, len
    call asm_printf
  common
    if subamount > 0
      add rsp, subamount
    end if
}
