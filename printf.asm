format ELF64

include "./io.inc"
include "./buff.inc"

section '.text' executable
public asm_printf
public asm_sprintf
extrn int32_to_str

; refer to any ASCII table out there
TAB = 9
NEWLINE = 10
CARRIAGE = 13

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
; fifth argument
; fourth argument
; LOWEST MEMORY ADDRESS
; r9 - third argument
; r8 - second argument
; rcx - first argument
;
; can be called from C.
;
; note: you probably think, after scrolling down and finding "asm_sprintf",
; "why don't you implement printf in terms of sprintf".
; for that, there are complications around passing va_args around. I need to
; change how the concept of va_list in here works.
;
; supported parse symbols:
; \n -> newline
; \t -> tab
; \\ -> backslash
; \% -> percent
; \r -> carriage
; %d -> number on va_arg list
; %s -> the buffer on va_arg list, followed by its length on va_arg list
asm_printf:
  ; Some macro to refer to memory positions more easily
  label .t_fd qword at rbp-8
  label .t_buf qword at rbp-16
  label .t_buflen qword at rbp-24
  label .va_arg_ptr qword at rbp-32
  label .retval qword at rbp-40
  label .strbuf_idx qword at rbp-48
  ; buf_idx equ qword [rbp-56]
  label .buf_idx qword at rbp-56
  label .va_arg_3 qword at rbp-64
  label .va_arg_2 qword at rbp-72
  label .va_arg_1 qword at rbp-80

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
  sub rsp, 80
  ; push all the arguments passed in to the stack
  mov [.t_fd], rdi
  mov [.t_buf], rsi
  mov [.t_buflen], rdx
  ; local variables
  lea rax, [rbp-80]
  mov [.va_arg_ptr], rax
  mov [.retval], 0
  mov [.va_arg_1], rcx
  mov [.va_arg_2], r8
  mov [.va_arg_3], r9

  ; strbuf index. Only meaningful in the context of .loop_put_str.
  mov [.strbuf_idx], 0
  
  ; format buffer index. Only meaningful in the context of .loop_put_str.
  mov [.buf_idx], 0
.loop_put_str:
  ; while (r9 < rdx)
  mov r9, [.buf_idx]
  mov rdx, [.t_buflen]
  cmp r9, rdx
  jge .end_loop_put_str
  ; while-body
  mov rsi, [.t_buf]
  cmp byte [rsi+r9], "\"
  je .match_backslash
  cmp byte [rsi+r9], "%"
  je .match_percent
.end_match:
  
.begin_put_str:
  c_to_put equ cl
  ; mov rsi, [.t_buf]
  mov c_to_put, byte [rsi+r9]
  mov rax, [.strbuf_idx]
  mov byte [strbuf+rax], c_to_put
  inc [.strbuf_idx]
  inc [.retval]
  c_to_put equ
.end_put_str:
  inc [.buf_idx]
  jmp .loop_put_str

; modifies r8 to be the position to write to.
macro bound_check label_if_ok, label_if_done {
  ; paranoia
  mov rsi, [.t_buf]
  mov r9, [.buf_idx]
  mov rdx, [.t_buflen]
  ; comparison
  lea r8, [rsi+r9+1]
  lea rax, [rsi+rdx]
  cmp r8, rax
  jl label_if_ok
  jmp label_if_done
}
.match_backslash:
  ; if the backslash is the last char, do nothing.
  ; otherwise, look to the next char:
  ; - if next char is t, put 9 to strbuf.
  ; - if next char is n, put 10 to strbuf.
  bound_check .match_backslash_peek_next, .end_match
.match_backslash_peek_next:
  ; use r8 here
  macro r8_match_char char_cmp, jmp_label {
    cmp byte [r8], char_cmp
    je jmp_label
  }
  r8_match_char "t", .match_backslash_put_tab
  r8_match_char "n", .match_backslash_put_newline
  r8_match_char "\", .match_backslash_put_backslash
  r8_match_char "%", .match_backslash_put_percent
  r8_match_char "r", .match_backslash_put_carriage
  jmp .begin_put_str

  ; only useful in the context of match_backslash really
  macro put_char to_put {
    mov rax, [.strbuf_idx]
    mov byte [strbuf+rax], to_put
    inc [.buf_idx]
    inc [.strbuf_idx]
    inc [.retval]
    jmp .end_put_str
  }
.match_backslash_put_tab:
  put_char TAB
.match_backslash_put_newline:
  put_char NEWLINE
.match_backslash_put_backslash:
  put_char "\"
.match_backslash_put_percent:
  put_char "%"
