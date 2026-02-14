## Class for stages. Make sure that if you're adding one, it extends this script.
class_name StageBase extends Node2D

@export var default_zoom:float = 0.8
@export var cam_speed:float = 4.0

## Current scene the stage is on, most likely Play_Scene
var Main:
	get: return Game.scene
var UI:
	get: return Game.scene.ui
var SONG:
	get: return Game.scene.SONG

var cur_beat:int:
	get: return int(Conductor.cur_beat)
var cur_step:int:
	get: return int(Conductor.cur_step)
var cur_section:int:
	get: return Conductor.cur_section

var boyfriend:Character:
	get: return Game.scene.get('boyfriend')
var dad:Character:
	get: return Game.scene.get('dad')
var gf:Character:
	get: return Game.scene.get('gf')

# initial positions the characters will take
@export var bf_pos:Vector2 = Vector2(770, 100)
@export var dad_pos:Vector2 = Vector2(100, 100)
@export var gf_pos:Vector2 = Vector2(550, 100)

# added onto the character's camera position
@export var bf_cam_offset:Vector2 = Vector2(0, 0)
@export var dad_cam_offset:Vector2 = Vector2(0, 0)
@export var gf_cam_offset:Vector2 = Vector2(0, 0)

# song functions for signals
func post_ready() -> void: pass
func countdown_start() -> void: pass
@warning_ignore("unused_parameter")
func countdown_tick(tick:int) -> void: pass
func song_start() -> void: pass
func song_end() -> void: pass

@warning_ignore("unused_parameter")
func beat_hit(beat:int) -> void: pass
@warning_ignore("unused_parameter")
func step_hit(step:int) -> void: pass
@warning_ignore("unused_parameter")
func section_hit(section:int) -> void: pass

@warning_ignore("unused_parameter")
func good_note_hit(note:Note) -> void: pass
@warning_ignore("unused_parameter")
func opponent_note_hit(note:Note) -> void: pass
@warning_ignore("unused_parameter")
func note_miss(note:Note) -> void: pass
@warning_ignore("unused_parameter")
func ghost_tap(dir:int) -> void: pass
@warning_ignore("unused_parameter")
func event_hit(event:EventData) -> void: pass

# bf died
func game_over_start() -> void: pass
func game_over_idle() -> void: pass
@warning_ignore("unused_parameter")
func game_over_confirm(is_retry:bool) -> void: pass
