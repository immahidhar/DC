CC = g++
CFLAGS= -O3 
LIBS = -lpthread\

all:  server client
clean:
	rm -f *.o
	rm -f server client

common.o: common.cpp common.h 
	  $(CC) $(CFLAGS) -c common.cpp

server.o: server.cpp common.h server.h
	  $(CC) $(CFLAGS) -c server.cpp 

server:  server.o common.o 
	  $(CC) $(CFLAGS) -o server server.o common.o

client.o: client.cpp common.h client.h
	  $(CC) $(CFLAGS) -c client.cpp 

client:  client.o common.o
	  $(CC) $(CFLAGS) -o client client.o common.o  ${LIBS}

