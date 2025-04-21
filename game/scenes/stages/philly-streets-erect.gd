extends StageBase

var light_stop:bool = false
var change_interval:int = 8
var prev_change:int = 0

var car_waiting:bool = false
var car1_interruptable:bool = true
var car2_interruptable:bool = true
var papr_interruptable:bool = true
const car_offsets = [[0, 0], [20, -15], [30, 50], [10, 60]]

var cur_can:AnimateSymbol = AnimateSymbol.new()
var CAN = load('res://assets/images/stages/philly-streets/effects/spraycanFULL.res')
func _ready() -> void:
	$Car1/Sprite.position = Vector2(1200, 818)
	$Car2/Sprite.position = Vector2(1200, 818)
	
	if SONG.player1.contains('pico'):
		THIS.DIE = load('res://game/scenes/game_over-pico.tscn')
	if !Game.persist.loaded_already:
		Game.persist.loaded_already = true
		ResourceLoader.load('res://assets/images/characters/pico/ex_death/blood.res')
		ResourceLoader.load('res://assets/images/characters/pico/ex_death/smoke.res')

	THIS.cam.position = Vector2(400, 490)

func post_ready() -> void:
	if gf.cur_char.contains('gf'):
		gf_pos.x += 150
		gf.position.x = gf_pos.x
		
	
func _process(delta:float) -> void:
	$Skybox/Sprite.region_rect.position.x -= delta * 22
	$Smog/Sprite.region_rect.position.x += delta * 22

	
func beat_hit(beat:int) -> void:
	var can_change:bool = (beat == (prev_change + change_interval))
		
	if Util.rand_bool(10) && !can_change && car1_interruptable:
		if !light_stop:
			pass #drive_car($Car1/Sprite)
		else:
			pass #drive_car_lights($Car1/Sprite)

	if (Util.rand_bool(10) && !can_change && car2_interruptable && !light_stop):pass
		#drive_car_back($Cars2)

	if can_change:
		change_lights(beat)

func change_lights(b:int) -> void:
	prev_change = b
	light_stop = !light_stop

	if light_stop:
		$Traffic/Sprite.play('to_red')
		change_interval = 20
	else:
		$Traffic/Sprite.play('to_green')
		change_interval = 30

		if car_waiting:
			pass #finish_car_lights($Car1/Sprite)
	
func countdown_start():
	if cur_can.get_parent() == null:
		#cur_can.atlas = 'res://assets/images/stages/philly-streets/effects/spraycan'
		#cur_can.playing = true
		#cur_can.symbol = 'can bounce off head'
		#$CharGroup.add_child(cur_can)
		#cur_can.animation_changed.connect(func():
		#	if cur_can.animation == 'hit':
		#		cur_can.offset = Vector2(-450, -70)
		#	else:
		#		cur_can.offset = Vector2(0, 0)
		#)
		#cur_can.sprite_frames = CAN
		cur_can.position = $SprayCanPile.position + Vector2(920, -150)
		#cur_can.animation_finished.connect(func(): cur_can.visible = cur_can.animation != 'fly')
	#cur_can.visible = false
	if Game.scene.story_mode:
		if Util.format_str(SONG.song) == 'darnell':
			UI.visible = false
			UI.pause_countdown = true
			boyfriend.play_anim('intro')
			Audio.play_music('darnellCanCutscene', false)

var cocked:bool = false
func good_note_hit(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	match note.type.replace('weekend-1-', ''):
		&'cockgun': 
			cocked = true
			boyfriend.play_anim('cock' if boyfriend.cur_char == 'pico' else 'pre-attack', true)
			boyfriend.special_anim = true
			Audio.play_sound('weekend/gun_prep')
		&'firegun': 
			if !cocked: 
				note_miss(note)
				return
			cocked = false
			if Util.rand_bool(90) and boyfriend.cur_char == 'pico':
				boyfriend.play_anim('intro')
				boyfriend.frame = 34
				boyfriend.pause()
		
				cur_can.play('hit')
				Audio.play_sound('weekend/bonk')
			else:
				boyfriend.play_anim('shoot' if boyfriend.cur_char == 'pico' else 'attack', true)
				boyfriend.special_anim = true
				
				Audio.play_sound('weekend/shots/'+ str(randi_range(1, 4)))
				cur_can.play('shoot')

var died_by_can:bool = false
func note_miss(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	if note.type.replace('weekend-1-', '') == 'firegun':
		Audio.play_sound('weekend/bonk')
		cur_can.play('hit')
		boyfriend.play_anim('shootMISS', true)
		boyfriend.special_anim = true
		await get_tree().create_timer(0.3).timeout
		UI.hp = 0
		died_by_can = true

func opponent_note_hit(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	match note.type.replace('weekend-1-', ''):
		'lightcan': 
			dad.play_anim('light', true)
			dad.special_anim = true
			Audio.play_sound('weekend/lighter')
		'kickcan' : 
			dad.play_anim('kick', true)
			dad.special_anim = true
			cur_can.visible = true
			cur_can.play('fly')
			Audio.play_sound('weekend/kickUp')
		'kneecan' : 
			dad.play_anim('knee', true)
			dad.special_anim = true
			Audio.play_sound('weekend/kickForward')

func game_over_start(scene):
	if died_by_can:
		died_by_can = false
		scene.we_dyin = scene.DEATH_TYPE.EXPLODE
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
