extends StageBase

var def_index
func _ready() -> void:
	THIS.DIE = load('res://game/scenes/game_over-pico.tscn')
	default_zoom = 0.75
	bf_pos = Vector2(850, -550)
	dad_pos = Vector2(-450, -550)
	gf_pos = Vector2(350, 100)

	dad_cam_offset = Vector2(350, 250)
	UI.health_bar.rotation = deg_to_rad(90)
	UI.health_bar.scale = Vector2(0.90, 0.90)
	UI.health_bar.position = Vector2(Game.screen[0] - 80, (Game.screen[1] / 2.0) - 280)
	UI.mark.rotation = -UI.health_bar.rotation
	UI.mark.position -= Vector2(15, -25)
	UI.time_bar.position.x = (Game.screen[0] / 2.0) - 400
	UI.icon_p2.flip_h = true
	UI.get_group('opponent').visible = false
	UI.get_group('player').position.x = Game.screen[0] / 2.0 - 180

func countdown_start():
	def_index = boyfriend.get_index()
	if Prefs.rating_cam == 'game':
		THIS.Judge.rating_pos = boyfriend.position + Vector2(650, 250)
		THIS.Judge.combo_pos = boyfriend.position + Vector2(550, 350)

func _process(delta):
	UI.icon_p1.position.y = 0
	UI.icon_p2.position.y = 0

	pass
	#var lol = ['punchHigh1', 'punchLow1', 'punchHigh2', 'punchLow2']
	#var an = lol.pick_random()
	#dad.play_anim(an, true)
	#THIS.move_child(dad, boyfriend.get_index() + 1)
	#boyfriend.play_anim('hit'+ an.replace('punch', '').replace('1', '').replace('2', ''), true)
	#Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.1)
	#UI.hp -= 10 * delta

