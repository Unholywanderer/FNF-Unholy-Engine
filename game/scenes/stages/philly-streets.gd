extends StageBase

var cur_can:AnimatedSprite2D = AnimatedSprite2D.new()
var CAN = load('res://assets/images/stages/philly-streets/effects/spraycanFULL.res')
func _ready() -> void:
	if SONG.player1.contains('pico'):
		THIS.DIE = load('res://game/scenes/game_over-pico.tscn')
	if !Game.persist.loaded_already:
		Game.persist.loaded_already = true
		ResourceLoader.load('res://assets/images/characters/pico/ex_death/blood.res')
		ResourceLoader.load('res://assets/images/characters/pico/ex_death/smoke.res')

	default_zoom = 0.77
	bf_pos = Vector2(1800, 450)
	dad_pos = Vector2(700, 445)
	gf_pos = Vector2(1200, 430)
	
	bf_cam_offset.x = -200
	dad_cam_offset.x = 200
	THIS.cam.position = Vector2(400, 490)
	

func countdown_start():
	if cur_can.get_parent() == null:
		$CharGroup.add_child(cur_can)
		cur_can.animation_changed.connect(func():
			if cur_can.animation == 'hit':
				cur_can.offset = Vector2(-450, -70)
			else:
				cur_can.offset = Vector2(0, 0)
		)
		cur_can.sprite_frames = CAN
		cur_can.position = $SprayCanPile.position + Vector2(920, -150)
		cur_can.animation_finished.connect(func(): cur_can.visible = cur_can.animation != 'fly')
	cur_can.visible = false
	if Game.scene.story_mode:
		if Game.format_str(SONG.song) == 'darnell':
			UI.visible = false
			UI.pause_countdown = true
			boyfriend.play_anim('intro')
			Audio.play_music('darnellCanCutscene', false)

var cocked:bool = false
func good_note_hit(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	match note.type.replace('weekend-1-', ''):
		'cockgun': 
			cocked = true
			boyfriend.play_anim('cock' if boyfriend.cur_char == 'pico' else 'pre-attack', true)
			boyfriend.special_anim = true
			Audio.play_sound('weekend/gun_prep')
		'firegun': 
			if !cocked: 
				note_miss(note)
				return
			cocked = false
			if Game.rand_bool(90) and boyfriend.cur_char == 'pico':
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
