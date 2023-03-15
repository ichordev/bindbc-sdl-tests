import json
import os

configs = []
names = []
for name in os.listdir('src/'):
	if name.endswith('.d'):
		names.append(name)

for name in names:
	name = name[:-2]
	cname = name
	configs.append({
		'name': cname,
		'targetName': cname,
		'mainSourceFile': f'src/{name}.d',
		'subConfigurations': {'bindbc-sdl': 'dynamic'},
	})
	cname = f'{name}BC'
	configs.append({
		'name': cname,
		'targetName': cname,
		'mainSourceFile': f'src/{name}.d',
		'subConfigurations': {'bindbc-sdl': 'dynamicBC'},
		'buildOptions': ['betterC'],
	})
	cname = f'{name}S'
	configs.append({
		'name': cname,
		'targetName': cname,
		'mainSourceFile': f'src/{name}.d',
		'subConfigurations': {'bindbc-sdl': 'static'},
	})
	cname = f'{name}SBC'
	configs.append({
		'name': cname,
		'targetName': cname,
		'mainSourceFile': f'src/{name}.d',
		'subConfigurations': {'bindbc-sdl': 'staticBC'},
		'buildOptions': ['betterC'],
	})

print(json.dumps(configs))

with open('buildAllTests.sh', 'w') as f:
	for config in configs:
		f.write(f'dub build --config={config["name"]} $1\n')

TEST_PARAMS_LISTS = {
	'shape': ['res/shapes/p11_shape32alpha.bmp', 'res/shapes/p08_shape32alpha.bmp'],
	'loadso': ['/usr/local/lib/libSDL2.so SDL_Init'],
	'showfont': ['-solid /usr/share/fonts/truetype/hack/Hack-Bold.ttf', '-shaded -outline 2 -fgcol 255,0,255,255 /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf'],
}
TEST_IGNORE_LIST = ['chat','chatd','playmus']

with open('runAllTests.sh', 'w') as f:
	for config in configs:
		key = config['mainSourceFile'][4:-2]
		if key in TEST_IGNORE_LIST:
			continue
		elif key in TEST_PARAMS_LISTS:
			for params in TEST_PARAMS_LISTS[key]:
				out = f'bin/{config["targetName"]} {params}\n'
				f.write(f'echo \\# {out}')
				f.write(out)
		else:
			out = f'bin/{config["targetName"]}\n'
			f.write(f'echo \\# {out}')
			f.write(out)
