extends Node2D

signal focus_change(is_focused) # when you click on/off the game window

var TRANS = preload('res://game/objects/ui/transition.tscn') # always have it loaded for instantiating
var cur_trans

var persist = { # change this to a global script or something
	'prev_scene': null,
	'note_splash': null,
	'loaded_already': false,
	'week_list': ['test', 'tutorial', 'week1', 'week2', 'week3', 'week4', 'week5', 'week6', 'week7', 'weekend1'],
	'week_int': -1, 'week_diff': -1,
	'song_list': [],
	'deaths': 0
} 
var scene:Node2D = null:
	get: return get_tree().current_scene
	
var screen = [
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
]

# fix pause screen because it sets the paused of the tree as well
func _ready():
	set_mouse_visibility(false)
	focus_change.connect(focus_changed)

var just_pressed:bool = false
var is_full:bool = false

func _process(_delta):
	if Input.is_key_pressed(KEY_F6):
		if !just_pressed:
			var window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if !is_full else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(window_mode)
			is_full = !is_full
		just_pressed = true
	else: just_pressed = false

func _notification(what):
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_change.emit(true)
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		focus_change.emit(false)

var is_paused:bool = false:
	set(paus): 
		is_paused = paus
		get_tree().paused = is_paused
func focus_changed(is_focused:bool):
	if Prefs.auto_pause:
		Engine.max_fps = Prefs.fps if is_focused else 12 # no need to process shit if its paused
		Audio.process_mode = Node.PROCESS_MODE_ALWAYS if is_focused else Node.PROCESS_MODE_DISABLED
		if is_focused:
			if is_paused: is_paused = false
		else:
			if !get_tree().paused: is_paused = true

func center_obj(obj = null, axis:String = 'xy') -> void:
	if obj == null: return
	match axis:
		'x': obj.position.x = (screen[0] / 2) #- (obj_size.x / 2)
		'y': obj.position.y = (screen[1] / 2) #- (obj_size.y / 2)
		_: obj.position = Vector2(screen[0] / 2, screen[1] / 2)

func reset_scene() -> void:
	LuaHandler.remove_all()
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
		get_tree().paused = false
		
		cur_trans.on_finish = func():
			remove_child(cur_trans)
			cur_trans.queue_free()
		cur_trans.trans_in(1, true)
		
# call function on nodes or somethin
func call_func(to_call:String, args:Array[Variant] = []) -> void:
	if to_call.is_empty() or scene == null: return
	if scene.has_method(to_call):
		scene.callv(to_call, args)

func format_str(string:String = '') -> String:
	return string.to_lower().strip_edges().replace(' ', '-').replace('\'', '').replace(':', '')

func round_d(num:float, digit:int) -> float: # bowomp
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
	
func rand_bool(chance:float = 50.0) -> bool:
	return true if (randi() % 100) < chance else false

func remove_all(array:Array[Array], node) -> void:
	if node == null: node = scene
	for sub in array:
		for i in sub:
			node.remove_child(i)
			i.queue_free()
		sub.clear()
			
func get_key_from_byte(btye:int) -> String:
	var key:String = OS.get_keycode_string(btye)
	match key.to_lower():
		'space': key = ' '
		'period': key = '.'
		'bracketleft': key = '['
		'bracketright': key = ']'
		'colon': key = ':'
		'comma': key = ','
		'minus': key = '-'
		'parenleft': key = '('
		'parenright': key = ')'
		'slash': key = '/'
		'quote': key = '\''
		'quotedbl': key = '"'
	return key

func get_alias(antialiased:bool = true) -> CanvasItem.TextureFilter:
	return CanvasItem.TEXTURE_FILTER_LINEAR if antialiased else CanvasItem.TEXTURE_FILTER_NEAREST
	
func to_time(secs:float, is_milli:bool = true, show_ms:bool = false) -> String:
	if is_milli: secs = secs / 1000.0
	var time_part1:String = str(int(secs / 60)) + ":"
	var time_part2:int = int(secs) % 60
	if time_part2 < 10:
		time_part1 += "0"

	time_part1 += str(time_part2)
	if show_ms:
		time_part1 += "."
		time_part2 = int((secs - int(secs)) * 100);
		if time_part2 < 10:
			time_part1 += "0"
	
		time_part1 += str(time_part2)
	
	return time_part1

func set_mouse_visibility(visiblilty:bool = true) -> void:
	var vis = Input.MOUSE_MODE_VISIBLE if visiblilty else Input.MOUSE_MODE_HIDDEN
	Input.mouse_mode = vis
