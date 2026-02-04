extends Node2D

var _saved_prefs:ConfigFile = ConfigFile.new()
var _default_prefs:Dictionary = {}
var _LIST:Array[Dictionary] = []
## GAMEPLAY ##
var auto_play:bool = false
var ghost_tapping:String = 'on'
var scroll_speed:float = 0.0
var scroll_type:String = 'up'
var center_strums:bool = false
var legacy_score:bool = false

var saved_volume:int = 10
var hitsound:String = 'normal'
var hitsound_volume:int = 0 # will be divided by 100
var offset:int = 0

var epic_window:float = 22.5
var sick_window:float = 45.0
var good_window:float = 90.0
var bad_window:float = 135.0
var safe_zone:float = 166.0

## VISUALS ##
var fps:int = 60:
	set(new): fps = new; Engine.max_fps = fps

var auto_pause:bool = true
var skip_transitions:bool = false
var basic_play:bool = false
var allow_rpc:bool = true:
	set(allow):
		allow_rpc = allow
		Discord.update(false, !allow)

var judgement_pos:Dictionary = {'game': [0, -40, -150, 70], 'hud': [580, 300, 420, 420]}

var note_splashes:String = 'both'
var splash_sprite:String = 'vis'
var hold_splash:String = 'cover/splash'

var behind_strums:bool = false
var rating_cam:String = 'game'
var femboy:bool = false

var daniel:bool = false: # if you switch too much, it'll break lol
	set(dani):
		daniel = dani
		Discord.update(true)

## KEYBINDS ##
var note_keys:Array = [
	['A', 'S', 'W', 'D'], ['Left', 'Down', 'Up', 'Right']
	# keybinds for note_left, note_down, note_up, note_right
]
var ui_keys:Array = [
	[['0', '+', '-'], ['', '', '']], # mute, volume up, volume down
	[['A', 'S', 'W', 'D'], ['Left', 'Down', 'Up', 'Right']] # menu navigation
]

func _ready():
	Discord.init_discord()
	update_list()
	for i in _LIST:
		_default_prefs.set(i.name, get(i.name))
	check_prefs()
	set_keybinds()
	DebugInfo.volume = saved_volume

func set_keybinds() -> void:
	var key_names:Array[String] = ['note_left', 'note_down', 'note_up', 'note_right']

	for i in key_names.size():
		var key:String = key_names[i]
		if InputMap.has_action(key):
			InputMap.action_erase_events(key)
		else:
			InputMap.add_action(key)

		var new_bind:Array[InputEventKey] = [InputEventKey.new(), InputEventKey.new()]
		for k in 2:
			new_bind[k].set_keycode(OS.find_keycode_from_string(note_keys[k][i]))
		InputMap.action_add_event(key, new_bind[0])
		InputMap.action_add_event(key, new_bind[1])

	print('updated keybinds')

func update_list() -> void:
	_LIST = get_script().get_script_property_list()
	for i:int in 4: _LIST.remove_at(0)
	# remove "Prefs.gd" and the variables "_saved_prefs", "_default_prefs", and "_LIST"
	#for i in _LIST: print(i.name)

func save_prefs() -> void:
	if _saved_prefs == null:
		printerr('CONFIG FILE is NOT loaded, couldn\'t save')
		return

	for i in _LIST:
		_saved_prefs.set_value('Preferences', i.name, get(i.name))

	_saved_prefs.save('user://prefs.cfg')
	#set_keybinds()
	print('Saved Preferences')

func load_prefs() -> ConfigFile:
	var saved_cfg = ConfigFile.new()
	saved_cfg.load('user://prefs.cfg')
	if saved_cfg.has_section('Preferences'):
		for pref in _LIST:
			set(pref.name, saved_cfg.get_value('Preferences', pref.name, null))
	return saved_cfg

func check_prefs():
	var config_exists = FileAccess.file_exists('user://prefs.cfg')

	if config_exists:
		var prefs_changed:bool = false
		_saved_prefs.load('user://prefs.cfg')
		for pref in _LIST:
			if !_saved_prefs.has_section_key('Preferences', pref.name):
				prefs_changed = true
				_saved_prefs.set_value('Preferences', pref.name, get(pref.name))
		if prefs_changed: # if a pref was added, resave the cfg file
			print('prefs changed, updating')
			_saved_prefs.save('user://prefs.cfg')

		_saved_prefs = load_prefs()
	else:
		save_prefs()
