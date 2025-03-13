extends StageBase

func _ready():
	default_zoom = 0.8
	bf_pos = Vector2(970, 100)
	gf_pos = Vector2(650, 100)
	
	bf_cam_offset = Vector2(-50, -100)
	
func post_ready() -> void:
	var new = ShaderMaterial.new()
	new.shader = load('res://game/resources/shaders/adjust_color.gdshader')
	new.set_shader_parameter('hue', 5)
	new.set_shader_parameter('saturation', 20)
	
	for i in [boyfriend, gf, dad, $Santa]:
		i.material = new
	
func beat_hit(_beat:int):
	for i in [$UpperBop/Sprite, $BottomBop, $Santa]:
		i.play()
		i.frame = 0
