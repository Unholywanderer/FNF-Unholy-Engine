shader_type canvas_item; //ported by @mableovo
//put this shader on a colorRect!!
uniform float Intensity :hint_range(0.0, 8.0) = 0.2;
uniform float Timescale :hint_range(-10.0, 10.0) = 0.05;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture,filter_linear_mipmap;

float rand(vec2 a) {
    return fract(sin(dot(mod(a, vec2(1000.0)).xy, vec2(12.9898, 78.233))) * 43758.5453);
}



float rainDist(vec2 p, float scale, float intensity, float uTime) {
    p *= 0.1;
    p.x += p.y * 0.1;
    p.y -= uTime * 500.0 / scale;
    p.y *= 0.03;
    float ix = floor(p.x);
    p.y += mod(ix, 2.0) * 0.5 + (rand(vec2(ix)) - 0.5) * 0.3;
    float iy = floor(p.y);
    vec2 index = vec2(ix, iy);
    p -= index;
    p.x += (rand(index.yx) * 2.0 - 1.0) * 0.35;
    vec2 a = abs(p - 0.5);
    float res = max(a.x * 0.8, a.y * 0.5) - 0.1;
    bool empty = rand(index) < mix(1.0, 0.1, intensity);
    return empty ? 1.0 : res;
}

void fragment() {
    vec2 fragCoord = FRAGCOORD.xy;
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = fragCoord / iResolution;
    vec2 wpos = uv * iResolution;

    float intensity = Intensity;
    float uTime = TIME * Timescale;
    vec3 add = vec3(0.0);
    float rainSum = 0.0;

    const int numLayers = 4;
    float scales[4];
    scales[0] = 1.0;
    scales[1] = 1.8;
    scales[2] = 2.6;
    scales[3] = 4.8;

    vec2 warpOffset = vec2(0.0);
    vec2 screenCenter = iResolution * 0.5;

    for (int i = 0; i < numLayers; i++) {
        float scale = scales[i] / 4.0;
        float r = rainDist(wpos * scale + 500.0 * float(i), scale, intensity, uTime);
        if (r < 0.0) {
            float v = (1.0 - exp(r * 5.0)) / scale * 2.0;
            wpos.x += v * 10.0;
            wpos.y -= v * 2.0;
            add += vec3(0.1, 0.15, 0.2) * v;
            rainSum += (1.0 - rainSum) * 0.75;
            warpOffset.x += v * 0.1 * (fragCoord.x - screenCenter.x) / screenCenter.x;
            warpOffset.y += v * 0.1 * (fragCoord.y) / screenCenter.y;
        }
    }

    vec3 rainColor = vec3(0.4, 0.5, 0.8);
    uv.x -= warpOffset.x * 0.03;
    uv.y -= warpOffset.y * 0.03;

    vec4 color = texture(SCREEN_TEXTURE, uv);
    color.rgb += (add * 0.4);
    color.rgb = mix(color.rgb, rainColor, 0.1 * rainSum);

    COLOR = color;
}
