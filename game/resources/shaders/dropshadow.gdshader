shader_type canvas_item;
//ported by mae :p
//update v2:
//peer pressured anti aliasing into working by sidestepping the function entirely
//added a "pixel perfect" mode for pixel stages
//show mask debug option

group_uniforms Drop_Shadow_config;
uniform float ang : hint_range(0, 360) = 0.0;
uniform float dist : hint_range(0, 100) = 15.0;
uniform float str : hint_range(0, 5) = 1.0;
uniform float thr : hint_range(0, 1) = 0.1;

uniform bool useMask = false;
uniform float thr2 : hint_range(0, 1) = 1.0;

uniform vec3 dropColor : source_color = vec3(0.5, 0.5, 0.5);
uniform float angOffset = 1.0;
uniform float AA_STAGES : hint_range(0, 0.2) = 0.08;
uniform sampler2D altMask : filter_nearest_mipmap;
group_uniforms HSBC_config;
uniform float hue : hint_range(-360, 360) = 10.0;
uniform float saturation : hint_range(-100, 100) = -50.0;
uniform float brightness : hint_range(-255, 255) = -50.0;
uniform float contrast : hint_range(-100, 100) = 1.0;

group_uniforms Debug;
uniform bool ShowMask = false;
uniform bool pixelPerfectFix = false;

const vec3 grayscaleValues = vec3(0.3098039215686275, 0.607843137254902, 0.0823529411764706);
const float e = 2.718281828459045;

vec3 applyHueRotate(vec3 aColor, float aHue){
	float angle = radians(aHue);

	mat3 m1 = mat3(vec3(0.213, 0.213, 0.213),
		vec3(0.715, 0.715, 0.715),
		vec3(0.072, 0.072, 0.072));

	mat3 m2 = mat3(vec3(0.787, -0.213, -0.213),
		vec3(-0.715, 0.285, -0.715),
		vec3(-0.072, -0.072, 0.928));

	mat3 m3 = mat3(vec3(-0.213, 0.143, -0.787),
		vec3(-0.715, 0.140, 0.715),
		vec3(0.928, -0.283, 0.072));

	mat3 m = m1 + cos(angle) * m2 + sin(angle) * m3;

	return m * aColor;
}

vec3 applySaturation(vec3 aColor, float value){
	if(value > 0.0){ value = value * 3.0; }
	value = (1.0 + (value / 100.0));
	vec3 grayscale = vec3(dot(aColor, grayscaleValues));
	return clamp(mix(grayscale, aColor, value), 0.0, 1.0);
}

vec3 applyContrast(vec3 aColor, float value){
	value = (1.0 + (value / 100.0));
	if(value > 1.0){
 		value = (((0.00852259 * pow(e, 4.76454 * (value - 1.0))) * 1.01) - 0.0086078159) * 10.0; //Just roll with it...
  		value += 1.0;
	}
	return clamp((aColor - 0.25) * value + 0.25, 0.0, 1.0);
}

vec3 applyHSBCEffect(vec3 color){
	//Brightness
	color = color + ((brightness) / 255.0);

	//Hue
	color = applyHueRotate(color, hue);

	//Contrast
	color = applyContrast(color, contrast);

	//Saturation
	color = applySaturation(color, saturation);

	return color;
}


float intensityPass(vec2 fragCoord, sampler2D iChannel0) {
	vec4 col = texture(iChannel0, fragCoord);

	float maskIntensity = 0.0;
	if (useMask == true) {
		maskIntensity = mix(0.0, 1.0, texture(altMask, fragCoord).b);
	}

	if (col.a <= 0.0) {
		return 0.0;
	}

	float intensity = dot(col.rgb, vec3(0.3098, 0.6078, 0.0823));
	//is this stupid? probs, did it work, yeahs.
	//somehow the anti aliasing function in the actual og shader just didnt work no matter what i did
	//BUT disabling the mask functionality did work to cause aliasing so i did a little trickery
	//- mae
	float edgeL = useMask && maskIntensity > 0.0 ? thr2 - AA_STAGES : thr - AA_STAGES;
	float edgeH = useMask && maskIntensity > 0.0 ? thr2 + AA_STAGES : thr + AA_STAGES;
	intensity = smoothstep(edgeL, edgeH, intensity);

    return intensity ;
}

vec3 createDropShadow(vec3 color,in vec2 uv,sampler2D tex,vec2 SCR) {
	// essentially a mask so that areas under the threshold dont show the rimlight (mainly the outlines)
	float intensity = intensityPass(uv,tex);


	// check the pixel in the direction and distance specified
	vec2 checkedPixel = vec2(uv.x + (dist * cos(ang/100. + angOffset) * SCR.x), uv.y - (dist * sin(ang/100. + angOffset) * SCR.y));

	if (pixelPerfectFix)
	{
		// chat, am i cooking?? - mae
		vec2 offset = round(vec2(cos(radians(ang + angOffset)), -sin(radians(ang + angOffset))) * dist);
		checkedPixel = uv + offset * SCR;
	}

	// multiplier for the intensity of the drop shadow
	float dropShadowAmount = 0.0;
	if (checkedPixel.x > 0.0 && checkedPixel.y > 0.0 && checkedPixel.x < 1.0 && checkedPixel.y < 1.0) {
		dropShadowAmount = texture(tex, checkedPixel).a;
	}
	// add the dropshadow color  based on the amount, strength, and intensity

	color += dropColor * ((1.0 - (dropShadowAmount * str)) * intensity);
	return color;
}

void fragment(){
	vec4 col = texture(TEXTURE, UV);

	if (ShowMask){
		col = texture(altMask, UV);

		if (col.b <= 0.0) {
			discard;
		}
	}

	if (col.a <= 0.0) {
		discard;
	}

	vec3 unpremultipliedColor = col.a > 0.0 ? col.rgb / col.a : col.rgb;
	vec3 outColor = applyHSBCEffect(unpremultipliedColor);

	outColor = createDropShadow(outColor,UV,TEXTURE,TEXTURE_PIXEL_SIZE);
	COLOR = vec4(outColor * col.a, col.a);
}