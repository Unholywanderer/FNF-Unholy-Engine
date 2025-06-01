shader_type canvas_item;

uniform vec2 uBlocksize = vec2(0.1, 0.1);
void fragment(){
	vec2 texSize = vec2(textureSize(TEXTURE,0));
	vec2 blocks = texSize / uBlocksize;
	COLOR = texture(TEXTURE, floor(UV * blocks) / blocks);
}