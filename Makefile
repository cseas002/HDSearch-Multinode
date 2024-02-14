all: server

clean: rm client client_both server server2

server: server.c
	gcc server.c -o server

