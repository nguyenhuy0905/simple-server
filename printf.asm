format ELF64

include "./io.inc"
include "./buff.inc"

section '.text' executable
public printf
extrn int32_to_str

; refer to any ASCII table out there
TAB = 9
NEWLINE = 10

; args:
; rdi: the output to print to.
; rsi: the address of the string buffer to print.
; rdx: the length to format.
; return through rax the number of bytes printed, or -1 if error.
;
; va_args are passed like so:
; HIGHEST MEMORY ADDRESS
; last argument
; ...
; second argument
; first argument
; LOWEST MEMORY ADDRESS
; for now, if you pass in too few va_arg, there's no bound-checking mechanism.
;
; supported parse symbols:
; \n -> newline
; \t -> tab
; \\ -> backslash
; %d -> number on va_arg list
printf:
  push rbp
  mov rbp, rsp
  ; rsp at this point:
  ; maybe some va_args here
  ; leave <- rbp
  ; value of rbp <- rsp
  ; I'm lazy, imma just save va_arg pointer to memory
  ; and besides, function calls inside here may very well use these registers,
  ; since they are not guaranteed to preserve
  ; imma just use rax, then rdi, rsi and rdx as temporary registers.
  sub rsp, 64
  ; push all the arguments passed in to the stack
  ; TODO: I should have utilized some function-call-preserved registers.
  ; that is, r12-r15 mostly. But, loading into memory saves me more headache.
  mov qword [rbp-8], rdi
  mov qword [rbp-16], rsi
  mov qword [rbp-24], rdx
  ; local variables
  lea rax, [rbp+16]
  mov qword [rbp-32], rax
  mov qword [rbp-40], 0
  ; Some macro to refer to these memory positions more easily
  t_fd equ qword [rbp-8]
  t_buf equ qword [rbp-16]
  t_buflen equ qword [rbp-24]
  va_arg_ptr equ qword [rbp-32]
  retval equ qword [rbp-40]

  ; strbuf index. Only meaningful in the context of .loop_put_str.
  mov qword [rbp-48], 1
  strbuf_idx equ qword [rbp-48]
  
  ; format buffer index. Only meaningful in the context of .loop_put_str.
  mov qword [rbp-56], 0
  buf_idx equ qword [rbp-56]
.loop_put_str:
  ; while (r9 < rdx)
  mov r9, buf_idx
  mov rdx, t_buflen
  cmp r9, rdx
  je .end_loop_put_str
  ; while-body
  mov rsi, t_buf
  cmp byte [rsi+r9], "\"
  je .match_backslash
  cmp byte [rsi+r9], "%"
  je .match_percent
.end_match:
  
.begin_put_str:
  c_to_put equ cl
  mov rsi, t_buf
  mov c_to_put, byte [rsi+r9]
  mov rax, strbuf_idx
  mov byte [strbuf+rax], c_to_put
  inc strbuf_idx
  inc retval
  c_to_put equ
.end_put_str:
  inc buf_idx
  jmp .loop_put_str

; modifies r10 to be the position to write to.
macro bound_check label_if_ok, label_if_done {
  ; paranoia
  mov rsi, t_buf
  mov r9, buf_idx
  mov rdx, t_buflen
  ; comparison
  lea r10, [rsi+r9+1]
  cmp r10, [rsi+rdx]
  ; if the backslash is the last char, do nothing.
  ; otherwise, look to the next char:
  ; - if next char is t, put 9 to strbuf.
  ; - if next char is n, put 10 to strbuf.
  jl label_if_ok
  jmp label_if_done
}
.match_backslash:
  ; at this point, r9, rsi and rdx should be loaded with buf_idx, t_buf and
  ; t_buflen respectively
  bound_check .match_backslash_peek_next, .end_match
.match_backslash_peek_next:
  ; use r10 here
  macro r10_match_char char_cmp, jmp_label {
    cmp byte [r10], char_cmp
    je jmp_label
  }
  r10_match_char "t", .match_backslash_put_tab
  r10_match_char "n", .match_backslash_put_newline
  r10_match_char "\", .match_backslash_put_backslash
  jmp .begin_put_str

  ; only useful in the context of match_backslash really
  macro put_char to_put {
    mov rax, strbuf_idx
    mov byte [strbuf+rax], to_put
    inc buf_idx
    inc strbuf_idx
    inc retval
    jmp .end_put_str
  }
.match_backslash_put_tab:
  put_char TAB
.match_backslash_put_newline:
  put_char NEWLINE
.match_backslash_put_backslash:
  put_char "\"

.match_percent:
  ; TODO: match_percent
  bound_check .match_percent_peek_next, .end_match
.match_percent_peek_next:
  r10_match_char "d", .match_percent_put_int
  jmp .begin_put_str
.match_percent_put_int:
  ; prepare to call the function
  mov t_buf, rsi
  ; get next arg in va_list 
  mov rax, va_arg_ptr
  mov edi, dword [rax]
  ; I'm lazy.
  ; technically I can save space by only pushing 4 bytes on here.
  add va_arg_ptr, 8
  mov rax, strbuf_idx
  lea rsi, [strbuf+rax]
  mov rdx, strbuf.len
  sub rdx, strbuf_idx
  call int32_to_str
  mov rsi, t_buf
  add retval, rax
  add strbuf_idx, rax
  inc buf_idx
  jmp .end_put_str

.end_loop_put_str:

  ; printing it out
  write t_fd,strbuf,retval
  mov rax, retval
.cleanup:
  leave
  ret
  
section '.data' writeable
strbuf arr 1024