.match_backslash_put_carriage:
  put_char CARRIAGE
  
  purge put_char

  macro put_va_arg reg, opsize {
    local .point_to_stack, .inc, .cont
    mov rax, [.va_arg_ptr]
    mov reg, opsize [rax]
    ; va_arg_3 at rbp-64, so when we're done with that va_arg, jump to point
    ; on stack.
    lea rsi, [rbp-64]
    cmp rax, rsi
    jl .inc
    lea rsi, [rbp+16]
    cmp rax, rsi
    jge .inc
    .point_to_stack:
    lea rax, [rbp+8]
    mov [.va_arg_ptr], rax
    .inc:
    add [.va_arg_ptr], 8
    .cont:
  }
.match_percent:
  ; TODO: match_percent
  bound_check .match_percent_peek_next, .end_match
.match_percent_peek_next:
  r8_match_char "d", .match_percent_put_int
  r8_match_char "s", .match_percent_put_str
  jmp .begin_put_str
.match_percent_put_int:
  ; prepare to call the function
  mov [.t_buf], rsi
  ; get next arg in va_list 
  ;mov rax, [.va_arg_ptr]
  ;mov edi, dword [rax]
  ;add [.va_arg_ptr], 8
  put_va_arg edi, dword
  mov rax, [.strbuf_idx]
  lea rsi, [strbuf+rax]
  mov rdx, strbuf.len
  sub rdx, [.strbuf_idx]
  call int32_to_str
  mov rsi, [.t_buf]
  add [.retval], rax
  add [.strbuf_idx], rax
  inc [.buf_idx]
  jmp .end_put_str

.match_percent_put_str:
  ; get string-to-put buffer and its length
  put_va_arg r8, qword
  put_va_arg r9, qword
  mov rsi, strbuf
  add rsi, qword [.strbuf_idx]
  ;mov rdx, 0
  mov rax, 0
.match_percent_put_str_loop:
  ; only put stuff if we can still put
  cmp rax, r9
  je .end_match_percent_put_str_loop
  ; do some bound-checking before putting stuff on strbuf
  sub rsi, strbuf
  cmp rsi, strbuf.len
  je .end_match_percent_put_str_loop
  ; put stuff
  add rsi, strbuf
  mov dl, byte [r8+rax]
  mov byte [rsi], dl
  inc rax
  inc rsi
  inc [.strbuf_idx]
  inc [.retval]
  jmp .match_percent_put_str_loop
.end_match_percent_put_str_loop:
  inc qword [.buf_idx]
  jmp .end_put_str

  purge bound_check
.end_loop_put_str:

  ; printing it out
  write [.t_fd],strbuf,[.retval]
  mov rax, [.retval]
.cleanup:
  leave
  ret

; args:
; rdi: the buffer to put stuff to.
; rsi: the max length of the put-stuff buffer.
; rdx: the address of the format buffer.
; rcx: the length to format.
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
; can be called from C.
;
; supported parse symbols:
; \n -> newline
; \t -> tab
; \\ -> backslash
; \% -> percent
; \r -> carriage
; %d -> number on va_arg list
; %s -> the buffer on va_arg list, followed by its length on va_arg list
asm_sprintf:
  ; Some macro to refer to memory positions more easily
  label .t_put_buf qword at rbp-8
  label .t_put_buflen qword at rbp-16
  label .t_fmt_buf qword at rbp-24
  label .t_fmt_buflen qword at rbp-32
  label .va_arg_ptr qword at rbp-40
  label .retval qword at rbp-48
  ; buf_idx equ qword [rbp-56]
  label .putbuf_idx qword at rbp-56
  label .buf_idx qword at rbp-64
  label .va_arg_2 qword at rbp-72
  label .va_arg_1 qword at rbp-80

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
  sub rsp, 80
  ; push all the arguments passed in to the stack
  mov [.t_put_buf], rdi
  mov [.t_put_buflen], rsi
  mov [.t_fmt_buf], rdx
  mov [.t_fmt_buflen], rcx
  ; local variables
  lea rax, [rbp-80]
  mov [.va_arg_ptr], rax
  mov [.retval], 0
  mov [.va_arg_1], r8
  mov [.va_arg_2], r9

  ; strbuf index. Only meaningful in the context of .loop_put_str.
  mov [.putbuf_idx], 0
  
  ; format buffer index. Only meaningful in the context of .loop_put_str.
  mov [.buf_idx], 0
.loop_put_str:
  ; while (r9 < rdx)
  mov r9, [.buf_idx]
  mov rdx, [.t_fmt_buflen]
  cmp r9, rdx
  jge .end_loop_put_str
  ; while-body
  mov rsi, [.t_fmt_buf]
  cmp byte [rsi+r9], "\"
  je .match_backslash
  cmp byte [rsi+r9], "%"
  je .match_percent
.end_match:
  
.begin_put_str:
  c_to_put equ cl
  mov rsi, [.t_fmt_buf]
  mov c_to_put, byte [rsi+r9]
  mov rax, [.t_put_buf]
  add rax, [.putbuf_idx]
  mov byte [rax], c_to_put
  inc [.putbuf_idx]
  inc [.retval]
  c_to_put equ
