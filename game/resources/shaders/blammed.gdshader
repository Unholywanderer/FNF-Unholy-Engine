shader_type canvas_item;

uniform vec4 outline_color;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 new_color = vec4(0, 0, 0, color.a);

	//new_color = vec4(color.r, 1.0 - (color.g), 1.0 - (color.g), color.a);

	if ((color.r + color.g + color.b) < 0.15){
		new_color = outline_color;
	}else if (color.r >= (color.g + color.b) + 0.05){
		new_color = vec4(1, 0, 0, color.a);
	}
	COLOR = vec4(new_color.rgb, color.a);
}