shader_type canvas_item;
//added anti aliasing to ts (this shader)
uniform float size_ = 1.0;
uniform vec3 color:  source_color = vec3(1,1,1);
uniform float AA = 1.0;
//sleep phonk


void fragment()
{
	vec2 size = vec2(size_);
	vec2 TextureSize = 1.0 / TEXTURE_PIXEL_SIZE;
    vec4 supergay = texture(TEXTURE, UV);
    vec4 gay = texture(TEXTURE, UV);
	vec4 Color_real = vec4(color,1.0);


	float edgeAlpha = 0.0;

	//id do <= 0.0 but the unaliased inner outline sucks dookie so imma just overlay the actual texture over the "outline"
	//which is just a big block in this case BUT it has aliasing so its cool
    if (gay.a > -0.01) {
		float w = size.x / TextureSize.x;
		float h = size.y / TextureSize.y;
		edgeAlpha += texture(TEXTURE, vec2(UV.x + w, UV.y)).a;
		edgeAlpha += texture(TEXTURE, vec2(UV.x - w, UV.y)).a;
		edgeAlpha += texture(TEXTURE, vec2(UV.x, UV.y + h)).a;
		edgeAlpha += texture(TEXTURE, vec2(UV.x, UV.y - h)).a;

    }
	//same AA stuff as the dropShadow shader
	float intensity = smoothstep(0.0, 1.0, edgeAlpha);

	gay = mix(gay, Color_real, intensity * AA);

	float outAlpha = supergay.a + gay.a * (1.0 - supergay.a);
	vec3 outColor = (supergay.rgb * supergay.a + gay.rgb * gay.a * (1.0 - supergay.a)) / max(outAlpha, 0.001);

    COLOR = vec4(outColor,outAlpha);
}