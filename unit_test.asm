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
extrn int32_to_str
section '.text' executable
public _start
_start:
  ; currently failing out_of_space cases.
  call uint32_to_str_zero
  call uint32_to_str_10_divisible
  call uint32_to_str_10_not_divisible
  call uint32_to_str_out_of_space
  call int32_to_str_zero
  call int32_to_str_10_divisible
  call int32_to_str_10_not_divisible
  call int32_to_str_out_of_space
  exit 0

uint32_to_str_zero:
  push rbp
  mov rbp, rsp
  mov edi, 0
  mov rsi, strbuf
  mov rdx, strbuf.len
  call uint32_to_str
  cmp rax, 1
  je .success1
  write STDOUT, uint32_to_str_zero_fail_1, uint32_to_str_zero_fail_1.len
  mov rax, 0
.success1:
  ; comment this out to see if it prints 0
  ; write STDOUT, strbuf, 1
  leave
  ret

uint32_to_str_out_of_space:
  ; simulates an out-of-space case
  push rbp
  mov rbp, rsp
  mov edi, 69
  mov rsi, strbuf
  mov rdx, 0
  call uint32_to_str
  cmp rax, 0
  je .cleanup
  write STDOUT, uint32_to_str_out_of_space_fail_1, uint32_to_str_out_of_space_fail_1.len
.cleanup:
  leave
  ret

uint32_to_str_10_divisible:
  push rbp
  mov rbp, rsp
  mov edi, 10
  mov rsi, strbuf
  mov rdx, strbuf.len
  call uint32_to_str
  cmp rax, 2
  je .success1
  write STDOUT, uint32_to_str_10_divisible_fail_1, uint32_to_str_10_divisible_fail_1.len
.success1:
  ; comment this out to see if it prints 10
  ; write STDOUT, strbuf, 2
  mov rax, 0
  leave
  ret

uint32_to_str_10_not_divisible:
  push rbp
  mov rbp, rsp
  mov edi, 128
  mov rsi, strbuf
  mov rdx, strbuf.len
  call uint32_to_str
  cmp rax, 3
  je .success1
  write STDOUT, uint32_to_str_10_not_divisible_fail_1, uint32_to_str_10_not_divisible_fail_1.len
.success1:
  ; comment this out to see if it prints 128
  ; write STDOUT, strbuf, 3
  mov rax, 0
  leave
  ret

; just a repeat of the uint32 test suite, but for signed version
int32_to_str_zero:
  push rbp
  mov rbp, rsp
  mov edi, 0
  mov rsi, strbuf
  mov rdx, strbuf.len
  call int32_to_str
  cmp rax, 1
  je .success1
  write STDOUT, int32_to_str_zero_fail_1, int32_to_str_zero_fail_1.len
  mov rax, 0
.success1:
  ; comment this out to see if it prints 0
  ; write STDOUT, strbuf, 1
  leave
  ret

int32_to_str_out_of_space:
  ; simulates an out-of-space case
  push rbp
  mov rbp, rsp
  mov edi, 69
  mov rsi, strbuf
  mov rdx, 0
  call int32_to_str
  cmp rax, 0
  je .cleanup
  write STDOUT, int32_to_str_out_of_space_fail_1, int32_to_str_out_of_space_fail_1.len
.cleanup:
  leave
  ret

int32_to_str_10_divisible:
  push rbp
  mov rbp, rsp
  mov edi, -10
  mov rsi, strbuf
  mov rdx, strbuf.len
  call int32_to_str
  cmp rax, 3
  je .success1
  write STDOUT, int32_to_str_10_divisible_fail_1, int32_to_str_10_divisible_fail_1.len
.success1:
  ; comment this out to see if it prints -10
  ; write STDOUT, strbuf, 3
  mov rax, 0
  leave
  ret

int32_to_str_10_not_divisible:
  push rbp
  mov rbp, rsp
  mov edi, -128
  mov rsi, strbuf
  mov rdx, strbuf.len
  call int32_to_str
  cmp rax, 4
  je .success1
  write STDOUT, int32_to_str_10_not_divisible_fail_1, int32_to_str_10_not_divisible_fail_1.len
.success1:
  ; comment this out to see if it prints -128
  ; write STDOUT, strbuf, 4
  mov rax, 0
  leave
  ret

section '.data' writeable
strbuf arr 1024
uint32_to_str_zero_fail_1 string "uint32_to_str_zero, case 1 failed!"
uint32_to_str_out_of_space_fail_1 string "uint32_to_str_out_of_space, case 1 failed!"
uint32_to_str_10_divisible_fail_1 string "uint32_to_str_10_divisible, case 1 failed!"
uint32_to_str_10_not_divisible_fail_1 string "uint32_to_str_10_not_divisible, case 1 failed!"

int32_to_str_zero_fail_1 string "int32_to_str_zero, case 1 failed!"
int32_to_str_out_of_space_fail_1 string "int32_to_str_out_of_space, case 1 failed!"
int32_to_str_10_divisible_fail_1 string "int32_to_str_10_divisible, case 1 failed!"
int32_to_str_10_not_divisible_fail_1 string "int32_to_str_10_not_divisible, case 1 failed!"
