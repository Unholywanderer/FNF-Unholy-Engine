extends StageBase

func post_ready():
	var le_cols = [[12, 0, 7, -23], [-9, 0, -4, -30], [-32, 0, -23, -33]] # hue, sat, contrast, brightness
	var heh = [boyfriend, gf, dad]
	for i in heh.size():
		var new = ShaderMaterial.new()
		new.shader = load('res://game/resources/shaders/adjust_color.gdshader')
		new.set_shader_parameter('hue', le_cols[i][0])
		new.set_shader_parameter('saturation', le_cols[i][1])
		new.set_shader_parameter('contrast', le_cols[i][2])
		new.set_shader_parameter('brightness', le_cols[i][3])
		heh[i].material = new
