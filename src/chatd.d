/*
CHATD:  A chat server using the SDL example network library
Copyright (C) 1997-2022 Sam Lantinga <slouken@libsdl.org>

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software
	in a product, an acknowledgment in the product documentation would be
	appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
	misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/
//This code was copied from libsdl-org/SDL_net/ version 2.2.0 from GitHub and modified to compile in D.

/* Note that this isn't necessarily the way to run a chat system.
This is designed to excercise the network code more than be really
functional.
*/

import core.stdc.stdlib; //#include <stdlib.h>
import core.stdc.stdio; //#include <stdio.h>
import core.stdc.string; //#include <string.h>

import bindbc.sdl; //#include "SDL_net.h"
// #include "chat.h":

extern(C) @nogc nothrow:

/* Convert four letters into a number */
ushort MAKE_NUM(char A, char B, char C, char D){ return cast(ushort)(((A+B)<<8)|(C+D)); }

/* Defines for the chat client */
enum CHAT_SCROLLBACK  = 512;
enum CHAT_PROMPT  = "> ";
enum CHAT_PACKETSIZE  = 256;

/* Defines shared between the server and client */
immutable ushort CHAT_PORT    = MAKE_NUM('C','H','A','T');

/* The protocol between the chat client and server */
enum CHAT_HELLO   = 0;
enum CHAT_HELLO_PORT      = 1;
enum CHAT_HELLO_NLEN      = CHAT_HELLO_PORT+2;
enum CHAT_HELLO_NAME      = CHAT_HELLO_NLEN+1;
enum CHAT_ADD     = 1;
enum CHAT_ADD_SLOT        = 1;
enum CHAT_ADD_HOST        = CHAT_ADD_SLOT+1;
enum CHAT_ADD_PORT        = CHAT_ADD_HOST+4;
enum CHAT_ADD_NLEN        = CHAT_ADD_PORT+2;
enum CHAT_ADD_NAME        = CHAT_ADD_NLEN+1;
enum CHAT_DEL     = 2   /* 2+N */;
enum CHAT_DEL_SLOT        = 1;
enum CHAT_DEL_LEN         = CHAT_DEL_SLOT+1;
enum CHAT_BYE     = 255;
enum CHAT_BYE_LEN         = 1;

/* The maximum number of people who can talk at once */
enum CHAT_MAXPEOPLE   = 10;

/* This is really easy.  All we do is monitor connections */

static TCPsocket servsock = null;
static SDLNet_SocketSet socketset = null;
struct _People{
	int active;
	TCPsocket sock;
	IPaddress peer;
	ubyte[256+1] name;
}
static _People[CHAT_MAXPEOPLE] people;


void HandleServer()
{
	TCPsocket newsock;
	int which;
	char data;

	newsock = SDLNet_TCP_Accept(servsock);
	if ( newsock is null ) {
		return;
	}

	/* Look for unconnected person slot */
	for ( which=0; which<CHAT_MAXPEOPLE; ++which ) {
		if ( ! people[which].sock ) {
			break;
		}
	}
	if ( which == CHAT_MAXPEOPLE ) {
		/* Look for inactive person slot */
		for ( which=0; which<CHAT_MAXPEOPLE; ++which ) {
			if ( people[which].sock && ! people[which].active ) {
				/* Kick them out.. */
				data = CHAT_BYE;
				SDLNet_TCP_Send(people[which].sock, &data, 1);
				SDLNet_TCP_DelSocket(socketset,
						people[which].sock);
				SDLNet_TCP_Close(people[which].sock);
debug{
				SDL_Log("Killed inactive socket %d\n", which);
}
				break;
			}
		}
	}
	if ( which == CHAT_MAXPEOPLE ) {
		/* No more room... */
		data = CHAT_BYE;
		SDLNet_TCP_Send(newsock, &data, 1);
		SDLNet_TCP_Close(newsock);
debug{
		SDL_Log("Connection refused -- chat room full\n");
}
	} else {
		/* Add socket as an inactive person */
		people[which].sock = newsock;
		people[which].peer = *SDLNet_TCP_GetPeerAddress(newsock);
		SDLNet_TCP_AddSocket(socketset, people[which].sock);
debug{
		SDL_Log("New inactive socket %d\n", which);
}
	}
}

/* Send a "new client" notification */
void SendNew(int about, int to)
{
	char[512] data;
	int n;

	n = cast(int)strlen(cast(char *)people[about].name)+1;
	data[0] = CHAT_ADD;
	data[CHAT_ADD_SLOT] = cast(char)about;
	memcpy(&data[CHAT_ADD_HOST], &people[about].peer.host, 4);
	memcpy(&data[CHAT_ADD_PORT], &people[about].peer.port, 2);
	data[CHAT_ADD_NLEN] = cast(char)n;
	memcpy(&data[CHAT_ADD_NAME], people[about].name.ptr, n);
	SDLNet_TCP_Send(people[to].sock, data.ptr, CHAT_ADD_NAME+n);
}

