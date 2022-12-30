/*
Copyright 1997-2022 Sam Lantinga
Copyright 2022 Collabora Ltd.

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely.
*/
//This code was copied from libsdl-org/SDL_Image/test version 2.6.0 from GitHub and modified to compile in D.

import sdltest.common;

import bindbc.sdl;

import core.stdc.stdlib;
//#include "SDL_test.h"

extern(C) @nogc nothrow:

static const (char)* pathsep = (){
	version(Windows)  return "\\";
	else              return "/";
}();

// #if defined(__APPLE__) && !defined(SDL_IMAGE_USE_COMMON_BACKEND)
// # define USING_IMAGEIO 1
// #else
// # define USING_IMAGEIO 0
// #endif

alias TestFileType = int;
enum: TestFileType{
	TEST_FILE_DIST,
	TEST_FILE_BUILT,
}

static SDL_bool
GetStringBoolean(const (char) *value, SDL_bool default_value)
{
	if (!value || !*value) {
		return default_value;
	}
	if (*value == '0' || SDL_strcasecmp(value, "false".ptr) == 0) {
		return SDL_FALSE;
	}
	return SDL_TRUE;
}

/*
* Return the absolute path to a resource file, similar to GLib's
* g_test_build_filename().
*
* If type is TEST_FILE_DIST, look for it in $SDL_TEST_SRCDIR or next
* to the executable.
*
* If type is TEST_FILE_BUILT, look for it in $SDL_TEST_BUILDDIR or next
* to the executable.
*
* Fails and returns null if out of memory.
*/
static char*
GetTestFilename(TestFileType type, const (char) *file)
{
	const (char) *env;
	char *base = null;
	char *path = null;
	SDL_bool needPathSep = SDL_TRUE;

	if (type == TEST_FILE_DIST) {
		env = SDL_getenv("SDL_TEST_SRCDIR");
	} else {
		env = SDL_getenv("SDL_TEST_BUILDDIR");
	}

	if (env !is null) {
		base = SDL_strdup(env);
		if (base is null) {
			SDL_OutOfMemory();
			return null;
		}
	}

	if (base is null) {
		base = SDL_GetBasePath();
		/* SDL_GetBasePath() guarantees a trailing path separator */
		needPathSep = SDL_FALSE;
	}

	if (base !is null) {
		size_t len = SDL_strlen(base) + SDL_strlen(pathsep) + SDL_strlen(file) + 1;

		path = cast(char*)SDL_malloc(len);

		if (path is null) {
			SDL_OutOfMemory();
			return null;
		}

		if (needPathSep) {
			SDL_snprintf(path, len, "%s%s%s".ptr, base, pathsep, file);
		} else {
			SDL_snprintf(path, len, "%s%s".ptr, base, file);
		}

		SDL_free(base);
	} else {
		path = SDL_strdup(file);
		if (path is null) {
			SDL_OutOfMemory();
			return null;
		}
	}

	return path;
}

static SDLTest_CommonState *state;

struct Format{
	const (char) *name;
	const (char) *sample;
	const (char) *reference;
	int w;
	int h;
	int tolerance;
	int initFlag;
	SDL_bool canLoad;
	SDL_bool canSave;
	extern(C) int function(SDL_RWops *src) nothrow @nogc checkFunction;
	extern(C) SDL_Surface* function(SDL_RWops *src) nothrow @nogc loadFunction;
}

Format[19] formats;

static SDL_bool
StrHasSuffix(const (char) *str, const (char) *suffix)
{
	size_t str_len = SDL_strlen(str);
	size_t suffix_len = SDL_strlen(suffix);

	return (str_len >= suffix_len
			&& SDL_strcmp(str + (str_len - suffix_len), suffix) == 0);
}

alias LoadMode = int;
enum: LoadMode{
	LOAD_CONVENIENCE = 0,
	LOAD_RW,
	LOAD_TYPED_RW,
	LOAD_FORMAT_SPECIFIC,
	LOAD_SIZED
}

