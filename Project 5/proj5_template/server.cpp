#include "common.h"
#include "server.h"

int SERVERPORT = 8080;
double SERVER_AVG_DELAY = 0.005;
double SERVER_DEV_DELAY = 0.0;
double SERVER_PROB_DROP = 0.0;
double SERVER_PROB_DUP = 0.0;
double SERVER_ECHO_MIN_INTERVAL = 1.0;
int SERVER_TX_QUEUE_MAX = 1000;

const char msg0[] = "We are proud to be home to five NSF CAREER Award winners, a US Dept. of Energy Early Career Principal Investigator Award winner, an AFOSR Young Investigator Award winner, three Fulbright Scholar Award winners, an IEEE Fellow, ACM Distinguished Scientists, and a FSU Distinguished Research Professor. Our faculty are among the world’s leaders in Algorithms, Architecture, Databases, Distributed Systems, High-Performance Computing, Networking, Programming Languages and Compilers, Scientific Computing, Security, Software Engineering, and Vision.";

void read_config(const char* configfile)
{
    FILE* f = fopen(configfile,"r");
    if (f)
    {
	int dummy;
        dummy = fscanf(f,"SERVERPORT %d\n",&SERVERPORT);
        dummy = fscanf(f,"SERVER_AVG_DELAY %lf\n",&SERVER_AVG_DELAY);
        dummy = fscanf(f,"SERVER_DEV_DELAY %lf\n",&SERVER_DEV_DELAY);
        dummy = fscanf(f,"SERVER_PROB_DROP %lf\n",&SERVER_PROB_DROP);
        dummy = fscanf(f,"SERVER_PROB_DUP %lf\n",&SERVER_PROB_DUP);
	dummy = fscanf(f,"SERVER_ECHO_MIN_INTERVAL %lf\n",&SERVER_ECHO_MIN_INTERVAL);
        fclose(f);
    }
    else
    {
        printf("cannot open config file!\n");  
        fflush(stdout);
        exit(1);
    }
}

class TXevent{
public:
    struct Packet pkt;
    double time;

    TXevent()
    {
        time  =-1;
    }
};

class Connection
{
public:
    int socket;
    char sock_buf[MY_SOCK_BUFFER_LEN];
    int sock_buf_byte_counter;
    int clientid;	
    struct Packet pkt;
    vector<TXevent> TXq;
    double lasttxtime;
    int msgpoiter;

    Connection()
    {
    socket = -1;
    sock_buf_byte_counter = 0;
    clientid = -1;
    lasttxtime = 0;
    msgpoiter = 0;
    }

    Connection(int sock, int id)
    {
    socket = sock;
    sock_buf_byte_counter = 0;
    clientid = id;
    lasttxtime = 0;
    msgpoiter = 0;
    }
};
vector<Connection> activeconnections;

// master file descriptor list
fd_set master;   
fd_set read_fds; // temp file descriptor list for select()
// listening socket descriptor for p2p connections
int listener;     
// socket for getting server responses
int serversockfd;
// highest file descriptor seen so far
int highestsocket;
void read_from_activesockets();
int server_curr_clientid = 0;

void send_packet_to_client(int sockettosend, Packet *packet)
{
    int send_result = send_a_control_packet_to_socket(sockettosend, packet);
    if (send_result == -1)  {
        printf("Oh! Cannot send packet to client\n");
        if (errno == EPIPE) {
            printf("Trouble sending data on socket %d to client with EPIPE .. CLOSING HIS CONNECTION\n", sockettosend);
            //printf("Trouble sending data on socket %d to client %d with EPIPE .. CLOSING HIS CONNECTION\n", socket2send, event->recipient);
        }
    } else {
        // printf("Ha! Sent packet to client %d!\n", clientid);
        //printpacket((char*) packet, PACKET_SIZE);            
    }    
}

