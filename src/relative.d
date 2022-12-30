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

/* Simple program:  Test relative mouse motion */

import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.time;
import sdltest.common;

static SDLTest_CommonState* state;
int i, done;
SDL_Rect rect;
SDL_Event event;

static void
DrawRects(SDL_Renderer * renderer)
{
	SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
	SDL_RenderFillRect(renderer, &rect);
}

static void
loop(){
	/* Check for events */
	while (SDL_PollEvent(&event)) {
		SDLTest_CommonEvent(state, &event, &done);
		switch(event.type) {
		case SDL_MOUSEMOTION:
			{
				rect.x += event.motion.xrel;
				rect.y += event.motion.yrel;
			}
			break;
			default: break;
		}
	}
	for (i = 0; i < state.num_windows; ++i) {
		SDL_Rect viewport;
		SDL_Renderer *renderer = state.renderers[i];
		if (state.windows[i] == null)
			continue;
		SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xFF);
		SDL_RenderClear(renderer);

		/* Wrap the cursor rectangle at the screen edges to keep it visible */
		SDL_RenderGetViewport(renderer, &viewport);
		if (rect.x < viewport.x) rect.x += viewport.w;
		if (rect.y < viewport.y) rect.y += viewport.h;
		if (rect.x > viewport.x + viewport.w) rect.x -= viewport.w;
		if (rect.y > viewport.y + viewport.h) rect.y -= viewport.h;

		DrawRects(renderer);

		SDL_RenderPresent(renderer);
	}
}

extern(C) int main(int argc, char** argv)
{
	static if(!staticBinding) loadSDL();
	/* Enable standard application logging */
	SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

	/* Initialize test framework */
	state = SDLTest_CommonCreateState(argv, SDL_INIT_VIDEO);
	if (!state) {
		return 1;
	}
	for (i = 1; i < argc; ++i) {
		SDLTest_CommonArg(state, i);
	}
	if (!SDLTest_CommonInit(state)) {
		return 2;
	}

	/* Create the windows and initialize the renderers */
	for (i = 0; i < state.num_windows; ++i) {
		SDL_Renderer *renderer = state.renderers[i];
		SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_NONE);
		SDL_SetRenderDrawColor(renderer, 0xA0, 0xA0, 0xA0, 0xFF);
		SDL_RenderClear(renderer);
	}

	srand(cast(uint)time(null));
	if(SDL_SetRelativeMouseMode(SDL_TRUE) < 0) {
		return 3;
	}

	rect.x = DEFAULT_WINDOW_WIDTH / 2;
	rect.y = DEFAULT_WINDOW_HEIGHT / 2;
	rect.w = 10;
	rect.h = 10;
	/* Main render loop */
	done = 0;
	while (!done) {
		loop();
		}
	SDLTest_CommonQuit(state);
	return 0;
}
