#include <stddef.h>
#include <stdint.h>

extern size_t asm_printf(int t_fd, const char* t_addr, size_t t_len, ...);
static const char str_to_print[] = "Hello\t %d/%d/%d\n";
static const size_t strsize = sizeof(str_to_print);

void _start() {
  size_t retcode = 0;
  asm_printf(1, str_to_print, strsize, 20, 4, 2025);
  __asm__ ("mov $60, %%rax\n\t"
          "mov %[retcode], %%rdi\n\t"
          "syscall\n\t"
          :
          : [retcode] "r"(retcode)
          : "rax" );
}