/* Convert to RGBA for comparison, if necessary */
static SDL_bool
ConvertToRgba32(SDL_Surface **surface_p)
{
	if ((*surface_p).format.format != SDL_PIXELFORMAT_RGBA32) {
		SDL_Surface *temp;

		temp = SDL_ConvertSurfaceFormat(*surface_p, SDL_PIXELFORMAT_RGBA32, 0);
		if(temp is null){
			SDL_Log("Converting to RGBA should succeed (%s)", SDL_GetError());
		}
		if (temp is null) {
			return SDL_FALSE;
		}
		SDL_FreeSurface(*surface_p);
		*surface_p = temp;
	}
	return SDL_TRUE;
}

static void
DumpPixels(const (char) *filename, SDL_Surface *surface)
{
	const (char) *pixels = cast(char*)surface.pixels;
	const (char) *p;
	size_t w, h, pitch;
	size_t i, j;

	SDL_Log("%s:\n", filename);

	if (surface.format.palette) {
		size_t n = 0;

		if (surface.format.palette.ncolors >= 0) {
			n = cast(size_t) surface.format.palette.ncolors;
		}

		SDL_Log("  Palette:\n");
		for (i = 0; i < n; i++) {
			SDL_Log("    RGBA[0x%02x] = %02x%02x%02x%02x\n",
					cast(uint) i,
					surface.format.palette.colors[i].r,
					surface.format.palette.colors[i].g,
					surface.format.palette.colors[i].b,
					surface.format.palette.colors[i].a);
		}
	}

	if (surface.w < 0) {
		SDL_Log("    Invalid width %d\n", surface.w);
		return;
	}

	if (surface.h < 0) {
		SDL_Log("    Invalid height %d\n", surface.h);
		return;
	}

	if (surface.pitch < 0) {
		SDL_Log("    Invalid pitch %d\n", surface.pitch);
		return;
	}

	w = cast(size_t) surface.w;
	h = cast(size_t) surface.h;
	pitch = cast(size_t) surface.pitch;

	SDL_Log("  Pixels:\n");

	for (j = 0; j < h; j++) {
		SDL_Log("    ");

		for (i = 0; i < w; i++) {
			p = pixels + (j * pitch) + (i * surface.format.BytesPerPixel);

			switch (surface.format.BitsPerPixel) {
				case 1:
				case 4:
				case 8:
					SDL_Log("%02x ", *p);
					break;

				case 12:
				case 15:
				case 16:
					SDL_Log("%02x", *p++);
					SDL_Log("%02x ", *p);
					break;

				case 24:
					SDL_Log("%02x", *p++);
					SDL_Log("%02x", *p++);
					SDL_Log("%02x ", *p);
					break;

				case 32:
					SDL_Log("%02x", *p++);
					SDL_Log("%02x", *p++);
					SDL_Log("%02x", *p++);
					SDL_Log("%02x ", *p);
					break;
				default: assert(0);
			}
		}

		SDL_Log("\n");
	}
}

