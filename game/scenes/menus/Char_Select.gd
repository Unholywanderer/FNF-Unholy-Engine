extends Node2D

var funny_test:PixelatedIcon
var name_tag:NameTag
var player:DipshitPlayer
func _ready() -> void:
	#funny_test = PixelatedIcon.new()
	#funny_test.position = Vector2(250, 300)
	#funny_test.change_icon('bf')
	#add_child(funny_test)
	bop_play = true
	$Cam.position.y = 0
	Audio.play_music('stayFunky-intro')
	Audio.Player.finished.connect(func():
		if Audio.music.contains('stayFunky'):
			if Audio.music.ends_with('-intro'):
				Conductor.reset_beats()
				Audio.play_music('stayFunky'))
	Audio.sync_conductor = true
	Conductor.reset_beats()
	Conductor.bpm = 90
	Conductor.beat_hit.connect(beat_hit)
	Conductor.song_started = true

	name_tag = NameTag.new()
	name_tag.position = Vector2(1008, 100)
	$Bar.add_child(name_tag)

	player = DipshitPlayer.new()
	player.hide()
	$Peeps.add_child(player)
	get_tree().create_timer(0.7, false).timeout.connect(func():
		player.show()
		player.play_anim('slideIn')
	)

	var ehh = [
		'',  '', '',
		'', 'bf', '',
		'',  '', ''
	]
	for i in 9:
		var fuck
		if ehh[i].is_empty():
			fuck = Lock.new()
		else:
			fuck = PixelatedIcon.new()
			fuck.change_icon(ehh[i])
			fuck.z_index = 15
		$Icons.add_child(fuck)

	align_icons()

	#barthing.y += 80
	#FlxTween.tween(barthing, {y: barthing.y - 80}, 1.3, {ease: FlxEase.expoOut})
	#dipshitBacking.y += 210
	#FlxTween.tween(dipshitBacking, {y: dipshitBacking.y - 210}, 1.1, {ease: FlxEase.expoOut})

	#chooseDipshit.y += 200
	#FlxTween.tween(chooseDipshit, {y: chooseDipshit.y - 200}, 1, {ease: FlxEase.expoOut})

	#dipshitBlur.y += 220
	#FlxTween.tween(dipshitBlur, {y: dipshitBlur.y - 220}, 1.2, {ease: FlxEase.expoOut})
var lo:int = 0
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"back"): Game.switch_scene('menus/freeplay')
	if event.is_action_pressed("accept"):
		bop_play = true
		player.play_anim('slideOut')
		get_tree().create_timer(0.3, false).timeout.connect(func():
			lo = wrapi(lo + 1, 0, 3)
			name_tag.switch_tag(['bf', 'pico', 'locked'][lo])
			player.change_char(['bf', 'pico', 'locked'][lo])
		)

func beat_hit(beat:int) -> void:
	if player.cur_anim == 'idle':
		player.play_anim('idle')
	$Speakers/Sprite.playing = true
	$Speakers/Sprite.frame = 0

func align_icons() -> void:
	for i:int in $Icons.get_child_count():
		var item = $Icons.get_child(i)
		var pos:Vector2 = Vector2(i % 3, floor(i / 3.0));

		# pixel icon looks offcenter without the (width/height) / 1.8
		item.position.x = pos.x * 118 + (item.width / 1.8 if item is PixelatedIcon else 0) #grpXSpread;
		item.position.y = pos.y * 130 + (item.height / 1.8 if item is PixelatedIcon else 0) #grpYSpread;

		#item.position.x += grpIcons.x;
		#item.position.y += grpIcons.y;

func _process(delta:float) -> void:
	if bop_play: bop_icon($Icons.get_child(4), delta)

var bop_info:Array[Dictionary] = JSFParser.parse('images/char_select/_info/iconBop/iconBopInfo')
var bop_timer:float = 0;
var delay:float = 1 / 24.0;
var bop_frame:int = 0;
var bop_play:bool = false;
var bop_ref_x:float = 0;
var bop_ref_y:float = 0;

func bop_icon(icon:PixelatedIcon, elapsed:float) -> void:
	if bop_frame >= bop_info.size():
		bop_ref_x = 0;
		bop_ref_y = 0;
		bop_play = false;
		bop_frame = 0;
		return;

	bop_timer += elapsed;

	if bop_timer >= delay:
		bop_timer -= bop_timer;

		var ref_frame = bop_info[bop_info.size() - 1];
		var cur_frame = bop_info[bop_frame];
		#if bop_frame >= 13: icon.filters = selectedBizz

		var x_diff:float = cur_frame.scale_x - ref_frame.scale_x;
		var y_diff:float = cur_frame.scale_y - ref_frame.scale_y;

		icon.scale = Vector2(2.6, 2.6);
		icon.scale += Vector2(x_diff, y_diff)

		bop_frame += 1

