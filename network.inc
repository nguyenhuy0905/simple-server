AF_INET = 2
SOCK_STREAM = 1
SYS_socket = 41
SYS_bind = 49

macro socket family, type, prot {
  mov rax, SYS_socket
  mov rdi, family
  mov rsi, type
  mov rdx, prot
  syscall
}

macro bind fd, addr, addrlen {
  mov rax, SYS_bind
  mov rdi, addr
  mov rdx, addrlen
  syscall
}
