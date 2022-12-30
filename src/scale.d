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
/* Simple program:  Move N sprites around on the screen as fast as possible */

import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.time;
import sdltest.common;
import sdltest.utils;

enum WINDOW_WIDTH  = 640;
enum WINDOW_HEIGHT = 480;

static SDLTest_CommonState *state;

struct DrawState{
	SDL_Window *window;
	SDL_Renderer *renderer;
	SDL_Texture *background;
	SDL_Texture *sprite;
	SDL_Rect sprite_rect;
	int scale_direction;
}

DrawState *drawstates;
int done;

/* Call this instead of exit(), so we can clean up SDL: atexit() is evil. */
static void
quit(int rc)
{
	SDLTest_CommonQuit(state);
	exit(rc);
}

void
Draw(DrawState *s)
{
	SDL_Rect viewport;

	SDL_RenderGetViewport(s.renderer, &viewport);

	/* Draw the background */
	SDL_RenderCopy(s.renderer, s.background, null, null);

	/* Scale and draw the sprite */
	s.sprite_rect.w += s.scale_direction;
	s.sprite_rect.h += s.scale_direction;
	if (s.scale_direction > 0) {
		if (s.sprite_rect.w >= viewport.w || s.sprite_rect.h >= viewport.h) {
			s.scale_direction = -1;
		}
	} else {
		if (s.sprite_rect.w <= 1 || s.sprite_rect.h <= 1) {
			s.scale_direction = 1;
		}
	}
	s.sprite_rect.x = (viewport.w - s.sprite_rect.w) / 2;
	s.sprite_rect.y = (viewport.h - s.sprite_rect.h) / 2;

	SDL_RenderCopy(s.renderer, s.sprite, null, &s.sprite_rect);

	/* Update the screen! */
	SDL_RenderPresent(s.renderer);
}

void
loop()
{
	int i;
	SDL_Event event;

	/* Check for events */
	while (SDL_PollEvent(&event)) {
		SDLTest_CommonEvent(state, &event, &done);
	}
	for (i = 0; i < state.num_windows; ++i) {
		if (state.windows[i] == null)
			continue;
		Draw(&drawstates[i]);
	}
}

extern(C) int
main(int argc, char** argv)
{
	static if(!staticBinding) loadSDL();
	int i;
	int frames;
	uint then, now;

	/* Enable standard application logging */
	SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

	/* Initialize test framework */
	state = SDLTest_CommonCreateState(argv, SDL_INIT_VIDEO);
	if (!state) {
		return 1;
	}

	if (!SDLTest_CommonDefaultArgs(state, argc, argv) || !SDLTest_CommonInit(state)) {
		SDLTest_CommonQuit(state);
		return 1;
	}

	drawstates = SDL_stack_alloc!DrawState(state.num_windows);
	for (i = 0; i < state.num_windows; ++i) {
		DrawState *drawstate = &drawstates[i];

		drawstate.window = state.windows[i];
		drawstate.renderer = state.renderers[i];
		drawstate.sprite = LoadTexture(drawstate.renderer, "res/icon.bmp", SDL_TRUE, null, null);
		drawstate.background = LoadTexture(drawstate.renderer, "res/sample.bmp", SDL_FALSE, null, null);
		if (!drawstate.sprite || !drawstate.background) {
			quit(2);
		}
		SDL_QueryTexture(drawstate.sprite, null, null,
						&drawstate.sprite_rect.w, &drawstate.sprite_rect.h);
		drawstate.scale_direction = 1;
	}

	/* Main render loop */
	frames = 0;
	then = SDL_GetTicks();
	done = 0;


	while (!done) {
		++frames;
		loop();
	}

	/* Print out some timing information */
	now = SDL_GetTicks();
	if (now > then) {
		double fps = (cast(double) frames * 1000) / (now - then);
		SDL_Log("%2.2f frames per second\n", fps);
	}

	SDL_stack_free(drawstates);

	quit(0);
	return 0;
}
