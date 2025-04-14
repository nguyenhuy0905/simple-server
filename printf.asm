format ELF64

include "./io.inc"
include "./buff.inc"

section '.text' executable
public printf

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
  lea rax, [rbp+16]
  sub rsp, 48
  ; push all the arguments passed in to the stack
  ; TODO: I should have utilized some function-call-preserved registers.
  ; that is, r12-r15 mostly. But, loading into memory saves me more headache.
  mov qword [rbp-8], rdi
  mov qword [rbp-16], rsi
  mov qword [rbp-24], rdx
  ; local variables
  mov qword [rbp-32], rax
  ; Some macro to refer to these memory positions more easily
  t_fd equ qword [rbp-8]
  t_buf equ qword [rbp-16]
  t_buflen equ qword [rbp-24]
  va_arg_ptr equ [rbp+16]

  ; strbuf index. Only meaningful in the context of .loop_put_str.
  mov qword [rbp-40], 1
  strbuf_idx equ qword [rbp-40]
  
  ; format buffer index. Only meaningful in the context of .loop_put_str.
  mov qword [rbp-48], 0
  buf_idx equ qword [rbp-48]
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
  push rdi
  c_to_put equ cl
  mov c_to_put, byte [rsi+r9]
  mov rax, strbuf_idx
  mov byte [strbuf+rax], c_to_put
  inc rax
  mov strbuf_idx, rax
  c_to_put equ
  pop rdi
.end_put_str:
  inc r9
  ; mov qword [rbp-48], r9
  mov buf_idx, r9
  jmp .loop_put_str

.match_backslash:
  ; at this point, r9, rsi and rdx should be loaded with buf_idx, t_buf and
  ; t_buflen respectively
  lea r10, [rsi+r9+1]
  ; if the backslash is the last char, do nothing.
  ; otherwise, look to the next char:
  ; - if next char is t, put 9 to strbuf.
  ; - if next char is n, put 10 to strbuf.
  cmp r10, [rsi+rdx]
  jl .match_backslash_peek_next
  jmp .end_match
  ; use r10 here
.match_backslash_peek_next:
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
    ; mov rax, qword [rbp-40]
    mov rax, strbuf_idx
    mov byte [strbuf+rax], to_put
    mov r9, buf_idx
    inc r9
    inc rax
    mov buf_idx, r9
    mov strbuf_idx, rax
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
  jmp .end_match

.end_loop_put_str:

  ; printing it out
  ; self-reminder, NEVER pass stuff to macros like this.
  ; Because rdi is used for the write syscall.
  write qword [rbp-8],strbuf,qword [rbp-24]
.cleanup:
  leave
  ret
  
section '.data' writeable
strbuf arr 1024