void read_from_activesockets(void)
{
    struct sockaddr_in remoteaddr; // peer address
    int newfd;        // newly accept()ed socket descriptor
    char buf[MAXBUFLEN];    // buffer for client data
    int nbytes;
    socklen_t addrlen;

    if (FD_ISSET(listener,&read_fds))
    {
        addrlen = sizeof(remoteaddr);
        if ((newfd = accept(listener, (struct sockaddr *)&remoteaddr,&addrlen)) == -1) 
        { 
             printf("Trouble accepting a new connection");
        } 
        else 
        {
            FD_SET(newfd, &master); // add to master set
            if (newfd > highestsocket) 
            { 
                 highestsocket = newfd;
            }
            printf("New connection from %s port number %d on socket %d assigned ID %d\n", inet_ntoa(remoteaddr.sin_addr), remoteaddr.sin_port, newfd, server_curr_clientid);
            Connection newconn(newfd, server_curr_clientid);    
            server_curr_clientid ++; 	
            activeconnections.push_back(newconn);
       }
    }
    else
    {        
         // run through the existing connections looking for data to read
         for(int conniter = 0; conniter < activeconnections.size(); conniter++) 
         {
             if (FD_ISSET(activeconnections[conniter].socket, &read_fds)) 
             {
                 nbytes = recv(activeconnections[conniter].socket, buf, MAXBUFLEN, 0);
                 if ( nbytes <= 0) 
                 {
                      // got error or connection closed by client
                     if (nbytes == 0) 
                      {
                          // connection closed
                          printf("Socket %d client hung up\n", activeconnections[conniter].socket);
                     } 
                      else 
                     {
                           printf("server recv error \n");
                     }
       
                     close(activeconnections[conniter].socket); // bye!
                     FD_CLR(activeconnections[conniter].socket, &master); // remove from master set
                     activeconnections.erase(activeconnections.begin()+conniter);
                     conniter --;
                 }
                 else
                 {
                     // printf("Got %d bytes from socket %d client\n", nbytes, activeconnections[conniter].socket);
                     memcpy(activeconnections[conniter].sock_buf + activeconnections[conniter].sock_buf_byte_counter, buf, nbytes);
                     activeconnections[conniter].sock_buf_byte_counter += nbytes;

                     int num_to_read = sizeof(Packet); 
                     while (num_to_read <= activeconnections[conniter].sock_buf_byte_counter)
                     {
                         Packet* packet = (Packet*) (activeconnections[conniter].sock_buf);  
 	  	         // printf("got from socket %d ID %d client sequence number %d\n", activeconnections[conniter].socket, activeconnections[conniter].clientid, packet->seq);	
                         struct Packet thispacket; 

			 double thisrand = drand48();
                         if (drand48() > SERVER_PROB_DROP && activeconnections[conniter].TXq.size() < SERVER_TX_QUEUE_MAX) {
                             int heresendnum = 1;
                             if (drand48() < SERVER_PROB_DUP) heresendnum = 2; 
                             for (int h=0;h<heresendnum;h++) {
                                 double thisdev = (drand48()-0.5)*2*SERVER_DEV_DELAY; 
                                 TXevent thisevent;
                                 thisevent.pkt = thispacket;  
                                 thisevent.time = getcurrenttime() + SERVER_AVG_DELAY + thisdev;
                                 activeconnections[conniter].TXq.push_back(thisevent);   
                             } 
                         }

                         remove_read_from_buf(activeconnections[conniter].sock_buf, num_to_read);
                         activeconnections[conniter].sock_buf_byte_counter -= num_to_read;
                     }
                 }    
            }
       }
   }
}

