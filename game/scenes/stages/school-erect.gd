extends StageBase

func post_ready() -> void:
	var rimming = ShaderMaterial.new()
	rimming.shader = load('res://game/resources/shaders/dropshadow.gdshader')
	rimming.set_shader_parameter('dropColor', Color('52351D'))
	
	rimming.set_shader_parameter('brightness', -66)
	rimming.set_shader_parameter('hue', -10)
	rimming.set_shader_parameter('saturation', 24)
	rimming.set_shader_parameter('contrast', -23)
	rimming.set_shader_parameter('dist', 5)
	rimming.set_shader_parameter('ang', 90)
	rimming.set_shader_parameter('pixelPerfectFix', true)
	
	
	for i in [boyfriend, dad, gf]:
		i.material = rimming
