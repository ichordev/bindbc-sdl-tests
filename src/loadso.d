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

/* Test program to test dynamic loading with the loadso subsystem.
*/

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

import bindbc.sdl;

alias fntype = int function(const (char )*);

extern(C) int
main(int argc, char** argv)
{
	static if(!staticBinding) loadSDL();
	int retval = 0;
	int hello = 0;
	const (char) *libname = null;
	const (char) *symname = null;
	void *lib = null;
	fntype fn = null;

	if (argc != 3) {
		const (char) *app = argv[0];
		SDL_Log("USAGE: %s <library> <functionname>\n", app);
		SDL_Log("       %s --hello <lib with puts()>\n", app);
		return 1;
	}

	/* Initialize SDL */
	if (SDL_Init(0) < 0) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n", SDL_GetError());
		return 2;
	}

	if (SDL_strcmp(argv[1], "--hello") == 0) {
		hello = 1;
		libname = argv[2];
		symname = "puts";
	} else {
		libname = argv[1];
		symname = argv[2];
	}

	lib = SDL_LoadObject(libname);
	if (lib == null) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_LoadObject('%s') failed: %s\n",
				libname, SDL_GetError());
		retval = 3;
	} else {
		fn = cast(fntype) SDL_LoadFunction(lib, symname);
		if (fn == null) {
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_LoadFunction('%s') failed: %s\n",
					symname, SDL_GetError());
			retval = 4;
		} else {
			SDL_Log("Found %s in %s at %p\n", symname, libname, fn);
			if (hello) {
				SDL_Log("Calling function...\n");
				fflush(stdout);
				fn("     HELLO, WORLD!\n");
				SDL_Log("...apparently, we survived.  :)\n");
				SDL_Log("Unloading library...\n");
				fflush(stdout);
			}
		}
		SDL_UnloadObject(lib);
	}
	SDL_Quit();
	return retval;
}
