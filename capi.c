#include <stddef.h>
#include <stdint.h>

extern size_t asm_printf(int t_fd, const char *t_addr, size_t t_len, ...);
extern size_t asm_sprintf(char *restrict t_put_buf, size_t t_put_buf_len,
                          const char *restrict t_fmt_buf, size_t t_fmt_buf_len,
                          ...);
constexpr char str_to_print[] = "Hello\t %d/%d/%d\n";
constexpr size_t strsize = sizeof(str_to_print);
static char fmt_buf[1024] = {0};
constexpr size_t fmt_buf_size = sizeof(fmt_buf);

[[noreturn]] void nolibc_exit(int retcode) {
  __asm__("mov $60, %%rax\n\t"
          "mov %[retcode], %%rdi\n\t"
          "syscall\n\t"
          :
          : [retcode] "r"((int64_t)retcode)
          : "rax");
  unreachable();
}

void _start() {
  asm_printf(1, str_to_print, strsize-1, 200000, 40000, 2025);
  int putsiz =
      asm_sprintf(fmt_buf, fmt_buf_size, str_to_print, strsize-1, 20, 4, 2025);
  asm_printf(1, fmt_buf, putsiz);
  nolibc_exit(0);
}