static void
FormatLoadTest(const Format *format,
			LoadMode mode)
{
	SDL_Surface *reference = null;
	SDL_Surface *surface = null;
	SDL_RWops *src = null;
	char *filename = GetTestFilename(TEST_FILE_DIST, format.sample);
	char *refFilename = GetTestFilename(TEST_FILE_DIST, format.reference);
	int initResult = 0;
	int diff;

	if (filename is null){
		SDL_Log("Building filename should succeed (%s)", SDL_GetError());
		goto out_;
	}
	if (refFilename is null){
		SDL_Log("Building ref filename should succeed (%s)", SDL_GetError());
		goto out_;
	}

	if (StrHasSuffix(format.reference, ".bmp")) {
		reference = SDL_LoadBMP(refFilename);
		if (reference is null){
			SDL_Log("Loading reference should succeed (%s)", SDL_GetError());
			goto out_;
		}
	}
	else if (StrHasSuffix (format.reference, ".png")) {
		reference = IMG_Load(refFilename);
		if (reference is null){
			SDL_Log("Loading reference should succeed (%s)", SDL_GetError());
			goto out_;
		}
	}

	if (format.initFlag) {
		initResult = IMG_Init(format.initFlag);
		if (initResult == 0){
			SDL_Log("Initialization should succeed (%s)", SDL_GetError());
			goto out_;
		}
		if(!(initResult & format.initFlag)){
			SDL_Log("Expected at least bit 0x%x set, got 0x%x", format.initFlag, initResult);
		}
	}

	if (mode != LOAD_CONVENIENCE) {
		src = SDL_RWFromFile(filename, "rb");
		if(src is null)
			SDL_Log("Opening %s should succeed (%s)", filename, SDL_GetError());
		if (src is null)
			goto out_;
	}

	switch (mode) {
		case LOAD_CONVENIENCE:
			surface = IMG_Load(filename);
			break;

		case LOAD_RW:
			if (format.checkFunction !is null) {
				SDL_RWops *ref_src;
				int check;

				ref_src = SDL_RWFromFile(refFilename, "rb");
				if(ref_src is null) SDL_Log("Opening %s should succeed (%s)", refFilename, SDL_GetError());
				if (ref_src !is null) {
					check = format.checkFunction(ref_src);
					if(check) SDL_Log("Should not detect %s as %s . %d", refFilename, format.name, check);
					SDL_RWclose(ref_src);
				}
			}

			if (format.checkFunction !is null) {
				int check = format.checkFunction(src);

				if(!check) SDL_Log("Should detect %s as %s . %d", filename, format.name, check);
			}

			surface = IMG_Load_RW(src, SDL_TRUE);
			src = null;      /* ownership taken */
			break;

		case LOAD_TYPED_RW:
			surface = IMG_LoadTyped_RW(src, SDL_TRUE, format.name);
			src = null;      /* ownership taken */
			break;

		case LOAD_FORMAT_SPECIFIC:
			surface = format.loadFunction(src);
			break;

		case LOAD_SIZED:
			if (SDL_strcmp(format.name, "SVG-sized") == 0) {
				surface = IMG_LoadSizedSVG_RW(src, 64, 64);
			}
			break;
		default: break;
	}

	if (surface is null){
		SDL_Log("Load %s (%s)", filename, SDL_GetError());
		goto out_;
	}

	if(surface.w != format.w) SDL_Log("Expected width %d px, got %d", format.w, surface.w);
	if(surface.h != format.h) SDL_Log("Expected height %d px, got %d", format.h, surface.h);

	if (GetStringBoolean(SDL_getenv("SDL_IMAGE_TEST_DEBUG"), SDL_FALSE)) {
		DumpPixels(filename, surface);
	}

	if (reference !is null) {
		ConvertToRgba32(&reference);
		ConvertToRgba32(&surface);
// 		diff = SDLTest_CompareSurfaces(surface, reference, format.tolerance);
// 		if(diff != 0) SDL_Log("Surface differed from reference by at most %d in %d pixels", format.tolerance, diff);
// 		if (diff != 0 || GetStringBoolean(SDL_getenv("SDL_IMAGE_TEST_DEBUG"), SDL_FALSE)) {
// 			DumpPixels(filename, surface);
// 			DumpPixels(refFilename, reference);
// 		}
	}

out_:
	if (surface !is null) {
		SDL_FreeSurface(surface);
	}
	if (reference !is null) {
		SDL_FreeSurface(reference);
	}
	if (src !is null) {
		SDL_RWclose(src);
	}
	if (refFilename !is null) {
		SDL_free(refFilename);
	}
	if (filename !is null) {
		SDL_free(filename);
	}
	if (initResult) {
		IMG_Quit();
	}
}

