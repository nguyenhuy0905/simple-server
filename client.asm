format ELF64 executable

include 'share.inc'

segment executable writeable
entry main
main:
  push rbp
  mov rbp, rsp

  socket AF_INET, SOCK_STREAM, 0
  mov qword [rbp], rax
  ; from [rbp+8] to [rbp+15] is the sockaddr_in struct.
  ; from [rbp+16] to [rbp+23], while unused, it's still required by the sockaddr
  ; struct
  mov word [rbp+8], AF_INET
  mov ax, 6969
  rol ax, 8
  mov word [rbp+10], ax
  mov eax, dword [addr]
  mov dword [rbp+12], eax
  lea r10, [rbp+8]

  connect qword [rbp], r10, 16
  ; new socket fd
  mov rsi, ping_msg
  mov rdx, qword [ping_msg_len]
  call fill_str_buff
  flush qword [rbp]
  lea r10, [strbuf]
  read qword [rbp], strbuf, qword [maxlen]
  flush qword [rbp]

  exit 0

segment readable writeable
addr db 127,0,0,1
ping_msg db "From client: connected!"
ping_msg_len db $-ping_msg
strbuf:
repeat 4096
db 0
end repeat
maxlen dq 4096
currlen dq 0
