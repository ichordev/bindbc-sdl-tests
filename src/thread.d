/*
Copyright (C) 1997-2022 Sam Lantinga <slouken@libsdl.org>

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely.
*/
//This code was copied from libsdl-org/SDL/test version 2.26.0 from GitHub and modified to compile in D.

/* Simple test of the SDL threading code */

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.signal;

import bindbc.sdl;

extern(C) @nogc nothrow:

static SDL_TLSID tls;
static int alive = 0;
static int testprio = 0;

/* Call this instead of exit(), so we can clean up SDL: atexit() is evil. */
static void 
quit(int rc)
{
	SDL_Quit();
	exit(rc);
}

static const (char) *
getprioritystr(SDL_ThreadPriority priority)
{
	switch(priority)
	{
	case SDL_THREAD_PRIORITY_LOW: return "SDL_THREAD_PRIORITY_LOW";
	case SDL_THREAD_PRIORITY_NORMAL: return "SDL_THREAD_PRIORITY_NORMAL";
	case SDL_THREAD_PRIORITY_HIGH: return "SDL_THREAD_PRIORITY_HIGH";
	case SDL_THREAD_PRIORITY_TIME_CRITICAL: return "SDL_THREAD_PRIORITY_TIME_CRITICAL";
	default: return "???";
	}
}

int
ThreadFunc(void *data)
{
	SDL_ThreadPriority prio = SDL_THREAD_PRIORITY_NORMAL;

	SDL_TLSSet(tls, "baby thread".ptr, null);
	SDL_Log("Started thread %s: My thread id is %lu, thread data = %s\n",
		cast(char *) data, SDL_ThreadID(), cast(const (char )*)SDL_TLSGet(tls));
	while (alive) {
		SDL_Log("Thread '%s' is alive!\n", cast(char *) data);

		if (testprio) {
			SDL_Log("SDL_SetThreadPriority(%s):%d\n", getprioritystr(prio), SDL_SetThreadPriority(prio));
			if (++prio > SDL_THREAD_PRIORITY_TIME_CRITICAL)
				prio = SDL_THREAD_PRIORITY_LOW;
		}

		SDL_Delay(1 * 1000);
	}
	SDL_Log("Thread '%s' exiting!\n", cast(char *) data);
	return (0);
}

static void
killed(int sig) nothrow @nogc
{
	SDL_Log("Killed with SIGTERM, waiting 5 seconds to exit\n");
	SDL_Delay(5 * 1000);
	alive = 0;
	quit(0);
}

int
main(int argc, char **argv)
{
	static if(!staticBinding) loadSDL();
	int arg = 1;
	SDL_Thread *thread;

	/* Enable standard application logging */
	SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

	/* Load the SDL library */
	if (SDL_Init(0) < 0) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n".ptr, SDL_GetError());
		return (1);
	}

	if (SDL_getenv("SDL_TESTS_QUICK") != null) {
		SDL_Log("Not running slower tests");
		SDL_Quit();
		return 0;
	}

	while (argv[arg] && *argv[arg] == '-') {
		if (SDL_strcmp(argv[arg], "--prio") == 0) {
			testprio = 1;
		}
		++arg;
	}

	tls = SDL_TLSCreate();
	assert(tls);
	SDL_TLSSet(tls, "main thread".ptr, null);
	SDL_Log("Main thread data initially: %s\n", cast(const (char) *)SDL_TLSGet(tls));

	alive = 1;
	thread = SDL_CreateThread(&ThreadFunc, "One".ptr, cast(void*)"#1".ptr);
	if (thread == null) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create thread: %s\n".ptr, SDL_GetError());
		quit(1);
	}
	SDL_Delay(5 * 1000);
	SDL_Log("Waiting for thread #1\n");
	alive = 0;
	SDL_WaitThread(thread, null);

	SDL_Log("Main thread data finally: %s\n", cast(const (char) *)SDL_TLSGet(tls));

	alive = 1;
	signal(SIGTERM, &killed);
	thread = SDL_CreateThread(&ThreadFunc, "Two".ptr, cast(void*)"#2".ptr);
	if (thread == null) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create thread: %s\n".ptr, SDL_GetError());
		quit(1);
	}
	raise(SIGTERM);

	SDL_Quit();                 /* Never reached */
	return (0);                 /* Never reached */
}
