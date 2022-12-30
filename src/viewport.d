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
/* Simple program:  Check viewports */

import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.time;

//#include "SDL_test.h"
import sdltest.common;
import sdltest.utils;

extern(C) @nogc nothrow:

static SDLTest_CommonState *state;

static SDL_Rect viewport;
static int done, j;
static SDL_bool use_target = SDL_FALSE;
static SDL_Texture *sprite;
static int sprite_w, sprite_h;

/* Call this instead of exit(), so we can clean up SDL: atexit() is evil. */
static void
quit(int rc)
{
	SDLTest_CommonQuit(state);
	exit(rc);
}

void
DrawOnViewport(SDL_Renderer * renderer)
{    
	SDL_Rect rect;

	/* Set the viewport */
	SDL_RenderSetViewport(renderer, &viewport);
	
	/* Draw a gray background */
	SDL_SetRenderDrawColor(renderer, 0x80, 0x80, 0x80, 0xFF);
	SDL_RenderClear(renderer);

	/* Test inside points */
	SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0x00, 0xFF);
	SDL_RenderDrawPoint(renderer, viewport.h/2 + 20, viewport.w/2);
	SDL_RenderDrawPoint(renderer, viewport.h/2 - 20, viewport.w/2);
	SDL_RenderDrawPoint(renderer, viewport.h/2     , viewport.w/2 - 20);
	SDL_RenderDrawPoint(renderer, viewport.h/2     , viewport.w/2 + 20);

	/* Test horizontal and vertical lines */
	SDL_SetRenderDrawColor(renderer, 0x00, 0xFF, 0x00, 0xFF);
	SDL_RenderDrawLine(renderer, 1, 0, viewport.w-2, 0);
	SDL_RenderDrawLine(renderer, 1, viewport.h-1, viewport.w-2, viewport.h-1);
	SDL_RenderDrawLine(renderer, 0, 1, 0, viewport.h-2);
	SDL_RenderDrawLine(renderer, viewport.w-1, 1, viewport.w-1, viewport.h-2);

	/* Test diagonal lines */
	SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0xFF, 0xFF);
	SDL_RenderDrawLine(renderer, 0, 0, viewport.w-1, viewport.h-1);
	SDL_RenderDrawLine(renderer, viewport.w-1, 0, 0, viewport.h-1);                      

	/* Test outside points */
	SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0x00, 0xFF);
	SDL_RenderDrawPoint(renderer, viewport.h/2 + viewport.h, viewport.w/2);
	SDL_RenderDrawPoint(renderer, viewport.h/2 - viewport.h, viewport.w/2);
	SDL_RenderDrawPoint(renderer, viewport.h/2, viewport.w/2 - viewport.w);
	SDL_RenderDrawPoint(renderer, viewport.h/2, viewport.w/2 + viewport.w);

	/* Add a box at the top */
	rect.w = 8;
	rect.h = 8;
	rect.x = (viewport.w - rect.w) / 2;
	rect.y = 0;
	SDL_RenderFillRect(renderer, &rect);

	/* Add a clip rect and fill it with the sprite */
	SDL_QueryTexture(sprite, null, null, &rect.w, &rect.h);
	rect.x = (viewport.w - rect.w) / 2;
	rect.y = (viewport.h - rect.h) / 2;
	SDL_RenderSetClipRect(renderer, &rect);
	SDL_RenderCopy(renderer, sprite, null, &rect);
	SDL_RenderSetClipRect(renderer, null);
}

void
loop()
{
	SDL_Event event;
	int i;
	/* Check for events */
	while (SDL_PollEvent(&event)) {
		SDLTest_CommonEvent(state, &event, &done);
	}

	/* Move a viewport box in steps around the screen */
	viewport.x = j * 100;
	viewport.y = viewport.x;
	viewport.w = 100 + j * 50;
	viewport.h = 100 + j * 50;
	j = (j + 1) % 4;
	SDL_Log("Current Viewport x=%i y=%i w=%i h=%i", viewport.x, viewport.y, viewport.w, viewport.h);

	for (i = 0; i < state.num_windows; ++i) {
		if (state.windows[i] == null)
			continue;

		/* Draw using viewport */
		DrawOnViewport(state.renderers[i]);

		/* Update the screen! */
		if (use_target) {
			SDL_SetRenderTarget(state.renderers[i], null);
			SDL_RenderCopy(state.renderers[i], state.targets[i], null, null);
			SDL_RenderPresent(state.renderers[i]);
			SDL_SetRenderTarget(state.renderers[i], state.targets[i]);
		} else {
			SDL_RenderPresent(state.renderers[i]);
		}
	}
}

int
main(int argc, char **argv)
{
	static if(!staticBinding) loadSDL();
	int i;
	uint then, now, frames;

	/* Initialize test framework */
	state = SDLTest_CommonCreateState(argv, SDL_INIT_VIDEO);
	if (!state) {
		return 1;
	}


	for (i = 1; i < argc;) {
		int consumed;

		consumed = SDLTest_CommonArg(state, i);
		if (consumed == 0) {
			consumed = -1;
			if (SDL_strcasecmp(argv[i], "--target") == 0) {
				use_target = SDL_TRUE;
				consumed = 1;
			}
		}
		if (consumed < 0) {
			static const(char)**options = [ "[--target]", null ];
			SDLTest_CommonLogUsage(state, argv[0], options);
			quit(1);
		}
		i += consumed;
	}
	if (!SDLTest_CommonInit(state)) {
		quit(2);
	}

	sprite = LoadTexture(state.renderers[0], "res/icon.bmp", SDL_TRUE, &sprite_w, &sprite_h);

	if (sprite == null) {
		quit(2);
	}

	if (use_target) {
		int w, h;

		for (i = 0; i < state.num_windows; ++i) {
			SDL_GetWindowSize(state.windows[i], &w, &h);
			state.targets[i] = SDL_CreateTexture(state.renderers[i], SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, w, h);
			SDL_SetRenderTarget(state.renderers[i], state.targets[i]);
		}
	}

	for (i = 0; i < state.num_windows; ++i) {
		SDL_Renderer *renderer = state.renderers[i];
		SDL_SetRenderDrawColor(renderer, 0xA0, 0xA0, 0xA0, 0xFF);
		SDL_RenderClear(renderer);
	}

	/* Main render loop */
	frames = 0;
	then = SDL_GetTicks();
	done = 0;
	j = 0;

	while (!done) {
		++frames;
		loop();
		SDL_Delay(1000);
	}

	/* Print out some timing information */
	now = SDL_GetTicks();
	if (now > then) {
		double fps = (cast(double) frames * 1000) / (now - then);
		SDL_Log("%2.2f frames per second\n", fps);
	}
	quit(0);
	return 0;
}

/* vi: set ts=4 sw=4 expandtab: */
