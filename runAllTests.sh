echo \# bin/customcursor
bin/customcursor
echo \# bin/customcursorBC
bin/customcursorBC
echo \# bin/customcursorS
bin/customcursorS
echo \# bin/customcursorSBC
bin/customcursorSBC
echo \# bin/thread
bin/thread
echo \# bin/threadBC
bin/threadBC
echo \# bin/threadS
bin/threadS
echo \# bin/threadSBC
bin/threadSBC
echo \# bin/mouse
bin/mouse
echo \# bin/mouseBC
bin/mouseBC
echo \# bin/mouseS
bin/mouseS
echo \# bin/mouseSBC
bin/mouseSBC
echo \# bin/timer
bin/timer
echo \# bin/timerBC
bin/timerBC
echo \# bin/timerS
bin/timerS
echo \# bin/timerSBC
bin/timerSBC
echo \# bin/bounds
bin/bounds
echo \# bin/boundsBC
bin/boundsBC
echo \# bin/boundsS
bin/boundsS
echo \# bin/boundsSBC
bin/boundsSBC
echo \# bin/dropfile
bin/dropfile
echo \# bin/dropfileBC
bin/dropfileBC
echo \# bin/dropfileS
bin/dropfileS
echo \# bin/dropfileSBC
bin/dropfileSBC
echo \# bin/draw2
bin/draw2
echo \# bin/draw2BC
bin/draw2BC
echo \# bin/draw2S
bin/draw2S
echo \# bin/draw2SBC
bin/draw2SBC
echo \# bin/relative
bin/relative
echo \# bin/relativeBC
bin/relativeBC
echo \# bin/relativeS
bin/relativeS
echo \# bin/relativeSBC
bin/relativeSBC
echo \# bin/streaming
bin/streaming
echo \# bin/streamingBC
bin/streamingBC
echo \# bin/streamingS
bin/streamingS
echo \# bin/streamingSBC
bin/streamingSBC
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/showfont -solid /System/Library/Fonts/Monaco.ttf
	bin/showfont -solid /System/Library/Fonts/Monaco.ttf
	echo \# bin/showfont -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
	bin/showfont -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
else
	echo \# bin/showfont -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	bin/showfont -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	echo \# bin/showfont -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
	bin/showfont -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/showfontBC -solid /System/Library/Fonts/Monaco.ttf
	bin/showfontBC -solid /System/Library/Fonts/Monaco.ttf
	echo \# bin/showfontBC -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
	bin/showfontBC -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
else
	echo \# bin/showfontBC -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	bin/showfontBC -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	echo \# bin/showfontBC -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
	bin/showfontBC -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/showfontS -solid /System/Library/Fonts/Monaco.ttf
	bin/showfontS -solid /System/Library/Fonts/Monaco.ttf
	echo \# bin/showfontS -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
	bin/showfontS -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
else
	echo \# bin/showfontS -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	bin/showfontS -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	echo \# bin/showfontS -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
	bin/showfontS -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/showfontSBC -solid /System/Library/Fonts/Monaco.ttf
	bin/showfontSBC -solid /System/Library/Fonts/Monaco.ttf
	echo \# bin/showfontSBC -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
	bin/showfontSBC -shaded -outline 2 -fgcol 255,0,255,255 /System/Library/Fonts/NewYork.ttf
else
	echo \# bin/showfontSBC -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	bin/showfontSBC -solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf
	echo \# bin/showfontSBC -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
	bin/showfontSBC -shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
fi
echo \# bin/scale
bin/scale
echo \# bin/scaleBC
bin/scaleBC
echo \# bin/scaleS
bin/scaleS
echo \# bin/scaleSBC
bin/scaleSBC
echo \# bin/drawchessboard
bin/drawchessboard
echo \# bin/drawchessboardBC
bin/drawchessboardBC
echo \# bin/drawchessboardS
bin/drawchessboardS
echo \# bin/drawchessboardSBC
bin/drawchessboardSBC
echo \# bin/locale
bin/locale
echo \# bin/localeBC
bin/localeBC
echo \# bin/localeS
bin/localeS
echo \# bin/localeSBC
bin/localeSBC
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/loadso /opt/homebrew/lib/libSDL2.dylib SDL_Init
	bin/loadso /opt/homebrew/lib/libSDL2.dylib SDL_Init
else
	echo \# bin/loadso /usr/local/lib/libSDL2.so SDL_Init
	bin/loadso /usr/local/lib/libSDL2.so SDL_Init
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/loadsoBC /opt/homebrew/lib/libSDL2.dylib SDL_Init
	bin/loadsoBC /opt/homebrew/lib/libSDL2.dylib SDL_Init
else
	echo \# bin/loadsoBC /usr/local/lib/libSDL2.so SDL_Init
	bin/loadsoBC /usr/local/lib/libSDL2.so SDL_Init
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/loadsoS /opt/homebrew/lib/libSDL2.dylib SDL_Init
	bin/loadsoS /opt/homebrew/lib/libSDL2.dylib SDL_Init
else
	echo \# bin/loadsoS /usr/local/lib/libSDL2.so SDL_Init
	bin/loadsoS /usr/local/lib/libSDL2.so SDL_Init
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo \# bin/loadsoSBC /opt/homebrew/lib/libSDL2.dylib SDL_Init
	bin/loadsoSBC /opt/homebrew/lib/libSDL2.dylib SDL_Init
else
	echo \# bin/loadsoSBC /usr/local/lib/libSDL2.so SDL_Init
	bin/loadsoSBC /usr/local/lib/libSDL2.so SDL_Init
fi
echo \# bin/viewport
bin/viewport
echo \# bin/viewportBC
bin/viewportBC
echo \# bin/viewportS
bin/viewportS
echo \# bin/viewportSBC
bin/viewportSBC
echo \# bin/shape res/shapes/p11_shape32alpha.bmp
bin/shape res/shapes/p11_shape32alpha.bmp
echo \# bin/shape res/shapes/p08_shape32alpha.bmp
bin/shape res/shapes/p08_shape32alpha.bmp
echo \# bin/shapeBC res/shapes/p11_shape32alpha.bmp
bin/shapeBC res/shapes/p11_shape32alpha.bmp
echo \# bin/shapeBC res/shapes/p08_shape32alpha.bmp
bin/shapeBC res/shapes/p08_shape32alpha.bmp
echo \# bin/shapeS res/shapes/p11_shape32alpha.bmp
bin/shapeS res/shapes/p11_shape32alpha.bmp
echo \# bin/shapeS res/shapes/p08_shape32alpha.bmp
bin/shapeS res/shapes/p08_shape32alpha.bmp
echo \# bin/shapeSBC res/shapes/p11_shape32alpha.bmp
bin/shapeSBC res/shapes/p11_shape32alpha.bmp
echo \# bin/shapeSBC res/shapes/p08_shape32alpha.bmp
bin/shapeSBC res/shapes/p08_shape32alpha.bmp
echo \# bin/audiocapture
bin/audiocapture
echo \# bin/audiocaptureBC
bin/audiocaptureBC
echo \# bin/audiocaptureS
bin/audiocaptureS
echo \# bin/audiocaptureSBC
bin/audiocaptureSBC
echo \# bin/message
bin/message
echo \# bin/messageBC
bin/messageBC
echo \# bin/messageS
bin/messageS
echo \# bin/messageSBC
bin/messageSBC
