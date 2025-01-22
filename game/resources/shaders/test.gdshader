shader_type canvas_item;

uniform vec4 color_to_be;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 new_color = vec4(0, 0, 0, color.a);
	
	//new_color = vec4(color.r, 1.0 - (color.g), 1.0 - (color.g), color.a);
	
	if ((color.r + color.g + color.b) < 0.15){
		new_color = vec4(0, 1.0 - (color.g / 2.0), 1.0 - (color.b / 2.0), color.a);
	}else if (color.r >= (color.g + color.b)){
		new_color = vec4(1, 0, 0, color.a);
	}else if (color.g >= (color.r + color.b)){
		new_color = vec4(0, 1, 0, color.a);
	}else if (color.b >= (color.r + color.g)){
		new_color = vec4(0, 0, 1, color.a);
	//}else if (color.r <= 0.4 && (color.g + color.b) >= 2.0){
	//	new_color = vec4(1, 1, 1, color.a);
	//}else if (color.r <= 0.4 && (color.g + color.b) <= 2.0){
	//	new_color = vec4(0, 0.8, 0.8, color.a);
	}else{//if(color.r >= (color.g + color.b)){
		new_color = vec4(0, 0, 0, color.a);
	}
	//if (new_color.rgb == vec3(1.0, 0, 0))
	//	new_color.rgb = vec3(0, 1, 1);
	COLOR = vec4(new_color.rgb, color.a);
}

/*
shader_type canvas_item;

uniform vec4 color_to_be;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 new_color = vec4(0, 0, 0, color.a);

	if ((color.r + color.g + color.b) < 0.15){
		new_color = color_to_be;
	}else if(color.r == 1.0){
		new_color = vec4(1, 0, 0, color.a);
	}else{//if(color.r >= (color.g + color.b)){
		new_color = vec4(0, 0, 0, color.a);
	}
	COLOR = vec4(new_color.rgb, color.a);
}


shader_type canvas_item;

uniform vec4 color_to_be;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 new_color = vec4(0, 0, 0, color.a);

	if ((color.r + color.g + color.b) < 0.15){
		new_color = color_to_be;
	}else if(color.r >= 1.0){
		new_color = vec4(1, 0, 0, color.a);
	}else{//if(color.r >= (color.g + color.b)){
		new_color = vec4(0, 0, 0, color.a);
	}
	COLOR = vec4(new_color.rgb, color.a);
}


	vec4 color = texture(TEXTURE, UV);
	vec4 new_color = vec4(0, 0, 0, color.a);

	if ((color.r + color.g + color.b) < 0.15){
		new_color = color_to_be;
	}else if(color.r >= 1.0){
		new_color = vec4(1, 0, 0, color.a);
	//}else if(color.r + color.g > 2.0){
	//	new_color = vec4(1, 1, 0, color.a);
	}else{//if(color.r >= (color.g + color.b)){
		new_color = vec4(0, 0, 0, color.a);
	}
	
	if (new_color.rgb == vec3(1.0, 0, 0))
		new_color.rgb = vec3(0, 1, 1);
	COLOR = vec4(new_color.rgb, color.a);
}


	vec4 color = texture(TEXTURE, UV);
	vec4 new_color = vec4(0, 0, 0, color.a);

	if ((color.r + color.g + color.b) < 0.15){
		new_color = vec4(0, 1.0 - (color.g / 2.0), 1.0 - (color.b / 2.0), color.a);
	}else if (color.r >= (color.g + color.b)){
		new_color = vec4(1, 0, 0, color.a);
	}else if (color.g >= (color.r + color.b)){
		new_color = vec4(0, 1, 0, color.a);
	}else if (color.b >= (color.r + color.g)){
		new_color = vec4(0, 0, 1, color.a);
	}else if (color.r <= 0.4 && (color.g + color.b) >= 2.0){
		new_color = vec4(1, 1, 1, color.a);
	}else if (color.r <= 0.4 && (color.g + color.b) <= 2.0){
		new_color = vec4(0, 0.8, 0.8, color.a);
	}else{//if(color.r >= (color.g + color.b)){
		new_color = vec4(0, 0, 0, color.a);
	}
	
	//if (new_color.rgb == vec3(1.0, 0, 0))
	//	new_color.rgb = vec3(0, 1, 1);
	COLOR = vec4(new_color.rgb, color.a);
*/