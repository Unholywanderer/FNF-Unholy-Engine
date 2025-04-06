shader_type canvas_item;

uniform vec2 direction = vec2(1.0,1.0);
uniform float speed_scale = 0.05;
// sprite needs to be repeatable
void fragment(){
     vec2 move = direction * TIME * speed_scale;
     COLOR = texture(TEXTURE, UV + move);
}