#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>

int main(int argc, char *argv[]) {
  printf("AF_INET: %d\n", AF_INET);
  printf("SOCK_STREAM: %d\n", SOCK_STREAM);
  struct sockaddr_in sock_in = {0};
  // sockaddr_in {
  //   uint16_t sin_family;
  //   uint16_t sin_port;
  //   struct in_addr {
  //     uint32_t s_addr;
  //   } sin_addr;
  //   byte sin_zero[8]; (padding)
  // }
  printf("sizeof(sin_family) = %lu\n", sizeof(sock_in.sin_family));
  printf("sizeof(sin_port) = %lu\n", sizeof(sock_in.sin_port));
  printf("sizeof(sin_addr.s_addr) = %lu\n", sizeof(sock_in.sin_addr.s_addr));

  return EXIT_SUCCESS;
}
