extends Node2D

signal focus_change(is_focused) # when you click on/off the game window

var TRANS = preload('res://game/objects/ui/transition.tscn') # always have it loaded for instantiating
var cur_trans

var persist = { # change this to a global script or something
	'scoring': null,
	'prev_scene': null,
	'note_splash': null,
	'loaded_already': false,
	'week_list': ['test', 'tutorial', 'week1', 'week2', 'week3', 'week4', 'week5', 'week6', 'week7', 'weekend1'],
	'stage_list': [
		'stage', 'spooky', 'philly', 'limo', 'mall', 'mall-evil', 'school', 'school-evil', 'tank', 'philly-streets', 'philly-blazin',
		'stage-erect', 'spooky-erect', 'philly-erect', 'limo-erect', 'mall-erect'
	],
	'week_int': -1, 'week_diff': -1,
	'song_list': [],
	'deaths': 0
}

var main_window:Window
var scene:Node2D = null:
	get: return get_tree().current_scene

var screen = [
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
]
var fullscreen = false:
	set(f): 
		fullscreen = f
		var window_mode = Window.MODE_EXCLUSIVE_FULLSCREEN if f else Window.MODE_WINDOWED
		main_window.mode = window_mode

# fix pause screen because it sets the paused of the tree as well
func _ready():
	main_window = get_window()
	# this is cool but its funky
	main_window.focus_entered.connect(_focus_in)
	main_window.focus_exited.connect(_focus_out)
	set_mouse_visibility(false)

var just_pressed:bool = false
func  _unhandled_input(event:InputEvent) -> void:
	if Input.is_key_pressed(KEY_F6): # i kinda like how janky this is when you hold the key
		just_pressed = event.is_released()
		if !just_pressed:
			fullscreen = !fullscreen

var is_paused:bool = false:
	set(paus): 
		is_paused = paus
		get_tree().paused = is_paused
		
func _focus_in():
	focus_change.emit(true)
	if !Prefs.auto_pause: return
	Audio.process_mode = Node.PROCESS_MODE_ALWAYS
	if is_paused: is_paused = false

func _focus_out():
	focus_change.emit(false)
	if !Prefs.auto_pause: return
	Audio.process_mode = Node.PROCESS_MODE_DISABLED
	if !get_tree().paused: is_paused = true

func reset_scene() -> void:
	LuaHandler.remove_all()
	get_tree().paused = false
	get_tree().reload_current_scene()

func switch_scene(to_scene, skip_trans:bool = false) -> void:
	LuaHandler.remove_all()
	Audio.sync_conductor = false
	persist.loaded_already = false
	persist.prev_scene = scene.name
	if ((to_scene is not String) and (to_scene is not PackedScene)) or to_scene == null:
		printerr('Switch Scene: new scene is invalid')
		return
	
	set_mouse_visibility(false)
	if Prefs.skip_transitions: skip_trans = true
	
	persist.deaths = 0
	print('LEAVING '+ scene.name)
	if to_scene is String: # scene is a string, make it into a packed scene
		to_scene = to_scene.to_lower()
		if to_scene == 'play_scene' and Prefs.basic_play: to_scene += '_simple'
		if ResourceLoader.exists('res://game/scenes/'+ to_scene +'.tscn', 'PackedScene'):
			to_scene = load('res://game/scenes/'+ to_scene +'.tscn')
		else:
			printerr('Switch Scene: "'+ to_scene +'" doesn\'t exist, reloading')
			return reset_scene()
	
	var new_scene:PackedScene = to_scene

	if cur_trans != null and cur_trans.in_progress: # cancel previous trans, if exists
		remove_child(cur_trans)
		cur_trans.cancel()
		get_tree().paused = false
		
	if skip_trans:
		get_tree().change_scene_to_packed(new_scene)
	else:
		get_tree().paused = true
		cur_trans = TRANS.instantiate()
		add_child(cur_trans)
		await cur_trans.trans_out(0.7)

		get_tree().change_scene_to_packed(new_scene)
		get_tree().paused = is_paused
		
		cur_trans.on_finish = func():
			remove_child(cur_trans)
			cur_trans.queue_free()
		cur_trans.trans_in(1, true)

# call function on nodes or somethin
func call_func(to_call:String, args:Array[Variant] = []) -> void:
	if to_call.is_empty() or scene == null: return
	if scene.has_method(to_call):
		scene.callv(to_call, args)

func set_mouse_visibility(visiblilty:bool = true) -> void:
	var vis = Input.MOUSE_MODE_VISIBLE if visiblilty else Input.MOUSE_MODE_HIDDEN
	Input.mouse_mode = vis
