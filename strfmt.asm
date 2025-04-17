format ELF64
include "./buff.inc"

; function call convention:
; rax: 1st return value
; rdi: 1st arg
; rsi: 2nd arg
; rdx: 3rd arg, 2nd return value if any
; rcx: 4th arg
; r8: 5th arg
; r9: 6th arg

; preserved registers through func calls:
; r12-r15, rbx, rsp, rbp

section '.text' executable
public uint32_to_str
; converts an unsigned integer to a string
; arguments:
; edi: the number to convert
; rsi: the buffer to put the converted number into
; rdx: max size of buffer
; 
; return value:
; rax: number of bytes put to the buffer
uint32_to_str:
  ; Imma just maintain stack frame to more easily debug.
  push rbp
  mov rbp, rsp
  ; Technically I only need to sub 8. This aligns the stack.
  ; Or so I think. Pretty sure I need to align to at least 8.
  ; not entirely sure about 16.
  sub rsp, 16
  mov qword [rbp-8], rsi
  
  call uint32_to_str_recursive
  cmp rax, 0
  jne .cleanup
  ; if rax == 0, aka, nothing is written with the recursive function, aka, we
  ; need to write a 0.
  mov rsi, qword [rbp-8]
  mov byte [rsi], '0'
.cleanup:
  leave
  ret

; converts a signed integer to a string
; arguments:
; edi: the number to convert
; rsi: the buffer to put the converted number into
; rdx: max size of buffer
; 
; return value:
; rax: number of bytes put to the buffer
int32_to_str:
  push rbp
  mov rbp, rsp
  cmp edi, 0
  jge .delegate
  ; only write if we can write
  cmp rdx, 0
  jle .cleanup
  mov byte [rsi], '-'
  neg edi
  inc rsi
  dec rdx

.delegate:
  sub rsp, 8
  call uint32_to_str
.cleanup:
  leave
  ret

; private recursive stuff for uint32_to_str
; arguments:
; edi: the number to convert. Other functions should call this with edi larger
; than 0, but this function will recurse until edi equals 0.
; rsi: the buffer to put the converted number into. Higher index == higher
; address.
; rdx: max size of buffer
; extra argument compared to its public buddy:
; return:
; rax: number of bytes put to the buffer
uint32_to_str_recursive:
  push rbp
  mov rbp, rsp
  ; if nothing happens, return value is 0
  mov rax, 0
  ; if number to convert is already 0, do nothing
  cmp edi, 0
  ; somehow it cannot find label .cleanup here
  jne .continue
  leave
  ret
.continue:
  ; otherwise, do a division
  mov edx, 0
  mov eax, edi
  mov r8d, 10
  div r8d
  ; eax: quotient, edx: remainder
  ; put remainder to buffer
  ; define some labels beforehand
  ; sizes of edi + rsi + rdx + rcx + edx. Just add extra padding in case
  stack_alloc_space = 8 + 8 + 8 + 8
  sub rsp, stack_alloc_space
  offset = 8
  label t_buf qword at rbp-offset
  offset = offset+8
  label t_siz qword at rbp-offset
  offset = offset+8
  label t_cnt qword at rbp-offset
  offset = offset+8
  label remainder byte at rbp-offset
  remainder_off = offset
  offset = offset+1

  mov [t_buf], rsi
  mov [t_siz], rdx
  mov [t_cnt], rcx
  mov qword [rbp-remainder_off], 0
  mov [remainder], dl
  ; prepare to call the function recursively
  mov edi, eax
  ; inc rsi
  ; dec rdx
  ; inc rcx
  call uint32_to_str_recursive
  ; recover the buffer, and find the position to write shits to
  mov rsi, [t_buf]
  sub rdx, rax
  ; let's write
  mov dl, [remainder]
  add dl, '0'
  ; only write if we can write
  cmp rdx, 0
  jle .cleanup
  mov byte [rsi+rax], dl
  inc rax
  dec rdx
.cleanup:
  leave
  ret
