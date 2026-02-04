extends Node2D

var colors:Array[Color] = [Color(0.2, 1, 1, 1), Color(0.21, 0.21, 0.8, 0.64)]

var finished_intro:bool = false
var added_text:Array = []

var flash = ColorRect.new()
var show_cow:bool = false #Util.rand_bool(5)
var blurb:Array = []
func _ready():
	Discord.change_presence('Title Screen', 'Welcome to the Funkin')
	Audio.sync_conductor = true
	Audio.volume = 0
	Conductor.bpm = 102
	Conductor.beat_hit.connect(beat_hit)

	Conductor.song_started = true
	Audio.play_music('freakyMenu', true, 0)

	add_child(flash)
	move_child(flash, 4)
	flash.color = Color.BLACK
	flash.position = Vector2(-15, -15)
	flash.size = Vector2(1300, 755)

	if !show_cow:
		blurb = get_funny().pick_random()
	print(blurb)

	Util.center_obj($GodotLogo)
	$GodotLogo.position.y += 75
	if Game.persist.prev_scene != null:
		finish_intro()

var danced:bool = false
func beat_hit(beat) -> void:
	#Audio.play_sound('tick')
	danced = !danced
	$TitleGF.play('dance'+ ('Left' if danced else 'Right'))
	$Funkin.scale = Vector2(1.1, 1.1)

	if !finished_intro:
		match beat:
			1:
				#Audio.play_music('freakyMenu') # restart song so it sync
				create_tween().tween_property(Audio, 'volume', 0.7, 4)
				make_funny(['Stupid ass engine by'], 40)
			3: add_funny('unholywanderer', 40)
			4: remove_funny()
			5: make_funny(['Made this hunk of shit'], -40)
			7:
				add_funny('With Godot', -40)
				$GodotLogo.visible = true
			8:
				remove_funny()
				$GodotLogo.visible = false
			9:
				if show_cow:
					$cow.visible = true
					$cow.play()
					$cow.frame = 0
					Audio.volume = 0
					Conductor.song_started = false
					await $cow.animation_finished
					Conductor.song_started = true
				else:
					make_funny([blurb[0]])
			11:
				if !show_cow:
					add_funny(blurb[1] if blurb.size() == 2 else '')
			12: remove_funny()
			13: add_funny('friday')
			14: add_funny('night')
			15: add_funny('funkin')
			16: finish_intro()

var accepted:bool = false
var funk_sin:float = 0.0
var time_lerped:float = 0.0
var flash_tween
func _process(delta):
	funk_sin += delta
	$Funkin.rotation = sin(Conductor.cur_beat) / 8.0
	$Funkin.scale.x = lerpf($Funkin.scale.x, 1, delta * 7)
	$Funkin.scale.y = $Funkin.scale.x

	#Conductor.song_pos = Audio.pos #im lazy dont judge me
	if !accepted:
		time_lerped += delta
		if time_lerped >= 1.5:
			time_lerped = 0
			colors.reverse()
		$PressEnter.modulate = colors[0].lerp(colors[1], time_lerped / 1.5)

		if Input.is_action_just_pressed("accept"):
			accepted = true

			if !finished_intro:
				accepted = false
				finish_intro()
			else:
				Audio.play_sound('confirmMenu')
				$PressEnter.modulate = Color.WHITE
				$PressEnter.play('ENTER PRESSED')

				if flash_tween: flash_tween.kill()
				if flash.modulate.a >= 0:
					flash.modulate.a = 1
					create_tween().tween_property(flash, 'modulate:a', 0, 1)

				await get_tree().create_timer(1).timeout
				Game.switch_scene('menus/main_menu')
				#Conductor.reset()

func finish_intro() -> void:
	finished_intro = true
	remove_funny()

	$GodotLogo.visible = false
	$cow.visible = false

	if !Audio.playing_music: #or Audio.volume < 0.7:
		Audio.play_music('freakyMenu', true, 0.7)
	Audio.volume = 0.7
	#Audio.seek(10_000) # skip it to the good part,,,

	flash.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(flash, 'modulate:a', 0, 4)

func make_funny(text:Array, offset:int = 0) -> void:
	for i in text.size():
		var new_text = Alphabet.new(text[i])
		new_text.position.x = (Game.screen[0] / 2) - (new_text.width / 2)
		new_text.position.y += (i * 60) + 200 + offset
		add_child(new_text)
		added_text.append(new_text)

func add_funny(text:String, offset:int = 0) -> void:
	var new_text = Alphabet.new(text)
	new_text.position.x = (Game.screen[0] / 2) - (new_text.width / 2)
	new_text.position.y += (added_text.size() * 60) + 200 + offset
	add_child(new_text)
	added_text.append(new_text)

func remove_funny() -> void:
	Util.remove_all([added_text], self)

func get_funny() -> Array[Array]:
	var intro_txt = FileAccess.get_file_as_string('res://assets/data/introText.txt')
	if intro_txt == null: return [['this is a', 'fallback text lol']]

	var split_intro:Array[Array] = []
	for txt in intro_txt.split('\n'):
		split_intro.append(Array(txt.strip_edges().replace(',', '').split('--')))

	return split_intro

func on_music_finish():
	Conductor.reset_beats()
