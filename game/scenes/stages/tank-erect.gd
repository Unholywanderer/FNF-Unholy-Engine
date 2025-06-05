extends StageBase

var tank_notes:Array = [] # for the fucks that run in and get shot
var runnin_boys:Array = []

func post_ready() -> void:
	if gf.cur_char.begins_with('gf'):
		gf_pos.x += 150
		gf.position.x = gf_pos.x

	var rimming = ShaderMaterial.new()
	rimming.shader = load('res://game/resources/shaders/dropshadow.gdshader')
	rimming.set_shader_parameter('dropColor', Color('DFEF3C'))

	rimming.set_shader_parameter('brightness', -46)
	rimming.set_shader_parameter('hue', -38)
	rimming.set_shader_parameter('saturation', -25)
	rimming.set_shader_parameter('contrast', -20)

	for i in [boyfriend, dad, gf]:
		var funny = rimming.duplicate(true)
		funny.set_shader_parameter('ang', 90)
		if i == dad:
			funny.set_shader_parameter('ang', 135)
			funny.set_shader_parameter('thr', 0.3)
		i.material = funny

var saw_cutscene:bool = false
func song_end() -> void:
	if SONG.song == 'Stress (Pico Mix)' and !saw_cutscene:
		saw_cutscene = true
		THIS.can_end = false
		var cutscene = Cutscene.new()
		#add_child(cutscene)
		dad.hide()

		var tanky_boy:AnimateSymbol = AnimateSymbol.new()
		tanky_boy.atlas = 'res://assets/images/stages/tank/erect/cutscene/tankmanEnding'
		add_child(tanky_boy)
		tanky_boy.loop_mode = 'beh'
		tanky_boy.playing = true
		tanky_boy.material = dad.material
		tanky_boy.position = dad.position + Vector2(300, 195)
		THIS.cam.position_smoothing_speed = 2
		THIS.cam.position = dad.get_cam_pos() + Vector2(320, -60)
		THIS.default_zoom = 0.65

		Audio.play_sound('tank/cutscene/end-pico')
		cutscene.add_timed_event(176.0/24.0, func(): boyfriend.play_anim('laugh'))
		cutscene.add_timed_event(270.0/24.0, func():
			THIS.cam.position_smoothing_speed = 1
			THIS.cam.position = boyfriend.get_cam_pos() - Vector2(130, -80)
		)
		cutscene.add_timed_event(320.0/24.0, func():
			THIS.can_end = true
			THIS.song_end()
		)

func init_tankmen():
	gf.chart = Chart.load_named_chart(JsonHandler.song_root, 'picospeaker', 'v_slice')
	tank_notes = gf.chart.duplicate()

	for note in tank_notes:
		if Util.rand_bool(16):
			var tankyboy = Tankmen.new(Vector2(500, 100), note[1] < 2)
			tankyboy.strum_time = note[0]
			$RunMen.add_child(tankyboy)
			runnin_boys.append(tankyboy)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func beat_hit(beat:int):
	if beat % 2 == 0:
		for tank in [$Sniper, $Guy]:
			tank.frame = 0
			tank.play('idle')

func event_hit(event:EventData) -> void:
	if event.event == 'SetHealthIcon' and dad.cur_char == 'tankman-bloody':
		dad.forced_suffix = '-bloody'

var played_line:bool = false
func game_over_start(scene): played_line = false
func game_over_idle(scene):
	if !played_line:
		played_line = true
		Audio.volume = 0.4
		var _death = Audio.return_sound('tank/jeffGameover-'+ str(randi_range(1, 25)))
		_death.play()
		_death.finished.connect(func(): Audio.volume = 1)

class Tankmen extends AnimatedSprite2D:
	var t_speed:float = 0.0
	var strum_time:float = 0.0
	var facing_right:bool = false
	var ending_offset:int = 0
	var shot_offset:Vector2 = Vector2(-400, -200)

	func _init(pos:Vector2, right:bool):
		centered = false
		position = pos
		sprite_frames = load('res://assets/images/stages/tank/tankmen/tankmanKilled1.res')
		scale = Vector2(1.1, 1.1)
		use_parent_material = true

		ending_offset = randi_range(50, 200)
		t_speed = randf_range(0.6, 1)

		facing_right = right
		if !facing_right:
			shot_offset.x /= 2
			shot_offset.x += 10
		play('runIn')
		frame = randi_range(0, sprite_frames.get_frame_count('runIn') - 1)
		animation_finished.connect(queue_free)

	func reset(pos:Vector2, right:bool):
		position = pos
		facing_right = right
		ending_offset = randi_range(50, 200)
		t_speed = randf_range(0.6, 1)

	func _process(delta):
		flip_h = facing_right

		if animation == 'runIn':
			var speed:float = (Conductor.song_pos - strum_time) * t_speed
			if facing_right:
				position.x = (-0.12 * Game.screen[0] - ending_offset) + speed
			else:
				position.x = (0.70 * Game.screen[0] + ending_offset) - speed

		if Conductor.song_pos > strum_time:
			play('shot'+ str(randi_range(1, 2)))
			offset = shot_offset
			strum_time = INF
