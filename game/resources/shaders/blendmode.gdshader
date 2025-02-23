shader_type canvas_item;

/*
multiply
screen
darken
lighten
difference
exclusion
overlay
hard_light
soft_light
color_dodge
linear_dodge
color_burn
linear_burn
*/

uniform int blend_mode;
void fragment() {
	if (blend_mode == 0){

	}else if (blend_mode == 1){
		
	}else if (blend_mode == 2){
		
	}else if (blend_mode == 3){
		
	}else if (blend_mode == 4){
		
	}else if (blend_mode == 5){
		
	}else if (blend_mode == 6){
		
	}else if (blend_mode == 7){
		
	}else if (blend_mode == 8){
		
	}else if (blend_mode == 9){
		
	}else if (blend_mode == 10){
		
	}else if (blend_mode == 11){
		
	}else if (blend_mode == 12){
		
	}
}

vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}
vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}
vec4 darken(vec4 base, vec4 blend){
	return min(base, blend);
}
vec4 lighten(vec4 base, vec4 blend){
	return max(base, blend);
}
vec4 difference(vec4 base, vec4 blend){
	return abs(base - blend);
}
vec4 exclusion(vec4 base, vec4 blend){
	return base + blend - 2.0 * base * blend;
}
vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec4 hard_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec4 soft_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}
vec4 color_dodge(vec4 base, vec4 blend){
	return base / (1.0 - blend);
}
vec4 linear_dodge(vec4 base, vec4 blend){
	return base + blend;
}

vec4 color_burn(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) / blend;
}
vec4 linear_burn (vec4 base, vec4 blend){
	return base + blend - 1.0;
}
