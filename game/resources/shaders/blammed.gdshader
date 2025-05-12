shader_type canvas_item; // improved by cyn0x8, edited by me

uniform float black_threshold : hint_range(0.0, 5.0, 0.01) = 0.03; 
uniform float outline_threshold : hint_range(0.0, 5.0, 0.01) = 0.0;
/** What the color out the outlines will be (alpha, or [code]modulate.a[/code] has no effect) */
uniform vec4 outline_color:source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float col = smoothstep(black_threshold, outline_threshold, (color.r + color.g + color.b) / 3.0); 
	COLOR = vec4(mix(vec4(0.0), outline_color, col).rgb, color.a); //* color.a; 
}