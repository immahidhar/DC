#include "common.h"
#include <sys/types.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>



double getcurrenttime()
{
    struct timeval timestruct;
    gettimeofday(&timestruct,NULL);
    return (double)( 1.0 *timestruct.tv_sec + (timestruct.tv_usec/1000000.0) );        
}


void remove_read_from_buf(char *buf, int num)
{
    char tempbuf[MY_SOCK_BUFFER_LEN];

    memcpy(tempbuf, buf + num, MY_SOCK_BUFFER_LEN - num);
    memcpy(buf, tempbuf, MY_SOCK_BUFFER_LEN);
}


int send_a_control_packet_to_socket(int sockfd, Packet *packet)
{
    char buf[MY_SOCK_BUFFER_LEN];
    memcpy(&(buf[0]), (char *)packet, sizeof(Packet));    

    int send_result = send(sockfd, (void*)(buf), sizeof(Packet), 0);

    return send_result;
}


