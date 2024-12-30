class_name NoteSplash; extends AnimatedSprite2D;

var info:Dictionary = {
	'vis'     = [[1, 2], 0.65, -20], # [variant_min, variant_max], scale, y_offset
	'base'    = [[1, 2], 0.75,   0],
	'haxe'    = [[],     0.65,   0],
	'forever' = [[1, 2], 1,      0]
}

func _init(da_strum:Strum):
	var spl = 'forever' if Prefs.daniel else Prefs.splash_sprite
	sprite_frames = Game.persist.note_splash
	scale = Vector2(info[spl][1], info[spl][1]) # 0.95, 0.95
	modulate.a = 0.8 #0.6
	
	var rand:String = '1'
	if info[spl][0].size() == 2:
		rand = str(randi_range(info[spl][0][0], info[spl][0][1]))
	
	play('splash %s %s' % [rand, ['purple', 'blue', 'green', 'red'][da_strum.dir % 4]])
	position = da_strum.position + Vector2(0, info[spl][2])