.end_put_str:
  inc [.buf_idx]
  jmp .loop_put_str

; modifies r8 to be the position to write to.
macro bound_check label_if_ok, label_if_done {
  ; paranoia
  mov rsi, [.t_fmt_buf]
  mov r9, [.buf_idx]
  mov rdx, [.t_fmt_buflen]
  ; comparison
  lea r8, [rsi+r9+1]
  lea rax, [rsi+rdx]
  cmp r8, rax
  ; if the backslash is the last char, do nothing.
  ; otherwise, look to the next char:
  ; - if next char is t, put 9 to strbuf.
  ; - if next char is n, put 10 to strbuf.
  jl label_if_ok
  jmp label_if_done
}
.match_backslash:
  ; at this point, r9, rsi and rdx should be loaded with buf_idx, .t_buf and
  ; .t_buflen respectively
  bound_check .match_backslash_peek_next, .end_match
.match_backslash_peek_next:
  ; use r8 here
  macro r8_match_char char_cmp, jmp_label {
    cmp byte [r8], char_cmp
    je jmp_label
  }
  r8_match_char "t", .match_backslash_put_tab
  r8_match_char "n", .match_backslash_put_newline
  r8_match_char "\", .match_backslash_put_backslash
  r8_match_char "%", .match_backslash_put_percent
  r8_match_char "r", .match_backslash_put_carriage
  jmp .begin_put_str

  ; only useful in the context of match_backslash really
  macro put_char to_put {
    mov rax, [.t_put_buf]
    add rax, [.putbuf_idx]
    mov byte [rax], to_put
    inc [.buf_idx]
    inc [.putbuf_idx]
    inc [.retval]
    jmp .end_put_str
  }
.match_backslash_put_tab:
  put_char TAB
.match_backslash_put_newline:
  put_char NEWLINE
.match_backslash_put_backslash:
  put_char "\"
.match_backslash_put_percent:
  put_char "%"
.match_backslash_put_carriage:
  put_char CARRIAGE
  
  purge put_char

  macro put_va_arg reg, opsize {
    local .point_to_stack, .inc, .cont
    mov rax, [.va_arg_ptr]
    mov reg, opsize [rax]
    ; va_arg_3 at rbp-64, so when we're done with that va_arg, jump to point
    ; on stack.
    lea rsi, [rbp-72]
    cmp rax, rsi
    jl .inc
    lea rsi, [rbp+16]
    cmp rax, rsi
    jge .inc
    .point_to_stack:
    lea rax, [rbp+8]
    mov [.va_arg_ptr], rax
    .inc:
    add [.va_arg_ptr], 8
    .cont:
  }
.match_percent:
  ; TODO: match_percent
  bound_check .match_percent_peek_next, .end_match
.match_percent_peek_next:
  r8_match_char "d", .match_percent_put_int
  r8_match_char "s", .match_percent_put_str
  jmp .begin_put_str
.match_percent_put_int:
  ; prepare to call the function
  mov [.t_fmt_buf], rsi
  ; get next arg in va_list 
  ;mov rax, [.va_arg_ptr]
  ;mov edi, dword [rax]
  ;add [.va_arg_ptr], 8
  put_va_arg edi, dword
  mov rsi, [.t_put_buf]
  add rsi, [.putbuf_idx]
  ; lea rsi, [strbuf+rax]
  mov rdx, [.t_put_buflen]
  sub rdx, [.putbuf_idx]
  call int32_to_str
  mov rsi, [.t_fmt_buf]
  add [.retval], rax
  add [.putbuf_idx], rax
  inc [.buf_idx]
  jmp .end_put_str

.match_percent_put_str:
  ; get string-to-put buffer and its length
  put_va_arg r8, qword
  put_va_arg r9, qword
  mov rsi, qword [.t_put_buf] 
  add rsi, qword [.putbuf_idx]
  ;mov rdx, 0
  mov rax, 0
.match_percent_put_str_loop:
  ; only put stuff if we can still put
  cmp rax, r9
  je .end_match_percent_put_str_loop
  ; do some bound-checking before putting stuff on put_buf
  sub rsi, [.t_put_buf]
  cmp rsi, [.t_put_buflen]
  je .end_match_percent_put_str_loop
  ; put stuff
  add rsi, [.t_put_buf]
  mov dl, byte [r8+rax]
  mov byte [rsi], dl
  inc rax
  inc rsi
  inc [.putbuf_idx]
  inc [.retval]
  jmp .match_percent_put_str_loop
.end_match_percent_put_str_loop:
  inc qword [.buf_idx]
  jmp .end_put_str

  purge bound_check
.end_loop_put_str:

  ; printing it out
  ; write [.t_fd],strbuf,[.retval]
  mov rax, [.retval]
.cleanup:
  leave
  ret
  
section '.data' writeable
strbuf arr 1024
