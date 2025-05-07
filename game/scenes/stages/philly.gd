extends StageBase

# Blammed Shit #
var blammed_shader:ShaderMaterial
var can_blam:bool = false
var blammin:bool = false:
	set(blam):
		for i in get_children():
			if i is not Character:
				i.visible = !blam
		$City.visible = true
		$Windows/Line.visible = blam
		$City/Sprite.modulate.a = 0.4 if blam else 1.0
		$Windows.visible = true
		$Black.visible = true
		$Gradifloor.visible = blam
		blammin = blam

		if blam:
			for i in [boyfriend, gf, dad]:
				if i == null: continue
				i.material = blammed_shader.duplicate()

			boyfriend.material.set_shader_parameter('outline_color', Color.CYAN)
			gf.material.set_shader_parameter('outline_color', Color.MAROON)
			dad.material.set_shader_parameter('outline_color', Color.GREEN_YELLOW)

			#UI.icon_p1.material = boyfriend.material
			#UI.icon_p2.material = dad.material
		else:
			for i in [boyfriend, gf, dad]:
				if i == null: continue
				i.material = null

@onready var initial_points:Array = $Windows/Line.points
var spec = AudioServer.get_bus_effect_instance(1, 0)

var windows:Array = ['31A2FD', '31FD8C', 'FB33F5', 'FD4531', 'FBA633'] # window colors so fancy wow woah woaoh

var train:Train = Train.new(Vector2(2000, 360))
func _ready():
	if SONG.song.to_lower().contains('blammed'):
		can_blam = true
		blammed_shader = ShaderMaterial.new()
		blammed_shader.shader = load('res://game/resources/shaders/blammed.gdshader')

	default_zoom = 1.05
	bf_pos += Vector2(70, -50)
	dad_pos += Vector2(100, -50)
	gf_pos.x += 100
	add_child(train)
	move_child(train, 5)

func countdown_start():
	pass
	#gf.load_char('gf-car')
	#THIS.remove_child(gf)
	#train.add_child(gf)
	#gf.scale /= 2.0
	#gf.position -= Vector2(155, train.texture.get_size()[1] / (1.28 / gf.scale.x))
	#Game.scene.speaker.visible = false

func _process(delta):
	$Windows/Sprite.self_modulate.a -= (Conductor.crochet / 1000.0) * delta * 1.5

	if blammin:
		var prev_hz:float = 0.0
		for i in initial_points.size():
			var hz:float = float(i) * 11025.0 / float(initial_points.size())
			var magnitude = spec.get_magnitude_for_frequency_range(prev_hz, hz).length()
			#var energy := clampf((6.0 + linear_to_db(magnitude)) / 6.0, 0.0, 1.0)
			#var silly := remap(energy, 0.0, 1.0, 0.0, 5.0)
			$Windows/Line.set_point_position(i, Vector2(0 + (30 * i), 300 - (magnitude * (300 + prev_hz))))
			prev_hz = hz
	else:
		for i in initial_points.size():
			var lin = $Windows/Line.get_point_position(i)
			var ini = initial_points[i]
			$Windows/Line.set_point_position(i, Vector2(lerpf(lin.x, ini.x, delta * 2), lerpf(lin.y, ini.y, delta * 2)))

var last_color:String
func beat_hit(beat:int):
	train.beat_hit(beat)
	if can_blam:
		if beat == 128: blammin = true
		if beat == 192: blammin = false

	if beat % 4 == 0:
		var can_cols = windows.duplicate()
		if last_color: can_cols.remove_at(windows.find(last_color))
		last_color = can_cols[randi_range(0, can_cols.size() - 1)]
		$Windows/Sprite.self_modulate = Color(last_color)

class Train extends Sprite2D:
	var active:bool = false
	var started:bool = false
	var stopping:bool = false

	var frame_limit:float = 0.0
	var sound := AudioStreamPlayer.new()
	var cars:int = 8
	var cooldown:int = 0

	func _init(pos:Vector2):
		centered = false
		position = pos
		texture = load('res://assets/images/stages/philly/train.png')
		sound.stream = load('res://assets/sounds/train_passes.ogg')
		add_child(sound)

	func _process(delta):
		if active:
			frame_limit += delta
			if frame_limit >= 1.0 / 24.0: #you gotta be kidding me
				frame_limit = 0.0
				if sound.get_playback_position() >= 4.7:
					started = true
					if Game.scene.gf.has_anim('hairBlow'):
						Game.scene.gf.play_anim('hairBlow')
						Game.scene.gf.can_dance = false
					#var last_frame:int = Game.scene.gf.frame
					#Game.scene.gf.play_anim(Game.scene.gf.animation +'-hair')
					#Game.scene.gf.frame = last_frame

				if started:
					position.x -= 400
					if position.x < -2000 && !stopping:
						position.x = -1150
						cars -= 1
						if cars < 1:
							stopping = true

					if position.x < -4000 && stopping:
						restart()

	var dance_gf:bool = false
	func beat_hit(beat:int):
		if !active:
			cooldown += 1

		if beat % 8 == 4 && Util.rand_bool(30) && !active && cooldown > 8: # 30
			cooldown = randi_range(-4, 0)
			active = true
			sound.play(0)

	func restart() -> void:
		var geef:Character = Game.scene.gf
		if geef.has_anim('hairFall'):
			geef.play_anim('hairFall')
			geef.special_anim = true
			geef.danced = false
			geef.can_dance = true

		position.x = Game.screen[0] + 300
		active = false
		cars = 8
		stopping = false
		started = false
