#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <sys/socket.h>

struct sl {
  struct sockaddr_in addr;
};

int main(int argc, char *argv[]) {
  printf("htonl of loopback: %d\n", htonl(INADDR_LOOPBACK));
  printf("htons of port 6969: %d\n", htons(6969));
  struct sockaddr_in addr = {.sin_family = AF_INET,
                             .sin_port = 8080,
                             .sin_addr = htonl(INADDR_LOOPBACK)};

  return 0;
}
