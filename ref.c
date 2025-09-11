#define _DEFAULT_SOURCE
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>

int main(/*int argc, char *argv[]*/) {
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
  printf("htons(6969) = %d\n", htons(6969));
  printf("manual math, htons: %d\n", ((1024 / 256)) + ((1024 % 256) << 8));

  // checking how network-byte-order works
  // ref: man 3 inet_aton
  struct in_addr addr;
  if (inet_aton("127.0.0.1", &addr) == 0) {
    fprintf(stderr, "Invalid address\n");
    exit(EXIT_FAILURE);
  }
  printf("127.0.0.1 network byte order: %d\n", addr.s_addr);
  int first_highest = addr.s_addr >> 24;
  int sum_highest = first_highest << 24;
  printf("8 highest bits: %d\n", first_highest);
  int second_highest = (addr.s_addr - sum_highest) >> 16;
  sum_highest += second_highest << 16;
  printf("8 2nd highest bits: %d\n", second_highest);
  int third_highest = (addr.s_addr - sum_highest) >> 8;
  sum_highest += third_highest << 8;
  printf("8 3nd highest bits: %d\n", third_highest);
  int lowest = (addr.s_addr - sum_highest);
  printf("8 lowest highest bits: %d\n", lowest);

  printf("SHUT_RD: %d\n", SHUT_RD);
  printf("SHUT_WR: %d\n", SHUT_WR);
  printf("SHUT_RDWR: %d\n", SHUT_RDWR);

  return EXIT_SUCCESS;
}