static void
FormatSaveTest(const Format *format,
			SDL_bool rw)
{
	char *refFilename = GetTestFilename(TEST_FILE_DIST, "sample.bmp");
	char[64] filename = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,];
	SDL_Surface *reference = null;
	SDL_Surface *surface = null;
	SDL_RWops *dest = null;
	int initResult = 0;
	int diff;
	int result;

	SDL_snprintf(filename.ptr, (filename).sizeof,
				"save%s.%s".ptr,
				rw ? "Rwops".ptr : "".ptr,
				format.name);

	if(refFilename is null){
		SDL_Log("Building ref filename should succeed (%s)", SDL_GetError());
		goto out_;
	}

	reference = SDL_LoadBMP(refFilename);
	if (reference is null){
		SDL_Log("Loading reference should succeed (%s)", SDL_GetError());
		goto out_;
	}

	if (format.initFlag) {
		initResult = IMG_Init(format.initFlag);
		if (initResult == 0){
			SDL_Log("Initialization should succeed (%s)",
								SDL_GetError());
			goto out_;
		}
		if(!(initResult & format.initFlag)) SDL_Log("Expected at least bit 0x%x set, got 0x%x",
							format.initFlag, initResult);
	}

	if (SDL_strcmp (format.name, "PNG".ptr) == 0) {
		if (rw) {
			dest = SDL_RWFromFile(filename.ptr, "wb".ptr);
			result = IMG_SavePNG_RW(reference, dest, SDL_FALSE);
			SDL_RWclose(dest);
		} else {
			result = IMG_SavePNG(reference, filename.ptr);
		}
	} else if (SDL_strcmp(format.name, "JPG".ptr) == 0) {
		if (rw) {
			dest = SDL_RWFromFile(filename.ptr, "wb".ptr);
			result = IMG_SaveJPG_RW(reference, dest, SDL_FALSE, 90);
			SDL_RWclose(dest);
		} else {
			result = IMG_SaveJPG(reference, filename.ptr, 90);
		}
	} else {
		SDL_Log("How do I save %s?", format.name);
		goto out_;
	}

	if(result != 0) SDL_Log("Save %s (%s)", filename.ptr, SDL_GetError());

	if (format.canLoad) {
		surface = IMG_Load(filename.ptr);

		if(surface is null){
			SDL_Log("Load %s (%s)", "saved file".ptr, SDL_GetError());
			goto out_;
		}

		ConvertToRgba32(&reference);
		ConvertToRgba32(&surface);

		if(surface.w != format.w) SDL_Log("Expected width %d px, got %d",format.w, surface.w);
		if(surface.h != format.h) SDL_Log("Expected height %d px, got %d",format.h, surface.h);

// 		diff = SDLTest_CompareSurfaces(surface, reference, format.tolerance);
// 		if(diff != 0) SDL_Log("Surface differed from reference by at most %d in %d pixels", format.tolerance, diff);
// 		if (diff != 0 || GetStringBoolean(SDL_getenv("SDL_IMAGE_TEST_DEBUG"), SDL_FALSE)) {
// 			DumpPixels(filename, surface);
// 			DumpPixels(refFilename, reference);
// 		}
	}

out_:
	if (surface !is null) {
		SDL_FreeSurface(surface);
	}
	if (reference !is null) {
		SDL_FreeSurface(reference);
	}
	if (refFilename !is null) {
		SDL_free(refFilename);
	}
	if (initResult) {
		IMG_Quit();
	}
}

static void
FormatTest(const (Format) *format)
{
	SDL_bool forced;
	char[64] envVar = [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, ];

	SDL_snprintf(envVar.ptr, (envVar).sizeof, "SDL_IMAGE_TEST_REQUIRE_LOAD_%s".ptr,
				format.name);

	forced = GetStringBoolean(SDL_getenv(envVar.ptr), SDL_FALSE);
	if (forced) {
		if(!format.canLoad) SDL_Log("%s loading should be enabled", format.name);
	}

	if (format.canLoad || forced) {
		SDL_Log("Testing ability to load format %s", format.name);

		if (SDL_strcmp(format.name, "SVG-sized".ptr) == 0) {
			FormatLoadTest(format, LOAD_SIZED);
		} else {
			FormatLoadTest(format, LOAD_CONVENIENCE);

			if (SDL_strcmp(format.name, "TGA".ptr) == 0) {
				SDL_Log("SKIP: Recognising %s by magic number is not supported", format.name);
			} else {
				FormatLoadTest(format, LOAD_RW);
			}

			FormatLoadTest(format, LOAD_TYPED_RW);

			if (format.loadFunction !is null) {
				FormatLoadTest(format, LOAD_FORMAT_SPECIFIC);
			}
		}
	} else {
		SDL_Log("Format %s is not supported", format.name);
	}

	SDL_snprintf(envVar.ptr, (envVar).sizeof, "SDL_IMAGE_TEST_REQUIRE_SAVE_%s".ptr,
				format.name);

	forced = GetStringBoolean(SDL_getenv(envVar.ptr), SDL_FALSE);
	if (forced) {
		if(!format.canSave) SDL_Log("%s saving should be enabled", format.name);
	}

	if (format.canSave || forced) {
		SDL_Log("Testing ability to save format %s", format.name);
		FormatSaveTest(format, SDL_FALSE);
		FormatSaveTest(format, SDL_TRUE);
	} else {
		SDL_Log("Saving format %s is not supported", format.name);
	}
}

