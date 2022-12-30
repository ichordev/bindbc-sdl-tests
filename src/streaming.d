/*
  Copyright (C) 1997-2022 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely.
*/
/********************************************************************************
 *                                                                              *
 * Running moose :) Coded by Mike Gorchak.                                      *
 *                                                                              *
 ********************************************************************************/
//This code was copied from libsdl-org/SDL/test version 2.26.0 from GitHub and modified to compile in D.

import core.stdc.stdlib;
import core.stdc.stdio;

import bindbc.sdl;
import sdltest.utils;

enum MOOSEPIC_W  = 64;
enum MOOSEPIC_H  = 88;

enum MOOSEFRAME_SIZE  = (MOOSEPIC_W * MOOSEPIC_H);
enum MOOSEFRAMES_COUNT  = 10;

SDL_Color[84] MooseColors = [
    {49, 49, 49, 255}, {66, 24, 0, 255}, {66, 33, 0, 255}, {66, 66, 66, 255},
    {66, 115, 49, 255}, {74, 33, 0, 255}, {74, 41, 16, 255}, {82, 33, 8, 255},
    {82, 41, 8, 255}, {82, 49, 16, 255}, {82, 82, 82, 255}, {90, 41, 8, 255},
    {90, 41, 16, 255}, {90, 57, 24, 255}, {99, 49, 16, 255}, {99, 66, 24, 255},
    {99, 66, 33, 255}, {99, 74, 33, 255}, {107, 57, 24, 255}, {107, 82, 41, 255},
    {115, 57, 33, 255}, {115, 66, 33, 255}, {115, 66, 41, 255}, {115, 74, 0, 255},
    {115, 90, 49, 255}, {115, 115, 115, 255}, {123, 82, 0, 255}, {123, 99, 57, 255},
    {132, 66, 41, 255}, {132, 74, 41, 255}, {132, 90, 8, 255}, {132, 99, 33, 255},
    {132, 99, 66, 255}, {132, 107, 66, 255}, {140, 74, 49, 255}, {140, 99, 16, 255},
    {140, 107, 74, 255}, {140, 115, 74, 255}, {148, 107, 24, 255}, {148, 115, 82, 255},
    {148, 123, 74, 255}, {148, 123, 90, 255}, {156, 115, 33, 255}, {156, 115, 90, 255},
    {156, 123, 82, 255}, {156, 132, 82, 255}, {156, 132, 99, 255}, {156, 156, 156, 255},
    {165, 123, 49, 255}, {165, 123, 90, 255}, {165, 132, 82, 255}, {165, 132, 90, 255},
    {165, 132, 99, 255}, {165, 140, 90, 255}, {173, 132, 57, 255}, {173, 132, 99, 255},
    {173, 140, 107, 255}, {173, 140, 115, 255}, {173, 148, 99, 255}, {173, 173, 173, 255},
    {181, 140, 74, 255}, {181, 148, 115, 255}, {181, 148, 123, 255}, {181, 156, 107, 255},
    {189, 148, 123, 255}, {189, 156, 82, 255}, {189, 156, 123, 255}, {189, 156, 132, 255},
    {189, 189, 189, 255}, {198, 156, 123, 255}, {198, 165, 132, 255}, {206, 165, 99, 255},
    {206, 165, 132, 255}, {206, 173, 140, 255}, {206, 206, 206, 255}, {214, 173, 115, 255},
    {214, 173, 140, 255}, {222, 181, 148, 255}, {222, 189, 132, 255}, {222, 189, 156, 255},
    {222, 222, 222, 255}, {231, 198, 165, 255}, {231, 231, 231, 255}, {239, 206, 173, 255}
];

ubyte[MOOSEFRAMES_COUNT][MOOSEFRAME_SIZE] MooseFrames;

SDL_Renderer *renderer;
int frame;
SDL_Texture *MooseTexture;
SDL_bool done = SDL_FALSE;

void quit(int rc)
{
    SDL_Quit();
    exit(rc);
}

void UpdateTexture(SDL_Texture *texture)
{
    SDL_Color *color;
    ubyte *src;
    uint *dst;
    int row, col;
    void *pixels;
    int pitch;

    if (SDL_LockTexture(texture, null, &pixels, &pitch) < 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't lock texture: %s\n".ptr, SDL_GetError());
        quit(5);
    }
    src = cast(ubyte*)MooseFrames[frame];
    for (row = 0; row < MOOSEPIC_H; ++row) {
        dst = cast(uint*)(cast(ubyte*)pixels + row * pitch);
        for (col = 0; col < MOOSEPIC_W; ++col) {
            color = &MooseColors[*src++];
            *dst++ = (0xFF000000|(color.r<<16)|(color.g<<8)|color.b);
        }
    }
    SDL_UnlockTexture(texture);
}

void
loop()
{
    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_KEYDOWN:
            if (event.key.keysym.sym == SDLK_ESCAPE) {
                done = SDL_TRUE;
            }
            break;
        case SDL_QUIT:
            done = SDL_TRUE;
            break;
        default: break;
        }
    }

    frame = (frame + 1) % MOOSEFRAMES_COUNT;
    UpdateTexture(MooseTexture);

    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, MooseTexture, null, null);
    SDL_RenderPresent(renderer);

}

extern(C) int
main(int argc, char **argv)
{
	static if(!staticBinding) loadSDL();
    SDL_Window *window;
    SDL_RWops *handle;
    char *filename = null;

    /* Enable standard application logging */
    SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n".ptr, SDL_GetError());
        return 1;
    }

    /* load the moose images */
    filename = GetResourceFilename(null, "res/moose.dat".ptr);
    if (filename == null) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Out of memory\n".ptr);
        return -1;
    }
    handle = SDL_RWFromFile(filename, "rb".ptr);
    SDL_free(filename);
    if (handle == null) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Can't find the file moose.dat !\n".ptr);
        quit(2);
    }
    SDL_RWread(handle, cast(ubyte**)MooseFrames, MOOSEFRAME_SIZE, MOOSEFRAMES_COUNT);
    SDL_RWclose(handle);


    /* Create the window and renderer */
    window = SDL_CreateWindow("Happy Moose",
                              SDL_WINDOWPOS_UNDEFINED,
                              SDL_WINDOWPOS_UNDEFINED,
                              MOOSEPIC_W*4, MOOSEPIC_H*4,
                              SDL_WINDOW_RESIZABLE);
    if (!window) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't set create window: %s\n".ptr, SDL_GetError());
        quit(3);
    }

    renderer = SDL_CreateRenderer(window, -1, 0);
    if (!renderer) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't set create renderer: %s\n".ptr, SDL_GetError());
        quit(4);
    }

    MooseTexture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, MOOSEPIC_W, MOOSEPIC_H);
    if (!MooseTexture) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't set create texture: %s\n".ptr, SDL_GetError());
        quit(5);
    }

    /* Loop, waiting for QUIT or the escape key */
    frame = 0;

    while (!done) {
        loop();
        }

    SDL_DestroyRenderer(renderer);

    quit(0);
    return 0;
}

/* vi: set ts=4 sw=4 expandtab: */
