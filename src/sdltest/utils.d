/*
Copyright 1997-2022 Sam Lantinga
Copyright 2022 Collabora Ltd.
SPDX-License-Identifier: Zlib
*/

/*
* Return the absolute path to def in the SDL_GetBasePath() if possible, or
* the relative path to def on platforms that don't have a working
* SDL_GetBasePath(). Free the result with SDL_free.
*
* Fails and returns null if out of memory.
*/
module sdltest.utils;

public import bindbc.sdl;

extern(C) @nogc nothrow:

char *
GetNearbyFilename(const (char) *file)
{
	char *base;
	char *path;

	base = SDL_GetBasePath();

	if (base != null) {
		SDL_RWops *rw;
		size_t len = SDL_strlen(base) + SDL_strlen(file) + 1;

		path = cast(char*)SDL_malloc(len);

		if (path == null) {
			SDL_free(base);
			SDL_OutOfMemory();
			return null;
		}

		SDL_snprintf(path, len, "%s%s".ptr, base, file);
		SDL_free(base);

		rw = SDL_RWFromFile(path, "rb".ptr);
		if (rw) {
			SDL_RWclose(rw);
			return path;
		}

		/* Couldn't find the file in the base path */
		SDL_free(path);
	}

	path = SDL_strdup(file);
	if (path == null) {
		SDL_OutOfMemory();
	}
	return path;
}

/*
* If user_specified is non-null, return a copy of it. Free with SDL_free.
*
* Otherwise, return the absolute path to def in the SDL_GetBasePath() if
* possible, or the relative path to def on platforms that don't have a
* working SDL_GetBasePath(). Free the result with SDL_free.
*
* Fails and returns null if out of memory.
*/
char *
GetResourceFilename(const (char) *user_specified, const (char) *def)
{
	if (user_specified != null) {
		char *ret = SDL_strdup(user_specified);

		if (ret == null) {
			SDL_OutOfMemory();
		}

		return ret;
	} else {
		return GetNearbyFilename(def);
	}
}

/*
* Load the .bmp file whose name is file, from the SDL_GetBasePath() if
* possible or the current working directory if not.
*
* If transparent is true, set the transparent colour from the top left pixel.
*
* If width_out is non-null, set it to the texture width.
*
* If height_out is non-null, set it to the texture height.
*/
//This code was copied from libsdl-org/SDL/tests version 2.26.0 from GitHub and modified to compile in D.
SDL_Texture *
LoadTexture(SDL_Renderer *renderer, const (char) *file, SDL_bool transparent,
			int *width_out, int *height_out)
{
	SDL_Surface *temp = null;
	SDL_Texture *texture = null;
	char *path;

	path = GetNearbyFilename(file);

	if (path != null) {
		file = path;
	}

	temp = SDL_LoadBMP(file);
	if (temp == null) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't load %s: %s".ptr, file, SDL_GetError());
	} else {
		/* Set transparent pixel as the pixel at (0,0) */
		if (transparent) {
			if (temp.format.palette) {
				SDL_SetColorKey(temp, SDL_TRUE, *cast(ubyte *)temp.pixels);
			} else {
				switch (temp.format.BitsPerPixel) {
				case 15:
					SDL_SetColorKey(temp, SDL_TRUE,
									(*cast(ushort *) temp.pixels) & 0x00007FFF);
					break;
				case 16:
					SDL_SetColorKey(temp, SDL_TRUE, *cast(ushort *) temp.pixels);
					break;
				case 24:
					SDL_SetColorKey(temp, SDL_TRUE,
									(*cast(uint *) temp.pixels) & 0x00FFFFFF);
					break;
				case 32:
					SDL_SetColorKey(temp, SDL_TRUE, *cast(uint *) temp.pixels);
					break;
				default: break;
				}
			}
		}

		if (width_out != null) {
			*width_out = temp.w;
		}

		if (height_out != null) {
			*height_out = temp.h;
		}

		texture = SDL_CreateTextureFromSurface(renderer, temp);
		if (!texture) {
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create texture: %s\n".ptr, SDL_GetError());
		}
	}
	SDL_FreeSurface(temp);
	if (path) {
		SDL_free(path);
	}
	return texture;
}
