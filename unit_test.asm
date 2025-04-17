format ELF64

include "./buff.inc"
include "./io.inc"
include "./program.inc"

; unit test functions:
; take no argument
; return on rax
; 0 for success
; anything else for failure

extrn uint32_to_str
section '.text' executable
public _start
_start:
  call strfmt_zero
  call strfmt_10_divisible
  call strfmt_10_not_divisible
  exit 0

strfmt_zero:
  push rbp
  mov rbp, rsp
  mov edi, 0
  mov rsi, strbuf
  mov rdx, strbuf.len
  call uint32_to_str
  cmp rax, 0
  je .success1
  write STDOUT, strfmt_zero_fail_1, strfmt_zero_fail_1.len
  mov rax, 0
.success1:
  ; comment this out to see if it prints 0
  ; write STDOUT, strbuf, 1
  leave
  ret

strfmt_out_of_space:
  ; simulates an out-of-space case
  push rbp
  mov rbp, rsp
  mov edi, 69
  mov rsi, strbuf
  mov rdx, 0
  call uint32_to_str
  cmp rax, 0
  je .cleanup
  write STDOUT, strfmt_out_of_space_fail_1, strfmt_out_of_space_fail_1.len
.cleanup:
  leave
  ret

strfmt_10_divisible:
  push rbp
  mov rbp, rsp
  mov edi, 10
  mov rsi, strbuf
  mov rdx, strbuf.len
  call uint32_to_str
  cmp rax, 2
  je .success1
  write STDOUT, strfmt_10_divisible_fail_1, strfmt_10_divisible_fail_1.len
.success1:
  ; comment this out to see if it prints 10
  ; write STDOUT, strbuf, 2
  mov rax, 0
  leave
  ret

strfmt_10_not_divisible:
  push rbp
  mov rbp, rsp
  mov edi, 128
  mov rsi, strbuf
  mov rdx, strbuf.len
  call uint32_to_str
  cmp rax, 3
  je .success1
  write STDOUT, strfmt_10_not_divisible_fail_1, strfmt_10_not_divisible_fail_1.len
.success1:
  ; comment this out to see if it prints 128
  ; write STDOUT, strbuf, 3
  mov rax, 0
  leave
  ret

section '.data' writeable
strbuf arr 1024
strfmt_zero_fail_1 string "strfmt_zero, case 1 failed!"
strfmt_out_of_space_fail_1 string "strfmt_out_of_space, case 1 failed!"
strfmt_10_divisible_fail_1 string "strfmt_10_divisible, case 1 failed!"
strfmt_10_not_divisible_fail_1 string "strfmt_10_not_divisible, case 1 failed!"
