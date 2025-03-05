stdout = 1
AF_INET = 2
SOCK_STREAM = 1
SOL_SOCKET = 1
SO_REUSEPORT = 15

macro write fd, buf, len {
  mov rax, 1
  mov rdi, fd
  mov rsi, buf
  mov rdx, len
  syscall
}

macro read fd, buf, maxsize {
  mov rax, 0
  mov rdi, fd
  mov rsi, buf
  mov rdx, maxsize
  syscall
  add qword [currlen], rax
}

macro exit retcode {
  mov rax, 60
  mov rdi, retcode
  syscall
}

; return val at rax
macro socket domain, type, proto {
  mov rax, 41
  mov rdi, domain
  mov rsi, type
  mov rdx, proto
  syscall
}

macro bind fd, addr, len {
  mov rax, 49
  mov rdi, fd
  mov rsi, addr
  mov rdx, len
  syscall
}

macro listen fd, backlog {
  mov rax, 50
  mov rdi, fd
  mov rsi, backlog
  syscall
}

macro connect fd, addr, len {
  mov rax, 42
  mov rdi, fd
  mov rsi, addr
  mov rdx, len
  syscall
}

macro accept fd, addr, addrlen {
  mov rax, 43
  mov rdi, fd
  mov rsi, addr
  mov rdx, addrlen
  syscall
}

macro setsockopt fd, level, optname, optval, optlen {
  mov rax, 54
  mov rdi, fd
  mov rsi, level
  mov rdx, optname
  mov r10, optval
  mov r8, optlen
  syscall
}

; arguments:
; rsi: address of string buffer
; rdx: string length
;
; other registers that will be used:
; rax, rcx, r10
fill_str_buff:
  mov rax, qword [currlen]
  add qword [currlen], rdx
  add rdx, rax
  lea r10, [strbuf]
  add r10, rax
.loop:
  cmp rax, rdx
  je .done
  mov cl, byte [rsi]
  mov byte [r10], cl
  inc rax
  inc rsi
  inc r10
  jmp .loop
.done:
  lea r10, [strbuf]
  add r10, rdx
  mov rdx, qword [rbp]
  ret

macro flush fd {
  write fd, strbuf, qword [currlen]
  mov qword [currlen], 0
}
