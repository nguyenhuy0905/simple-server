format ELF64 executable

segment readable executable

include 'share.inc'

entry main
main:
  mov qword [currlen], 0
  push rbp
  mov rbp, rsp
  socket AF_INET, SOCK_STREAM, 0
  ; running in gdb shows that the return value is in rax
  ; and, rax is overwritten very quickly, so better save it somewhere.

  ; socket fd
  mov qword [rbp], rax
  ; log socket fd
  ; need the add so that any number becomes its ASCII representation
  add qword [rbp], '0'
  ; logging
  lea rsi, [sockfd_log_1]
  mov rdx, qword [sockfd_log_1_len]
  call fill_str_buff
  lea rsi, [rbp]
  mov rdx, 1
  call fill_str_buff
  mov byte [rbp+8], 10
  lea rsi, [rbp+8]
  mov rdx, 1
  call fill_str_buff
  flush stdout

  ; done with the string
  ; undo the add called earlier
  sub qword [rbp], '0'
  
  ; set socket option
  mov qword [rbp+8], 1
  lea r15, [rbp+8]
  setsockopt qword [rbp], SOL_SOCKET, SO_REUSEPORT, r15, 8

  ; bind socket
  ; I will use the bytes from [rbp+8] to [rbp+15] as struct sockaddr.
  ; sockaddr need the extra 8 padding bytes, so I'm actually using up to [rbp+23]
  ; zero shits out first
  mov qword [rbp+8], 0
  mov qword [rbp+16], 0
  ; sin_family
  mov word [rbp+8], AF_INET
  ; sin_port
  ; htons(14619)
  mov ax, 6969
  rol ax, 8
  mov word [rbp+10], ax
  ; sin_addr.s_addr
  ; htonl(INADDR_LOOPBACK)
  mov eax, dword [addr]
  mov dword [rbp+12], eax
  lea r15, [rbp+8]
  bind qword [rbp], r15, 16

  listen qword [rbp], 2
  accept qword [rbp], 0, 0
  ; new socket fd
  mov qword [rbp+24], rax
  lea rsi, [socksend_1]
  mov rdx, qword [socksend_1_len]
  call fill_str_buff
  lea r10, [strbuf]
  add r10, qword [currlen]
  read qword [rbp+24], r10, qword [maxlen]
  flush stdout
  ; write back a message
  write qword [rbp+24], sockpingback_1, qword [sockpingback_1_len]

  exit 0

segment readable writeable
sockfd_log_1 db "Socket fd: "
sockfd_log_1_len dq $-sockfd_log_1
socksend_1 db "Received: "
socksend_1_len dq $-socksend_1
sockpingback_1 db "Im boutta begone :(",10
sockpingback_1_len dq $-sockpingback_1
addr db 127,0,0,1
; your general string buffer
strbuf:
repeat 4096
db 0
end repeat
maxlen dq 4096
currlen dq 0
