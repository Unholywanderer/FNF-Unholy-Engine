shader_type canvas_item;

//rain v3 by mable yeah
uniform sampler2D SCREEN : hint_screen_texture;
uniform bool warp_screen = true;

const int numLayers = 4;
const float scales[4] = float[4](1.0,1.8,2.6,4.8);

uniform float warp_amount = 1.0;
uniform float direction : hint_range(-0.8,0.8,0.1) = 0.1;
uniform float Scale = 1;
uniform float intensity = 0.1;
uniform float speed = 1.0;

//vec3(0.1, 0.15, 0.2) * 4 and then lightened up to match with the original code's results
uniform vec3 RainColor: source_color = vec3(0.7, 0.8, 0.9);

float rand(vec2 uv){
	return fract(sin(dot(uv ,vec2(12.9,78.2))) * 43758.5);
}

float rainDist(vec2 uv, float scale) {
	//scale, shear + transform
	uv.x += uv.y * direction;
	uv.y = (uv.y - TIME * speed * 500.0 / scale) * 0.03;

	vec2 index = floor(uv);
	float random = rand(index);
	uv -= index;

	//shift
	uv.y += (random - 0.5) * 1.0;
	uv.x += (random * 2.0 - 1.0) * 0.35;

	//get distance, decimate
	vec2 distance_ = abs(uv - 0.5);
	float res = max(distance_.x * 0.8, distance_.y * 0.5) - 0.1;
	return (random < mix(1.0, 0.1, intensity)) ? 1.0 : res;
}

void fragment() {
	vec2 uv = UV / 0.01; float add = 0.0;

	for (int i = 0; i < numLayers; i++) {
		float rainscale = scales[i];
		float rain  = rainDist(uv / (rainscale * float(i) * Scale), rainscale);
		if (rain < 0.0) {
			float v = (1.0 - exp(rain * 5.0)) / rainscale * 2.0;
			add += v;
		}
	}

	if (warp_screen){
		vec4 screen = texture(SCREEN,SCREEN_UV - (vec2(0.0,add/20.0) * warp_amount)); 		
		COLOR = mix(screen, vec4(RainColor,1.0),add/2.0);
	}
	else {
		COLOR = mix(vec4(RainColor,0.0), vec4(RainColor,1.0),add/2.0);
	}
}