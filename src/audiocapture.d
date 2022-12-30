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
import bindbc.sdl;

import core.stdc.stdlib;

static SDL_Window *window = null;
static SDL_Renderer *renderer = null;
static SDL_AudioSpec spec;
static SDL_AudioDeviceID devid_in = 0;
static SDL_AudioDeviceID devid_out = 0;

static void
loop()
{
	SDL_bool please_quit = SDL_FALSE;
	SDL_Event e;

	while (SDL_PollEvent(&e)) {
		if (e.type == SDL_QUIT) {
			please_quit = SDL_TRUE;
		} else if (e.type == SDL_KEYDOWN) {
			if (e.key.keysym.sym == SDLK_ESCAPE) {
				please_quit = SDL_TRUE;
			}
		} else if (e.type == SDL_MOUSEBUTTONDOWN) {
			if (e.button.button == 1) {
				SDL_PauseAudioDevice(devid_out, SDL_TRUE);
				SDL_PauseAudioDevice(devid_in, SDL_FALSE);
			}
		} else if (e.type == SDL_MOUSEBUTTONUP) {
			if (e.button.button == 1) {
				SDL_PauseAudioDevice(devid_in, SDL_TRUE);
				SDL_PauseAudioDevice(devid_out, SDL_FALSE);
			}
		}
	}

	if (SDL_GetAudioDeviceStatus(devid_in) == SDL_AUDIO_PLAYING) {
		SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);
	} else {
		SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
	}
	SDL_RenderClear(renderer);
	SDL_RenderPresent(renderer);

	if (please_quit) {
		/* stop playing back, quit. */
		SDL_Log("Shutting down.\n");
		SDL_PauseAudioDevice(devid_in, 1);
		SDL_CloseAudioDevice(devid_in);
		SDL_PauseAudioDevice(devid_out, 1);
		SDL_CloseAudioDevice(devid_out);
		SDL_DestroyRenderer(renderer);
		SDL_DestroyWindow(window);
		SDL_Quit();
		exit(0);
	}

	/* Note that it would be easier to just have a one-line function that
		calls SDL_QueueAudio() as a capture device callback, but we're
		trying to test the API, so we use SDL_DequeueAudio() here. */
	while (SDL_TRUE) {
		ubyte[1024] buf;
		const uint br = SDL_DequeueAudio(devid_in, buf.ptr, (buf).sizeof);
		SDL_QueueAudio(devid_out, buf.ptr, br);
		if (br < (buf).sizeof) {
			break;
		}
	}
}

extern(C) int
main(int argc, char **argv)
{
	static if(!staticBinding) loadSDL();
	/* (argv[1] == null means "open default device.") */
	const char *devname = argv[1];
	SDL_AudioSpec wanted;
	int devcount;
	int i;

	/* Enable standard application logging */
	SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

	/* Load the SDL library */
	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n", SDL_GetError());
		return (1);
	}

	window = SDL_CreateWindow("testaudiocapture", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 320, 240, 0);
	renderer = SDL_CreateRenderer(window, -1, 0);
	SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
	SDL_RenderClear(renderer);
	SDL_RenderPresent(renderer);

	SDL_Log("Using audio driver: %s\n", SDL_GetCurrentAudioDriver());

	devcount = SDL_GetNumAudioDevices(SDL_TRUE);
	for (i = 0; i < devcount; i++) {
		SDL_Log(" Capture device #%d: '%s'\n", i, SDL_GetAudioDeviceName(i, SDL_TRUE));
	}

	SDL_zero(wanted);
	wanted.freq = 44100;
	wanted.format = AUDIO_F32SYS;
	wanted.channels = 1;
	wanted.samples = 4096;
	wanted.callback = null;

	SDL_zero(spec);

	/* DirectSound can fail in some instances if you open the same hardware
	for both capture and output and didn't open the output end first,
	according to the docs, so if you're doing something like this, always
	open your capture devices second in case you land in those bizarre
	circumstances. */

	SDL_Log("Opening default playback device...\n");
	devid_out = SDL_OpenAudioDevice(null, SDL_FALSE, &wanted, &spec, SDL_AUDIO_ALLOW_ANY_CHANGE);
	if (!devid_out) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't open an audio device for playback: %s!\n", SDL_GetError());
		SDL_Quit();
		exit(1);
	}

	SDL_Log("Opening capture device %s%s%s...\n",
			devname ? "'".ptr : "".ptr,
			devname ? devname : "[[default]]".ptr,
			devname ? "'".ptr : "".ptr);

	devid_in = SDL_OpenAudioDevice(argv[1], SDL_TRUE, &spec, &spec, 0);
	if (!devid_in) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't open an audio device for capture: %s!\n".ptr, SDL_GetError());
		SDL_Quit();
		exit(1);
	}

	SDL_Log("Ready! Hold down mouse or finger to record!\n");
	
	int x = 1;
	while (x) { loop(); SDL_Delay(16); }

	return 0;
}