void send_to_activesockets(void)
{
    for(int conniter = 0; conniter < activeconnections.size(); conniter++) 
    {
	
        if (activeconnections[conniter].lasttxtime + SERVER_ECHO_MIN_INTERVAL < getcurrenttime())
        {
            for(int h=0; h<activeconnections[conniter].TXq.size(); h++) 
            {
		TXevent thisevent = activeconnections[conniter].TXq[h];
    	        if (thisevent.time < getcurrenttime()) 
                {
		    send_packet_to_client(activeconnections[conniter].socket, &(thisevent.pkt));
                    activeconnections[conniter].TXq.erase(activeconnections[conniter].TXq.begin()+h);
                    activeconnections[conniter].lasttxtime = getcurrenttime();
                    h--; 
                } 
            }
        }
	
        if (activeconnections[conniter].lasttxtime + SERVER_ECHO_MIN_INTERVAL < getcurrenttime()) {
            struct Packet thispkt;
            memset(thispkt.data, 0, sizeof(Packet)); 		
            char shouldcloseflag = 0;
            int thiscopysize = sizeof(Packet);
            int thisexpend = activeconnections[conniter].msgpoiter + sizeof(Packet); 
            if (thisexpend >= sizeof(msg0)) {
                thiscopysize = sizeof(msg0) - activeconnections[conniter].msgpoiter;
	        shouldcloseflag = 1;
            }
            memcpy(thispkt.data, msg0 + activeconnections[conniter].msgpoiter, thiscopysize);
	    send_packet_to_client(activeconnections[conniter].socket, &(thispkt));
            activeconnections[conniter].lasttxtime = getcurrenttime();
            activeconnections[conniter].msgpoiter +=  thiscopysize;
	    printf("sent on socket %d of %d bytes\n",activeconnections[conniter].socket, activeconnections[conniter].msgpoiter); 

	    if (shouldcloseflag) {
   	        printf("done with client on socket %d\n",activeconnections[conniter].socket); 
                close(activeconnections[conniter].socket); // bye!
                FD_CLR(activeconnections[conniter].socket, &master); // remove from master set
                activeconnections.erase(activeconnections.begin()+conniter);
                conniter --;
            }
        }
    }
}


void server_init()
{
    struct sockaddr_in myaddr;       // my address
    struct sockaddr_in remoteaddr;   // peer address

    int yes=1;                       // for setsockopt() SO_REUSEADDR, below
    socklen_t addrlen;

    FD_ZERO(&master);                // clear the master and temp sets
    FD_ZERO(&read_fds);

    // get the listener
    if ((listener = socket(PF_INET, SOCK_STREAM, 0)) == -1) 
    {
        printf("cannot create a socket");
        fflush(stdout);
        exit(1);
    }
   
    // lose the pesky "address already in use" error message
    if (setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes,sizeof(int)) == -1) 
    {
        printf("setsockopt");
        fflush(stdout);
        exit(1);
    }

    // bind to the port
    myaddr.sin_family = AF_INET;
    myaddr.sin_addr.s_addr = INADDR_ANY;
    myaddr.sin_port = htons(SERVERPORT);
    memset(&(myaddr.sin_zero), '\0', 8);
    if (bind(listener, (struct sockaddr *)&myaddr, sizeof(myaddr)) == -1) 
    {
        printf("could not bind to MYPORT");
        fflush(stdout);
        exit(1);
     }
     
     // listen
     if (listen(listener, 40) == -1) 
     {
        printf("too many backlogged connections on listen");
        fflush(stdout);
        exit(1);
     }

     // add the listener to the master set
     FD_SET(listener, &master);

     // keep track of the biggest file descriptor
     if (listener > highestsocket)
     {
          highestsocket = listener;
     }
        
     FD_SET(fileno(stdin), &master);

     if (fileno(stdin) > highestsocket)
     {
          highestsocket = fileno(stdin);
     }

     read_config("./SERVER_config_challenging");
}

void server_run()
{
     while (1)
     {
         struct timeval timeout;
         timeout.tv_sec = 0;
         timeout.tv_usec = 1000;
         read_fds = master; 
         if (select(highestsocket+1, &read_fds, NULL, NULL, &timeout) == -1) 
         {
             if (errno == EINTR)
             {
                 cout << "got the EINTR error in select" << endl;   
             }
             else
             {
                 cout << "select problem, server got errno " << errno << endl;   
                 printf("Select problem .. exiting server");
                 fflush(stdout);
                 exit(1);
             } 
         }
         read_from_activesockets();
         send_to_activesockets();
     }
}


int main(int argc, char** argv)
{
    server_init();
    server_run();
    return 0;
}

