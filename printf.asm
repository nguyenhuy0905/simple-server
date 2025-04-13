format ELF64

include "./io.inc"

section '.text' executable
public printf

; refer to any ASCII table out there
TAB = 9
NEWLINE = 10
BACKSLASH = "\"

; args:
; al: number of registered va_args
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
;
; supported parse symbols:
; \n -> newline
; \t -> tab
; \\ -> backslash
printf:
  push rbp
  mov rbp, rsp
  ; save some supposedly persistent registers
  push r10

  ; variables, I suppose?
  ; these are FASM keywords to define symbolic constants.
  ; I follow my notations in C++ here:
  ; t_ prefix = args passed in to function.
  ; t_p_ prefix = pointer args passed in to function.
  ; 
  ; u8 t_n_va_args
  t_n_va_args equ al
  ; i32 t_fd
  t_fd equ edi
  ; u64 t_p_buff
  t_p_buff equ rsi
  ; u64 t_len
  t_len equ rdx
  ; u64 arg_ptr
  arg_ptr equ rcx
  ; u64 strbuf_pos
  ; increment AFTER putting a char in.
  strbuf_pos equ r8

  ; convenience macro
  ; ONLY USE IN MATCHES
  macro put_char to_put {
    mov byte [strbuf+strbuf_pos], to_put
    inc loop_idx
    inc strbuf_pos
    jmp .end_put_str
  }

  mov strbuf_pos, 1
  loop_idx equ r9
  mov loop_idx, 0
.loop_put_str:
  ; while (loop_idx < t_len)
  cmp loop_idx, t_len
  je .end_loop_put_str
  ; while-body
  cmp byte [t_p_buff+loop_idx], BACKSLASH
  je .match_backslash
.end_match:
  
.begin_put_str:
  ; put_char doesn't work super well here
  push rcx
  c_to_put equ cl
  mov c_to_put, byte [t_p_buff+loop_idx]
  mov byte [strbuf+strbuf_pos], c_to_put
  inc strbuf_pos
  c_to_put equ
  pop rcx
.end_put_str:
  inc loop_idx
  jmp .loop_put_str

.match_backslash:
  p_next_char equ r10
  lea p_next_char, [t_p_buff+loop_idx+1]
  ; if the backslash is the last char, do nothing.
  ; otherwise, look to the next char:
  ; - if next char is t, put 9 to strbuf.
  ; - if next char is n, put 10 to strbuf.
  cmp loop_idx, t_len
  jl .match_backslash_peek_next
  jmp .end_match
.match_backslash_peek_next:
  macro case char_cmp, jmp_label {
    cmp byte [p_next_char], char_cmp
    je jmp_label
  }
  case "t", .match_backslash_put_tab
  case "n", .match_backslash_put_newline
  case "\", .match_backslash_put_backslash
  jmp .begin_put_str

.match_backslash_put_tab:
  put_char TAB
.match_backslash_put_newline:
  put_char NEWLINE
.match_backslash_put_backslash:
  put_char BACKSLASH

.end_loop_put_str:
  ; referring to loop_idx now does no shits.
  loop_idx equ

  ; printing it out
  ; self-reminder, NEVER pass stuff to macros like this.
  ; Because rdi is used for the write syscall.
  write rdi,strbuf,rdx
.cleanup:
  pop r10
  leave
  ret
  
section '.data' writeable
strbuf:
repeat 4096
db 0
end repeat
.len = $-strbuf
