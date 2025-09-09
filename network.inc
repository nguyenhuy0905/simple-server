AF_INET = 2
SOCK_STREAM = 1
SYS_socket = 41
SYS_bind = 49
SYS_listen = 50
SYS_accept = 43

macro socket family, type, prot {
  mov rax, SYS_socket
  mov rdi, family
  mov rsi, type
  mov rdx, prot
  syscall
}

macro bind fd, addr, addrlen {
  mov rax, SYS_bind
  mov rdi, fd
  mov rsi, addr
  mov rdx, addrlen
  syscall
}

macro listen fd, backlog {
  mov rax, SYS_listen
  mov rdi, fd
  mov rsi, backlog
  syscall
}

macro accept fd, addr, addrlen {
        mov rax, SYS_accept
        mov rdi, fd
        mov rsi, addr
        mov rdx, addrlen
        syscall
}

; port will be reverse-byte-ordered.
struc sockaddr_in family*, port*, b1*, b2*, b3*, b4* {
  local nbo_port
  common
  nbo_port = port / 256
  nbo_port = nbo_port + (port mod 256) * 256
  .sin_family dw family
  .sin_port dw nbo_port
  .s_addr db b1, b2, b3, b4
  .padding dq 0
  .len = $ - .sin_family
}
