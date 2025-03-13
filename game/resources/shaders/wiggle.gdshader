shader_type canvas_item;
//put this shader on a colorRect!!
const int EFFECT_TYPE_DREAMY = 0;
const int EFFECT_TYPE_WAVY = 1;
const int EFFECT_TYPE_HEAT_WAVE_HORIZONTAL = 2;
const int EFFECT_TYPE_HEAT_WAVE_VERTICAL = 3;
const int EFFECT_TYPE_FLAG = 4;

uniform int effectType :hint_range(0, 4) = 4;

uniform float Speed = 1;

uniform float Freq;

uniform float Amp = 0.1;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
vec2 sineWave(vec2 pt, vec2 ss) {
    float x = 0.0;
    float y = 0.0;
    
    float w = 1.0 / ss.y; 
    float h = 1.0 / ss.x;

    if (effectType == EFFECT_TYPE_DREAMY) {
        pt.x = floor(pt.x / h) * h;

        float offsetX = sin(pt.x * Freq + TIME * Speed) * Amp;
        pt.y += floor(offsetX / w) * w;
        pt.y = floor(pt.y / w) * w;

        float offsetY = sin(pt.y * (Freq / 2.0) + TIME * (Speed / 2.0)) * (Amp / 2.0);
        pt.x += floor(offsetY / h) * h; 
    } else if (effectType == EFFECT_TYPE_WAVY) {
        float offsetY = sin(pt.x * Freq + TIME * Speed) * Amp;
        pt.y += offsetY; 
    } else if (effectType == EFFECT_TYPE_HEAT_WAVE_HORIZONTAL) {
        x = sin(pt.x * Freq + TIME * Speed) * Amp;
    } else if (effectType == EFFECT_TYPE_HEAT_WAVE_VERTICAL) {
        y = sin(pt.y * Freq + TIME * Speed) * Amp;
    } else if (effectType == EFFECT_TYPE_FLAG) {
        y = sin(pt.y * Freq + 10.0 * pt.x + TIME * Speed) * Amp;
        x = sin(pt.x * Freq + 5.0 * pt.y + TIME * Speed) * Amp;
    }
    
    return vec2(pt.x + x, pt.y + y);
}

void fragment() {
    vec2 uv = sineWave(UV,1.0 / SCREEN_PIXEL_SIZE);
    vec4 color = texture(SCREEN_TEXTURE, uv);
    COLOR = color;
}
