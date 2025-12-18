extends Node2D

signal focus_change(is_focused) # when you click on/off the game window

const week_list:PackedStringArray = [
	'test', 'tutorial', 'week1', 'week2', 'week3', 'week4', 'week5', 'week6', 'week7', 'weekend1'
]
const stage_list:PackedStringArray = [
	'stage', 'spooky', 'philly', 'limo', 'mall', 'mall-evil', 'school', 'school-evil', 'tank',
	'philly-streets', 'philly-blazin',
	'stage-erect', 'spooky-erect', 'philly-erect', 'limo-erect', 'mall-erect'
]

# always have it loaded for instantiating
var TRANS:PackedScene = preload('res://game/objects/ui/transition.tscn')
var cur_trans:CanvasLayer

## Dictionary that holds variables/resources that will NOT reset when changing scenes
var persist:Dictionary[String, Variant] = { # change this to a global script or something
	'prev_scene': null,
	'scoring': null,
	'song_list': [],
	'deaths': 0,
	'note_splash': null,
	'note_skin': null,
	'week_int': -1,
	'week_diff': -1,
}

var main_window:Window
var scene:Node2D:
	get: return get_tree().current_scene

var screen:Array[float] = [
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
]
var fullscreen:bool = false:
	set(f):
		fullscreen = f
		var window_mode = Window.MODE_EXCLUSIVE_FULLSCREEN if f else Window.MODE_WINDOWED
		main_window.mode = window_mode

# fix pause screen because it sets the paused of the tree as well
var exe_path:String = ''

func _ready():
	exe_path = OS.get_executable_path()
	var exe_name := exe_path.split('/', false)[-1]
	exe_path = exe_path.replace(exe_name, '')
	if !OS.is_debug_build():
		var folders_to_make = {
			'data' = ['characters', 'events', 'players', 'scripts', 'skins', 'weeks'],
			'fonts' = [],
			'images' = ['characters', 'credits', 'freeplay', 'icons', 'main_menu',
				'results_screen', 'stages', 'story_mode', 'ui'],
			'music' = [],
			'songs' = [],
			'sounds' = [],
			'videos' = []
		}

		if !DirAccess.dir_exists_absolute(exe_path +'mods'):
			DirAccess.make_dir_absolute(exe_path +'mods')
			for i:String in folders_to_make.keys():
				DirAccess.make_dir_absolute(exe_path +'mods/'+ i)
				if !folders_to_make[i].is_empty():
					for sub:String in folders_to_make[i]:
						DirAccess.make_dir_absolute(exe_path +'mods/'+ i +'/'+ sub)
			#var txt_note = FileAccess.open(exe_path +'mods/', FileAccess.WRITE)

	main_window = get_window()
	# this is cool but its funky
	#main_window.focus_entered.connect(_focus_in)
	#main_window.focus_exited.connect(_focus_out)
	set_mouse_visibility(false)

func _notification(what:int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN: _focus_in()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: _focus_out()

var just_pressed:bool = false
func _unhandled_input(event:InputEvent) -> void:
	if Input.is_key_pressed(KEY_F6): # i kinda like how janky this is when you hold the key
		just_pressed = event.is_released()
		if !just_pressed:
			fullscreen = !fullscreen

var is_paused:bool = false:
	set(paus):
		is_paused = paus
		get_tree().paused = is_paused

func _focus_in():
	if !Prefs.auto_pause or get_viewport().gui_get_focus_owner(): return
	focus_change.emit(true)
	Audio.process_mode = Node.PROCESS_MODE_ALWAYS
	if is_paused: is_paused = false

func _focus_out():
	if !Prefs.auto_pause or get_viewport().gui_get_focus_owner(): return
	focus_change.emit(false)
	Audio.process_mode = Node.PROCESS_MODE_DISABLED
	if !get_tree().paused: is_paused = true

func reset_scene() -> void:
	LuaHandler.remove_all()
	get_tree().paused = false
	get_tree().reload_current_scene()

func switch_scene(to_scene, skip_trans:bool = false) -> void:
	if ((to_scene is not String) and (to_scene is not PackedScene)) or to_scene == null:
		printerr('Switch Scene: new scene is invalid')
		return

	LuaHandler.remove_all()
	Audio.sync_conductor = false
	if scene: persist.prev_scene = scene.name

	set_mouse_visibility(false)
	if Prefs.skip_transitions: skip_trans = true

	persist.deaths = 0
	print('LEAVING '+ scene.name)
	if to_scene is String: # scene is a string, make it into a packed scene
		to_scene = to_scene.to_lower()
		if to_scene == 'play_scene' and Prefs.basic_play: to_scene += '_simple'
		if FileAccess.file_exists('res://assets/data/scripts/custom_scenes/'+ to_scene +'.lua'):
			print('we lua-ing')
			to_scene = 'custom_scene'

		if ResourceLoader.exists('res://game/scenes/'+ to_scene +'.tscn'):
			to_scene = load('res://game/scenes/'+ to_scene +'.tscn')
		else:
			Alert.make_alert('Switch Scene: "'+ to_scene +'" doesn\'t exist\nreloading')
			return reset_scene()

	var new_scene:PackedScene = to_scene

	if cur_trans and cur_trans.in_progress: # cancel previous trans, if exists
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
