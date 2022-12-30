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

import core.stdc.stdlib;
import core.stdc.stdio;

import sdltest.common;

extern(C) @nogc nothrow:

/* Stolen from the mailing list */
/* Creates a new mouse cursor from an XPM */


/* XPM */
static const (char) **arrow = [
	/* width height num_colors chars_per_pixel */
	"    32    32        3            1",
	/* colors */
	"X c #000000",
	". c #ffffff",
	"  c None",
	/* pixels */
	"X                               ",
	"XX                              ",
	"X.X                             ",
	"X..X                            ",
	"X...X                           ",
	"X....X                          ",
	"X.....X                         ",
	"X......X                        ",
	"X.......X                       ",
	"X........X                      ",
	"X.....XXXXX                     ",
	"X..X..X                         ",
	"X.X X..X                        ",
	"XX  X..X                        ",
	"X    X..X                       ",
	"     X..X                       ",
	"      X..X                      ",
	"      X..X                      ",
	"       XX                       ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"                                ",
	"0,0"
];

static SDL_Cursor*
init_color_cursor(const (char) *file)
{
	SDL_Cursor *cursor = null;
	SDL_Surface *surface = SDL_LoadBMP(file);
	if (surface) {
		if (surface.format.palette) {
			SDL_SetColorKey(surface, 1, *cast(ubyte *) surface.pixels);
		} else {
			switch (surface.format.BitsPerPixel) {
			case 15:
				SDL_SetColorKey(surface, 1, (*cast(ushort *)surface.pixels) & 0x00007FFF);
				break;
			case 16:
				SDL_SetColorKey(surface, 1, *cast(ushort *)surface.pixels);
				break;
			case 24:
				SDL_SetColorKey(surface, 1, (*cast(uint *)surface.pixels) & 0x00FFFFFF);
				break;
			case 32:
				SDL_SetColorKey(surface, 1, *cast(uint *)surface.pixels);
				break;
			default: break;
			}
		}
		cursor = SDL_CreateColorCursor(surface, 0, 0);
		SDL_FreeSurface(surface);
	}
	return cursor;
}

static SDL_Cursor*
init_system_cursor(const (char) **image)
{
int i, row, col;
ubyte [4*32]data;
ubyte [4*32]mask;
int hot_x, hot_y;

i = -1;
for (row=0; row<32; ++row) {
	for (col=0; col<32; ++col) {
	if (col % 8) {
		data[i] <<= 1;
		mask[i] <<= 1;
	} else {
		++i;
		data[i] = mask[i] = 0;
	}
	switch (image[4+row][col]) {
		case 'X':
		data[i] |= 0x01;
		mask[i] |= 0x01;
		break;
		case '.':
		mask[i] |= 0x01;
		break;
		case ' ':
		break;
		default: break;
	}
	}
}
SDL_sscanf(image[4+row], "%d,%d", &hot_x, &hot_y);
return SDL_CreateCursor(data.ptr, mask.ptr, 32, 32, hot_x, hot_y);
}

static SDLTest_CommonState *state;
int done;
static SDL_Cursor *[1+SDL_NUM_SYSTEM_CURSORS] cursors;
static int current_cursor;
static int show_cursor;

/* Call this instead of exit(), so we can clean up SDL: atexit() is evil. */
static void
quit(int rc)
{
	SDLTest_CommonQuit(state);
	exit(rc);
}

void
loop()
{
	int i;
	SDL_Event event;
	/* Check for events */
	while (SDL_PollEvent(&event)) {
		SDLTest_CommonEvent(state, &event, &done);
		if (event.type == SDL_MOUSEBUTTONDOWN) {
			if (event.button.button == SDL_BUTTON_LEFT) {
				++current_cursor;
				if (current_cursor == SDL_arraysize(cursors)) {
					current_cursor = 0;
				}
				SDL_SetCursor(cursors[current_cursor]);
			} else {
				show_cursor = !show_cursor;
				SDL_ShowCursor(show_cursor);
			}
		}
	}
	
	for (i = 0; i < state.num_windows; ++i) {
		SDL_Renderer *renderer = state.renderers[i];
		SDL_RenderClear(renderer);
		SDL_RenderPresent(renderer);
	}
}

int
main(int argc, char **argv)
{
	static if(!staticBinding) loadSDL();
	int i;
	const (char) *color_cursor = null;

	/* Enable standard application logging */
	SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

	/* Initialize test framework */
	state = SDLTest_CommonCreateState(argv, SDL_INIT_VIDEO);
	if (!state) {
		return 1;
	}
	for (i = 1; i < argc;) {
		int consumed;

		consumed = SDLTest_CommonArg(state, i);
		if (consumed == 0) {
			color_cursor = argv[i];
			break;
		}
		if (consumed < 0) {
			SDLTest_CommonLogUsage(state, argv[0], null);
			quit(1);
		}
		i += consumed;
	}

	if (!SDLTest_CommonInit(state)) {
		quit(2);
	}

	for (i = 0; i < state.num_windows; ++i) {
		SDL_Renderer *renderer = state.renderers[i];
		SDL_SetRenderDrawColor(renderer, 0xA0, 0xA0, 0xA0, 0xFF);
		SDL_RenderClear(renderer);
	}

	if (color_cursor) {
		cursors[0] = init_color_cursor(color_cursor);
	} else {
		cursors[0] = init_system_cursor(arrow);
	}
	if (!cursors[0]) {
		SDL_Log("Error, couldn't create cursor\n");
		quit(2);
	}
	for (i = 0; i < SDL_NUM_SYSTEM_CURSORS; ++i) {
		cursors[1+i] = SDL_CreateSystemCursor(cast(SDL_SystemCursor)i);
		if (!cursors[1+i]) {
			SDL_Log("Error, couldn't create system cursor %d\n", i);
			quit(2);
		}
	}
	SDL_SetCursor(cursors[0]);

	/* Main render loop */
	done = 0;
	while (!done) {
		loop();
	}

	for (i = 0; i < SDL_arraysize(cursors); ++i) {
		SDL_FreeCursor(cursors[i]);
	}
	quit(0);

	/* keep the compiler happy ... */
	return(0);
}

/* vi: set ts=4 sw=4 expandtab: */
