extends Node2D

@onready var DJ:AnimateSymbol = $DJ
func _ready() -> void:
	Audio.play_music('freeplayRandom')
	Audio.sync_conductor = true
	Conductor.reset_beats()
	Conductor.bpm = 145
	Conductor.beat_hit.connect(beat_hit)

	DJ.add_anim_by_frames('fall-in', [0, 16])
	DJ.add_anim_by_frames('idle', [17, 29])
	DJ.add_anim_by_frames('confirm', [60, 89])
	DJ.add_anim_by_frames('yeah', [90, 150])
	DJ.add_anim_by_frames('oops', [151, 312])
	DJ.add_anim_by_frames('dad', [324, 460])
	DJ.add_anim_by_frames('tv', [532, 702])
	DJ.add_anim_by_frames('hop-down', [703, 730])
	DJ.add_anim_by_frames('unlock', [746, 806])
	DJ.play_anim('fall-in', true)
	DJ.finished.connect(func():
		if DJ.cur_anim != 'idle':
			DJ.play_anim('idle', true)
	)

func beat_hit(beat:int) -> void:
	if beat % 2 == 0 and DJ.cur_anim == 'idle':
		DJ.play_anim('idle')


func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed(&"back"):
		Game.switch_scene('menus/freeplay_classic')