void HandleClient(int which)
{
	char[512] data;
	int i;

	/* Has the connection been closed? */
	if ( SDLNet_TCP_Recv(people[which].sock, data.ptr, 512) <= 0 ) {
debug{
		SDL_Log("Closing socket %d (was%s active)\n",
				which, people[which].active ? "".ptr : " not".ptr);
}
		/* Notify all active clients */
		if ( people[which].active ) {
			people[which].active = 0;
			data[0] = CHAT_DEL;
			data[CHAT_DEL_SLOT] = cast(char)which;
			for ( i=0; i<CHAT_MAXPEOPLE; ++i ) {
				if ( people[i].active ) {
					SDLNet_TCP_Send(people[i].sock,data.ptr,CHAT_DEL_LEN);
				}
			}
		}
		SDLNet_TCP_DelSocket(socketset, people[which].sock);
		SDLNet_TCP_Close(people[which].sock);
		people[which].sock = null;
	} else {
		switch (data[0]) {
			case CHAT_HELLO: {
				/* Yay!  An active connection */
				memcpy(&people[which].peer.port,
						&data[CHAT_HELLO_PORT], 2);
				memcpy(people[which].name.ptr,
						&data[CHAT_HELLO_NAME], 256);
				people[which].name[256] = 0;
debug{
				SDL_Log("Activating socket %d (%s)\n",
						which, people[which].name.ptr);
}
				/* Notify all active clients */
				for ( i=0; i<CHAT_MAXPEOPLE; ++i ) {
					if ( people[i].active ) {
						SendNew(which, i);
					}
				}

				/* Notify about all active clients */
				people[which].active = 1;
				for ( i=0; i<CHAT_MAXPEOPLE; ++i ) {
					if ( people[i].active ) {
						SendNew(i, which);
					}
				}
			}
			break;
			default: {
				/* Unknown packet type?? */
			}
			break;
		}
	}
}

static void cleanup(int exitcode)
{
	if ( servsock !is null ) {
		SDLNet_TCP_Close(servsock);
		servsock = null;
	}
	if ( socketset !is null ) {
		SDLNet_FreeSocketSet(socketset);
		socketset = null;
	}
	SDLNet_Quit();
	SDL_Quit();
	exit(exitcode);
}

int main(int argc, char **argv)
{
	static if(!staticBinding){
		loadSDL();
		loadSDLNet();
	}
	IPaddress serverIP;
	int i;

	/* Initialize SDL */
	if ( SDL_Init(0) < 0 ) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"Couldn't initialize SDL: %s\n".ptr,
					SDL_GetError());
		exit(1);
	}

	/* Initialize the network */
	if ( SDLNet_Init() < 0 ) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"Couldn't initialize net: %s\n".ptr,
					SDLNet_GetError());
		SDL_Quit();
		exit(1);
	}

	/* Initialize the channels */
	for ( i=0; i<CHAT_MAXPEOPLE; ++i ) {
		people[i].active = 0;
		people[i].sock = null;
	}

	/* Allocate the socket set */
	socketset = SDLNet_AllocSocketSet(CHAT_MAXPEOPLE+1);
	if ( socketset is null ) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"Couldn't create socket set: %s\n".ptr,
					SDLNet_GetError());
		cleanup(2);
	}

	/* Create the server socket */
	SDLNet_ResolveHost(&serverIP, null, CHAT_PORT);
	SDL_Log("Server IP: %x, %d\n", serverIP.host, serverIP.port);
	servsock = SDLNet_TCP_Open(&serverIP);
	if ( servsock is null ) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"Couldn't create server socket: %s\n".ptr,
					SDLNet_GetError());
		cleanup(2);
	}
	SDLNet_TCP_AddSocket(socketset, servsock);

	/* Loop, waiting for network events */
	auto x = true;
	while(x){
		/* Wait for events */
		SDLNet_CheckSockets(socketset, ~0);

		/* Check for new connections */
		if ( SDLNet_SocketReady(servsock) ) {
			HandleServer();
		}

		/* Check for events on existing clients */
		for ( i=0; i<CHAT_MAXPEOPLE; ++i ) {
			if ( SDLNet_SocketReady(people[i].sock) ) {
				HandleClient(i);
			}
		}
	}
	cleanup(0);

	/* Not reached, but fixes compiler warnings */
	return 0;
}