class DipshitPlayer extends AnimateSymbol:
	var char_name:String = ''
	var le_anim:String = ''
	var pos:Dictionary[String, Vector2] = {
		'bf': Vector2(630, 345), 'pico': Vector2(750, 390),
		'locked': Vector2(715, 380)
	}
	var anim_data = { # this works fine for now since only 2 chars but, this isnt very customizable is it
		'bf': {'idle': [0, 9], 'confirm': [16, 28], 'unconfirm': [29, 46],
		 'slideIn': [50, 57], 'slideOut': [48, 49]},
		'pico': {'idle': [0, 11], 'confirm': [16, 22], 'unconfirm': [29, 38],
		 'slideIn': [42, 50], 'slideOut': [40, 41], 'unlock': [51, 80]},
		'locked': {'idle': [0, 26], 'unlock': [27, 108]}

	#	'bf': {'idle': 'bf cs idle', 'confirm': 'bf cs confirm', 'unconfirm': 'bf cs deselect',
	#	 'slideIn': 'bf slide in', 'slideOut': 'bf slide out'},
	#	'pico': {'idle': 'bf cs idle', 'confirm': 'bf cs confirm', 'unconfirm': 'bf cs deselect',
	#	 'slideIn': 'bf slide in', 'slideOut': 'bf slide out'}
	}
	func _init() -> void:
		loop_mode = 'Play Once'
		atlas = 'res://assets/images/char_select/dipshits/bfChill'
		position = Vector2(630, 345)
		change_char()
		finished.connect(func():
			if cur_anim == 'slideIn':
				play_anim('idle')
		)

	func change_char(new_chill:String = 'bf') -> void:
		if new_chill == char_name: return
		loop_mode = 'Loop' if new_chill == 'locked' else 'Play Once'

		atlas = 'res://assets/images/char_select/dipshits/'+ new_chill +'Chill'
		position = pos[new_chill]
		_added_anims.clear()
		char_name = new_chill
		for i in anim_data[char_name].keys():
			add_anim_by_frames(i, anim_data[char_name][i])
		play_anim('slideIn')

class DipshitGF extends AnimateSymbol:
	pass

class Lock extends AnimateSymbol:
	const colors = [
		0x31F2A5, 0x20ECCD, 0x24D9E8,
		0x20ECCD, 0x20C8D4, 0x209BDD,
		0x209BDD, 0x2362C9, 0x243FB9
	]

	func _init() -> void:
		atlas = 'res://assets/images/char_select/lock'
		loop_mode = 'Fuck no'
		playing = false

class NameTag extends Sprite2D:
	func _ready() -> void:
		var mos_shader = ShaderMaterial.new()
		mos_shader.shader = load('res://game/resources/shaders/mosiac.gdshader')
		material = mos_shader

		switch_tag('bf')

	func switch_tag(new_tag:String = 'bf') -> void:
		if texture == null: texture = load('res://assets/images/char_select/nametags/bf.png')
		shader_effect()
		get_tree().create_timer(4.0 / 30.0, false).timeout.connect(func():
			var path = 'assets/images/char_select/nametags/%s.png' % [new_tag]
			if !ResourceLoader.exists('res://'+ path):
				path = 'res://assets/images/char_select/nametags/locked.png'

			texture = load(path)
			scale = Vector2(0.77, 0.77)
			shader_effect(true)
		)

	func shader_effect(fade_out:bool = false) -> void:
		var size:Vector2 = Vector2(texture.get_width() * scale.x, texture.get_height() * scale.y)
		if fade_out:
			block_timer(0, 1, 1)
			block_timer(1, size.x / 27.0, size.y / 26.0)
			block_timer(2, size.x / 10.0, size.y / 10.0)

			block_timer(3, 1, 1)
		else:
			block_timer(0, size.x / 10.0, size.y / 10.0)
			block_timer(1, size.x / 73.0, size.y / 6.0)
			block_timer(2, size.x / 10.0, size.y / 10.0)

	func block_timer(frame:int, force_x:float = -1, force_y:float = -1) -> void:
		var da:Vector2 = Vector2(10 * randi_range(1, 4), 10 * randi_range(1, 4))

		if force_x > -1: da.x = force_x
		if force_y > -1: da.y = force_y

		get_tree().create_timer(frame / 30.0, false).timeout.connect(func():
			material.set_shader_parameter('uBlocksize', da)
		)