func good_note_hit(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	pico_anim(note.type.replace('weekend-1-', ''))
	darnell_anim(note.type.replace('weekend-1-', ''))

func opponent_note_hit(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	pico_anim(note.type.replace('weekend-1-', ''), true)
	darnell_anim(note.type.replace('weekend-1-', ''), true)

func note_miss(note:Note):
	if !note.type.begins_with('weekend-1'): return
	pico_anim(note.type.replace('weekend-1-', ''), true)
	darnell_anim(note.type.replace('weekend-1-', ''), true)

func ghost_tap(_dir):
	if Prefs.ghost_tapping == 'insta-kill' or UI.hp <= 5:
		darnell_anim('punchlow', true)
	else:
		pico_anim('punchhigh')
		dad.play_anim(('block' if Util.rand_bool(50) else 'dodge'), true)

var alt:bool = false
var alt_dad:bool = false
var front_anims:Array = ['punchHigh1', 'punchHigh2', 'punchLow1', 'punchLow2', 'uppercut', 'fakeout']

func pico_anim(note:String, missed:bool = false):
	boyfriend.can_dance = false
	if missed:
		if note.contains('high') or note.contains('low'):
			boyfriend.play_anim('hit'+ ('High' if note.contains('high') else 'Low'), true)
		match note:
			'hitspin': boyfriend.play_anim('spinOut', true)
			'picouppercutprep': boyfriend.play_anim('uppercutPrep', true)
			'picouppercut': boyfriend.play_anim('uppercut', true)
			'darnelluppercutprep': boyfriend.play_anim('idle', true)
			'darnelluppercut':
				boyfriend.play_anim('uppercutHit', true)
				boyfriend.flip_h = true
			'idle': boyfriend.play_anim('idle', true)
			'fakeout': boyfriend.play_anim('fakeout', true)
			'taunt': if boyfriend.animation == 'fakeout': boyfriend.play_anim('taunt', true)
			'tauntforce': boyfriend.play_anim('taunt', true)
			'reversefakeout': boyfriend.play_anim('idle', true)
	else:
		match note:
			'punchlow', 'punchlowblocked', 'punchlowdodged', 'punchlowspin':
				boyfriend.play_anim('punchLow'+ alter('alt'), true)
			'punchhigh', 'punchhighblocked', 'punchhighdodge', 'punchhighspin':
				boyfriend.play_anim('punchHigh'+ alter('alt'), true)
			'blockhigh', 'blocklow', 'blockspin':
				boyfriend.play_anim('block', true)
			'dodgehigh', 'dodgelow', 'dodgespin':
				boyfriend.play_anim('dodge', true)
			'hithigh': boyfriend.play_anim('hitHigh', true)
			'hitlow' : boyfriend.play_anim('hitLow', true)
			'hitspin': boyfriend.play_anim('spinOut', true)
			'picouppercutprep': boyfriend.play_anim('uppercutPrep', true)
			'picouppercut': boyfriend.play_anim('uppercut', true)
			'darnelluppercutprep': boyfriend.play_anim('idle', true)
			'darnelluppercut':
				boyfriend.play_anim('uppercutHit', true)
				boyfriend.flip_h = true
			'idle': boyfriend.play_anim('idle', true)
			'fakeout': boyfriend.play_anim('fakeout', true)
			'taunt': if boyfriend.animation == 'fakeout': boyfriend.play_anim('taunt', true)
			'tauntforce': boyfriend.play_anim('taunt', true)
			'reversefakeout': boyfriend.play_anim('idle', true)
	boyfriend.flip_h = (boyfriend.animation == 'uppercutHit') # i cant be assed
	if front_anims.has(boyfriend.animation):
		$CharGroup.move_child(boyfriend, 2)
	else:
		$CharGroup.move_child(boyfriend, 1)

func darnell_anim(note, missed:bool = false):
	dad.can_dance = false

	if missed:
		if UI.hp <= 5:
			dad.play_anim('punchLow'+ alter('alt_dad'))
			return

		if note.contains('high') or note.contains('low'):
			dad.play_anim('punch'+ ('High' if note.contains('high') else 'Low') + alter('alt_dad'), true)
		match note:
			'picouppercutprep': dad.play_anim('hitHigh', true)
			'picouppercut': dad.play_anim('dodge', true)

			'darnelluppercutprep': dad.play_anim('uppercutPrep', true)
			'darnelluppercut': dad.play_anim('uppercut', true)
			'idle': dad.play_anim('idle', true)
			'fakeout': dad.play_anim('cringe', true)
			'taunt': dad.play_anim('pissed', true)
			'tauntforce': dad.play_anim('pissed', true)

			#case "weekend-1-picouppercutprep":
			#	playHitHighAnim();
			#	cantUppercut = true;
			#case "weekend-1-taunt":
			#	playPissedConditionalAnim();
	else:
		match note:
			'punchlow': dad.play_anim('hitLow', true)
			'punchlowblocked': dad.play_anim('block', true)
			'punchlowdodged': dad.play_anim('dodge', true)
			'punchlowspin': dad.play_anim('spinOut', true)

			'punchhigh': dad.play_anim('hitHigh', true)
			'punchhighblocked': dad.play_anim('block', true)
			'punchhighdodged': dad.play_anim('dodge', true)
			'punchhighspin': dad.play_anim('spinOut', true)

			'blockhigh': dad.play_anim('punchHigh'+ alter('alt_dad'), true)
			'blocklow': dad.play_anim('punchLow'+ alter('alt_dad'), true)
			'blockspin': dad.play_anim('punchHigh'+ alter('alt_dad'), true)

			'dodgehigh': dad.play_anim('punchHigh'+ alter('alt_dad'), true)
			'dodgelow': dad.play_anim('punchLow'+ alter('alt_dad'), true)
			'dodgespin': dad.play_anim('punchHigh'+ alter('alt_dad'), true)

			'hithigh': dad.play_anim('punchHigh'+ alter('alt_dad'), true)
			'hitlow': dad.play_anim('punchLow'+ alter('alt_dad'), true)
			'hitspin': dad.play_anim('punchHigh'+ alter('alt_dad'), true)

			'picouppercutprep': pass
			'picouppercut': dad.play_anim('uppercutHit', true)

			'darnelluppercutprep': dad.play_anim('uppercutPrep', true)
			'darnelluppercut': dad.play_anim('uppercut', true)

			'idle': dad.play_anim('idle')
			'fakeout': dad.play_anim('cringe', true)
			'taunt': dad.play_anim('pissed', true)
			'tauntforce': dad.play_anim('pissed', true)
			'reversefakeout': dad.play_anim('fakeout', true)
	if front_anims.has(dad.animation):
		$CharGroup.move_child(dad, 2)
	else:
		$CharGroup.move_child(dad, 1)



func alter(a:String):
	set(a, !get(a))
	return '1' if get(a) else '2'

func game_over_start(scene):
	scene.we_dyin = scene.DEATH_TYPE.PUNCH
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