static int
TestFormats(void *arg)
{
	size_t i;

	for (i = 0; i < SDL_arraysize(formats); i++) {
		FormatTest(&formats[i]);
	}

	return 1;
}

// static const SDLTest_TestCaseReference formatsTestCase = {
// 	TestFormats, "Images", "Load and save various image formats", TEST_ENABLED
// };
// 
// static const SDLTest_TestCaseReference **testCases =  {
// 	&formatsTestCase,
// 	null
// };
// static SDLTest_TestSuiteReference testSuite = {
// 	"img",
// 	null,
// 	testCases,
// 	null
// };
// static SDLTest_TestSuiteReference **testSuites =  {
// 	&testSuite,
// 	null
// };

/* Call this instead of exit(), so we can clean up SDL: atexit() is evil. */
static void
quit(int rc)
{
	SDLTest_CommonQuit(state);
	exit(rc);
}

int
main(int argc, char **argv)
{
	static if(!staticBinding){
		loadSDL();
		loadSDLImage();
	}
	formats = [
	Format(
		"AVIF",
		"sample.avif",
		"sample.bmp",
		23,
		42,
		300,
		IMG_INIT_AVIF,
		SDL_FALSE,
		SDL_FALSE,      /* can save */
		&IMG_isAVIF,
		&IMG_LoadAVIF_RW,
	), Format(
		"BMP",
		"sample.bmp",
		"sample.png",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isBMP,
		&IMG_LoadBMP_RW,
	), Format(
		"CUR",
		"sample.cur",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isCUR,
		&IMG_LoadCUR_RW,
	), Format(
		"GIF",
		"palette.gif",
		"palette.bmp",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isGIF,
		&IMG_LoadGIF_RW,
	), Format(
		"ICO",
		"sample.ico",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isICO,
		&IMG_LoadICO_RW,
	), Format(
		"JPG",
		"sample.jpg",
		"sample.bmp",
		23,
		42,
		100,
		IMG_INIT_JPG,
		SDL_TRUE,
		SDL_TRUE,
		&IMG_isJPG,
		&IMG_LoadJPG_RW,
	), Format(
		"JXL",
		"sample.jxl",
		"sample.bmp",
		23,
		42,
		300,
		IMG_INIT_JXL,
		SDL_FALSE,
		SDL_FALSE,      /* can save */
		&IMG_isJXL,
		&IMG_LoadJXL_RW,
	),// Format(
// 		"LBM",
// 		"sample.lbm",
// 		"sample.bmp",
// 		23,
// 		42,
// 		0,              /* lossless? */
// 		0,              /* no initialization */
// 		SDL_TRUE,
// 		SDL_FALSE,      /* can save */
// 		&IMG_isLBM,
// 		&IMG_LoadLBM_RW,
// 	),
	Format(
		"PCX",
		"sample.pcx",
		"sample.bmp",
		23,
		42,
		0,              /* lossless? */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isPCX,
		&IMG_LoadPCX_RW,
	), Format(
		"PNG",
		"sample.png",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		IMG_INIT_PNG,
		SDL_TRUE,
		SDL_TRUE,
		&IMG_isPNG,
		&IMG_LoadPNG_RW,
	), Format(
		"PNM",
		"sample.pnm",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isPNM,
		&IMG_LoadPNM_RW,
	), Format(
		"QOI",
		"sample.qoi",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isQOI,
		&IMG_LoadQOI_RW,
	), Format(
		"SVG",
		"svg.svg",
		"svg.bmp",
		32,
		32,
		100,
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isSVG,
		&IMG_LoadSVG_RW,
	), Format(
		"SVG-sized",
		"svg.svg",
		"svg64.bmp",
		64,
		64,
		100,
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isSVG,
		&IMG_LoadSVG_RW,
	), Format(
		"SVG-class",
		"svg-class.svg",
		"svg-class.bmp",
		82,
		82,
		0,              /* lossless? */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isSVG,
		&IMG_LoadSVG_RW,
	), Format(
		"TGA",
		"sample.tga",
		"sample.bmp",
		23,
		42,
		0,              /* lossless? */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		null,
		&IMG_LoadTGA_RW,
	), Format(
		"TIF",
		"sample.tif",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		IMG_INIT_TIF,
		SDL_FALSE,
		SDL_FALSE,      /* can save */
		&IMG_isTIF,
		&IMG_LoadTIF_RW,
	), Format(
		"WEBP",
		"sample.webp",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		IMG_INIT_WEBP,
		SDL_FALSE,
		SDL_FALSE,      /* can save */
		&IMG_isWEBP,
		&IMG_LoadWEBP_RW,
	), Format(
		"XCF",
		"sample.xcf",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isXCF,
		&IMG_LoadXCF_RW,
	), Format(
		"XPM",
		"sample.xpm",
		"sample.bmp",
		23,
		42,
		0,              /* lossless */
		0,              /* no initialization */
		SDL_TRUE,
		SDL_FALSE,      /* can save */
		&IMG_isXPM,
		&IMG_LoadXPM_RW,
	),// Format(
// 		"XV",
// 		"sample.xv",
// 		"sample.bmp",
// 		23,
// 		42,
// 		0,              /* lossless? */
// 		0,              /* no initialization */
// 		SDL_TRUE,
// 		SDL_FALSE,      /* can save */
// 		&IMG_isXV,
// 		&IMG_LoadXV_RW,
// 	),
];
	int result;
	int testIterations = 1;
	ulong userExecKey = 0;
	char *userRunSeed = null;
	char *filter = null;
	int i, done;
	SDL_Event event;

	/* Initialize test framework */
	state = SDLTest_CommonCreateState(argv, SDL_INIT_VIDEO);
	if (!state) {
		return 1;
	}

	/* Parse commandline */
	for (i = 1; i < argc;) {
		int consumed;

		consumed = SDLTest_CommonArg(state, i);
		if (consumed == 0) {
			consumed = -1;
			if (SDL_strcasecmp(argv[i], "--iterations".ptr) == 0) {
				if (argv[i + 1]) {
					testIterations = SDL_atoi(argv[i + 1]);
					if (testIterations < 1) testIterations = 1;
					consumed = 2;
				}
			}
			else if (SDL_strcasecmp(argv[i], "--execKey".ptr) == 0) {
				if (argv[i + 1]) {
					SDL_sscanf(argv[i + 1], "%".ptr, SDL_PRIu64.ptr, &userExecKey);
					consumed = 2;
				}
			}
			else if (SDL_strcasecmp(argv[i], "--seed".ptr) == 0) {
				if (argv[i + 1]) {
					userRunSeed = SDL_strdup(argv[i + 1]);
					consumed = 2;
				}
			}
			else if (SDL_strcasecmp(argv[i], "--filter".ptr) == 0) {
				if (argv[i + 1]) {
					filter = SDL_strdup(argv[i + 1]);
					consumed = 2;
				}
			}
		}
		if (consumed < 0) {

static if(SDL_VERSION_ATLEAST(2, 0, 10)){
			static const (char) **options = [ "[--iterations #]", "[--execKey #]", "[--seed string]", "[--filter suite_name|test_name]", null ];
			SDLTest_CommonLogUsage(state, argv[0], options);
}else{
			SDLTest_CommonUsage(state);
}
			quit(1);
		}

		i += consumed;
	}

	/* Initialize common state */
	if (!SDLTest_CommonInit(state)) {
		quit(2);
	}

	/* Create the windows, initialize the renderers */
	for (i = 0; i < state.num_windows; ++i) {
		SDL_Renderer *renderer = state.renderers[i];
		SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF);
		SDL_RenderClear(renderer);
	}

	/* Call Harness */
// 	result = SDLTest_RunSuites(testSuites, cast(const char *)userRunSeed, userExecKey, cast(const char *)filter, testIterations);

	/* Empty event queue */
	done = 0;
	for (i=0; i<100; i++)  {
		while (SDL_PollEvent(&event)) {
			SDLTest_CommonEvent(state, &event, &done);
		}
		SDL_Delay(10);
	}

	/* Clean up */
	SDL_free(userRunSeed);
	SDL_free(filter);

	/* Shutdown everything */
	quit(result);
	return(result);
}
