#ifndef __COMMON_H

#define __COMMON_H

#include <sys/time.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>
#include <getopt.h>
#include <netdb.h>
#include <netinet/in.h>
#include <iostream>
#include <vector>
#include <map>
#include <set>
#include <queue>
#include <list>
#include <stdint.h>
#include <string.h>


#define MAXBUFLEN 100000
#define MAXIPLEN 100
#define MY_SOCK_BUFFER_LEN 3000

struct Packet
{
    unsigned char data[100];	
};

int send_a_control_packet_to_socket(int sockfd, Packet *packet);
double getcurrenttime();
void remove_read_from_buf(char *buf, int num);

using namespace std;


#endif
