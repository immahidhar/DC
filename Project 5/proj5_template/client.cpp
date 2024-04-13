#include "common.h"
#include "client.h"
#include "math.h"

#define _INCLUDE_RTT_CODE_

int SERVERPORT = 51000;
//char SERVERNODE[100] = "lingprog8.cs.fsu.edu";
char SERVERNODE[100] = "ec2-35-170-70-54.compute-1.amazonaws.com";
//char SERVERNODE[100] = "localhost";
char SERVERIP[40];

char server_sock_buf[MY_SOCK_BUFFER_LEN];
int server_sock_buf_byte_counter;
fd_set master;   
fd_set read_fds;   
int highestsocket = -1;
int serversockfd = -1;

// new change below
char* packetOutput;
double last_time;
double interval = 0;
int msgCount = 0;

int connect_to_server(const char* IP, int PORT)
{
    struct sockaddr_in server_addr; // peer address\n";
    int sockfd;
    
    if ((sockfd = socket(PF_INET, SOCK_STREAM, 0)) == -1) {
        printf("Cannot create a socket");
        return -1;
    }
    
    server_addr.sin_family = AF_INET;    // host byte order 
    server_addr.sin_port = htons(PORT);  // short, network byte order 
    inet_aton(IP, (struct in_addr *)&server_addr.sin_addr.s_addr);
    memset(&(server_addr.sin_zero), '\0', 8);  // zero the rest of the struct 

    if (connect(sockfd, (struct sockaddr *)&server_addr, sizeof(struct sockaddr)) == -1) {
         printf("Error connecting to the server %s on port %d\n",IP,PORT);
         sockfd = -1;
         exit(1);
    }

    if (sockfd != -1)  {
        FD_SET(sockfd, &master);
        if (highestsocket <= sockfd) {
            highestsocket = sockfd;
        } 
    }
    return sockfd; 
}

void client_init(void)
{
    struct hostent     *he_server;
    if ((he_server = gethostbyname(SERVERNODE)) == NULL) {
        printf("error resolving hostnam for server %s\n",SERVERNODE);
        fflush(stdout);
        exit(1);
    }

    struct sockaddr_in  server;
    memcpy(&server.sin_addr, he_server->h_addr_list[0], he_server->h_length);
    printf("SERVER IP is %s\n",inet_ntoa(server.sin_addr));
    strcpy(SERVERIP,inet_ntoa(server.sin_addr));

    FD_ZERO(&master);    // clear the master and temp sets
    FD_ZERO(&read_fds);
    
    serversockfd =  connect_to_server(SERVERIP,SERVERPORT);
    printf("Connected to the server on socket %d\n",serversockfd); 

     FD_SET(fileno(stdin), &master);
     if (fileno(stdin) > highestsocket) {
          highestsocket = fileno(stdin);
     }

     // new change below
     packetOutput = (char*) malloc(MAXBUFLEN);

}

void process_server_message(Packet *packet)
{
    printf("got something on socket %d from the server\n",serversockfd); 
    // TODO
    // new change below
    double current_time = getcurrenttime();
    char* packetBuf = (char*) malloc(MAXIPLEN);
    memcpy(packetBuf, packet->data, MAXIPLEN);
    strcat(packetOutput, packetBuf);
    if(last_time != NULL) {
        interval += current_time - last_time;
        msgCount++;
    }
    last_time = current_time;
}

// new change below
void printOutput(void) {
    printf("\n%s\n", packetOutput);
    printf("\nAverage interval = %lf seconds\n \n", (interval/msgCount));
}

// new change below
void clearMem(void) {
    free(packetOutput);
}

void read_from_activesockets(void)
{
    int nbytes;
    unsigned char buf[10000];	

    if ((serversockfd != -1) && FD_ISSET(serversockfd,&read_fds) ) {
        nbytes = recv(serversockfd, buf, MAXBUFLEN, 0);
        // handle server response or data         
        if ( nbytes <= 0) {
            // got error or connection closed by client
            if (nbytes == 0) {
		        // TODO
                // new change below
                printOutput();
                clearMem();
                exit(0);
            } else {
                printf("client recv error from server \n");
            }
            close(serversockfd); // bye!
            FD_CLR(serversockfd, &master); // remove from master set
            serversockfd = -1;
        } else {
            memcpy(server_sock_buf + server_sock_buf_byte_counter, buf, nbytes);
            server_sock_buf_byte_counter += nbytes;
            int num_to_read = sizeof(Packet);
            while (num_to_read <= server_sock_buf_byte_counter) {
                Packet* packet = (Packet*) (server_sock_buf);     
                process_server_message(packet);
                remove_read_from_buf(server_sock_buf, num_to_read);
                server_sock_buf_byte_counter -= num_to_read;
            }
        }
     }
}

void client_run(void)
{
    while (1) {
        read_fds = master; 
        struct timeval timeout;
        timeout.tv_sec = 0;
        timeout.tv_usec = 10000;

        if (select(highestsocket+1, &read_fds, NULL, NULL, &timeout) == -1) {
            if (errno == EINTR) {
                printf("Select for client interrupted by interrupt...\n");
            } else {
                printf("Select problem .. client exiting iteration\n");
                fflush(stdout);
                exit(1);
            }
        }
        read_from_activesockets();
    }           
}

int main(int argc, char** argv)
{
    client_init();
    client_run();
    return 0;
}

