shader_type canvas_item;
//"super FUCKING awesome tile shader V1"  by mable yeah
//type "i love TV" in the chat to recieve 10 + battle points and invulnerability to poison attacks
//on the next turn

uniform vec2 direction;
uniform float speed_scale;

group_uniforms canvas_effects;
uniform vec2 canvas_scaling = vec2(1.0);
uniform float canvas_rotation;

group_uniforms texture_effects;
uniform float texture_spacing_x :hint_range(0.0, 0.9, 0.01) = 0.0;
uniform float texture_spacing_y :hint_range(0.0, 0.9, 0.01) = 0.0;
uniform vec2 texture_scaling = vec2(1.0);
uniform float texture_rotation;

//https://gist.github.com/ayamflow/c06bc0c8a64f985dd431bd0ac5b557cd
vec2 rotateUV(vec2 uv, float rotation,vec2 mid){
    return vec2(
      cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x,
      cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y
    );
}

void vertex(){
	VERTEX *= canvas_scaling ;
	VERTEX = rotateUV(VERTEX,canvas_rotation,vec2(0.5));
}

void fragment(){
	vec2 texture_tile_spacing = vec2(texture_spacing_x,texture_spacing_y);
	vec2 move = direction * TIME * speed_scale;
	if (abs(speed_scale) <= 0.0){
		move = direction;
	}

	vec2 uv = UV;

	uv -= 0.5;
	uv *= (canvas_scaling / texture_scaling) ;
	uv = rotateUV(uv, texture_rotation,vec2(0.0));

	uv *= (1.0 - texture_tile_spacing);

	vec2 tile_uv = fract(uv + move * (1.0 + texture_tile_spacing));
	vec2 texture_uv = tile_uv / (1.0 - texture_tile_spacing);

	if (any(greaterThan(texture_uv, vec2(1.0)))) {
		discard;
	}
	COLOR = texture(TEXTURE, texture_uv);
}
