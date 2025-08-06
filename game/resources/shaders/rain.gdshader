shader_type canvas_item;

//FNF RAIN PORT V2 BY MAE :p
//ADDED MORE SHIT
//rate 5 stars and subscribe and leave a like for more
//dont forget to buy my youtooz

group_uniforms general;
uniform bool calculate_rain = true;
 //i also use this as just a lightmap shader, ion wanna do all ts sometimes
uniform bool use_lightmap = false;
uniform bool use_screen = false;
uniform bool warp_screen = false;
uniform sampler2D LIGHTMAP: filter_linear;

group_uniforms Rain_Settings;
uniform float direction : hint_range(-0.8,0.8,0.1) = 0.2;
uniform float Scale = 2;
uniform float Intensity = 0.1;
uniform float speed = 1.0;
uniform sampler2D Screen: hint_screen_texture;
uniform vec3 RainColor: source_color = vec3(1,1,1);

uniform float warp_amount = 0.1;

float rand(vec2 a) {
	return fract(sin(dot(mod(a, vec2(1000.0)).xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float rainDist(vec2 p, float scale, float rainIntensity) {
	// scale everything
	p *= 0.1;
	// sheer
	p.x += p.y * direction ;
	// scroll
	p.y -= TIME * speed * 500.0 / scale;
	// expand Y
	p.y *= 0.03;
	float ix = floor(p.x);
	// shift Y
	p.y += mod(ix, 2.0) * 0.5 + (rand(vec2(ix)) - 0.5) * 0.3;
	float iy = floor(p.y);
	vec2 index = vec2(ix, iy);
	// mod
	p -= index;
	// shift X
	p.x += (rand(index.yx) * 2.0 - 1.0) * 0.35;
	// distance
	vec2 a = abs(p - 0.5);
	float res = max(a.x * 0.8, a.y * 0.5) - 0.1;
	// decimate
	bool empty = rand(index) < mix(1.0, 0.1, rainIntensity);
	return empty ? 1.0 : res;
}

void fragment() {
	vec2 wpos = FRAGCOORD.xy;

	vec3 add = vec3(0);
	float rainSum = 0.0;

	const int numLayers = 4;
	vec2 warpOffset = vec2(0.0);
	vec2 screenCenter = (1.0 / SCREEN_PIXEL_SIZE) * 0.5;

	if (calculate_rain){
		float scales[4];
		scales[0] = 1.0;
		scales[1] = 1.8;
		scales[2] = 2.6;
		scales[3] = 4.8;
		for (int i = 0; i < numLayers; i++) {
			float Rainscale = scales[i];
			float r = rainDist(wpos * Rainscale / Scale + 500.0 * float(i), Rainscale, Intensity);
			if (r < 0.0) {
				float v = (1.0 - exp(r * 5.0)) / Rainscale * 2.0;
				wpos.x += v * 10.0 * Scale;
				wpos.y -= v * 2.0 * Scale;
				add += vec3(0.1, 0.15, 0.2) * v;
				rainSum += (1.0 - rainSum) * 0.75;

				if (warp_screen){
					warpOffset.x += v * warp_amount * (FRAGCOORD.x - screenCenter.x) / screenCenter.x;
					warpOffset.y += v * warp_amount * (FRAGCOORD.y) / screenCenter.y;
				}
			}
		}
	}

	vec2 uv = UV;
	uv.x -= warpOffset.x * 0.03;
	uv.y -= warpOffset.y * 0.03;

	vec4 LIGHTMAP_ = texture(LIGHTMAP,uv);
	vec4 GAME_ = texture(TEXTURE,uv);

	if (use_screen)
		GAME_ = texture(Screen,SCREEN_UV);

	LIGHTMAP_.a = GAME_.a;

	GAME_.rgb += add;
	GAME_.rgb = mix(GAME_.rgb, RainColor, 0.1 * rainSum);
	if (use_lightmap)
		COLOR =  1.0 - (1.0 - LIGHTMAP_) * (1.0 - GAME_);
	else
		COLOR =  GAME_;
}