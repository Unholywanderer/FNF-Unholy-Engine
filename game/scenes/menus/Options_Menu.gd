extends Node2D

var descriptions
var catagories:Array[String] = ['Gameplay', 'Visuals', 'Controls']
var lerp_points:Array = [-700, 0, 700]

# options that will be in each catagory
# pref name, type, if type is int/float [min_num, max_num], if type is array ['list', 'of', 'choices']
var gameplay = [
	['auto_play',        'bool'],
	['legacy_score',     'bool'],
	['ghost_tapping',    'array', ['on', 'off', 'insta-kill']],
	['scroll_speed',     'float', [0, 10], 0.01],
	['scroll_type',      'array', ['up', 'down', 'left', 'right', 'middle', 'split']],
	['center_strums',    'bool'],
	['hitsound',        'array', []],
	['hitsound_volume',   'int', [0, 200], 5],
	['offset',            'int', [-500, 500]],
	['epic_window',     'float', [15, 22.5], 0.1],
	['sick_window',     'float', [15, 45], 0.1],
	['good_window',     'float', [15, 90], 0.1],
	['bad_window' ,     'float', [15, 135], 0.1]
]
var visuals = [
	['fps',             'int', [0, 240], 10],
	['skip_transitions', 'bool'],
	['allow_rpc',      'bool'],
	['basic_play',     'bool'],
	['note_splashes', 'array', ['epics', 'both', 'none']],
	['splash_sprite', 'array', ['vis', 'base', 'base-pixel', 'haxe', 'forever']],
	['hold_splash',   'array', ['disabled', 'cover', 'full']],
	['behind_strums',  'bool'],
	['rating_cam',    'array', ['game', 'hud', 'none']],
	['auto_pause',     'bool'],
	['chart_grid',     'bool'],
	['deaf',           'bool'],
	['daniel',         'bool']
]
#var controls = []

var from_play:bool = false
var cur_option:int = 0
var sub_option:int = 0
var in_sub:bool = false
var cur_shit:AudioStreamPlayer

var main_text:Array[Alphabet]
var pref_list:Array[Alphabet]
func _ready():
	Discord.change_presence('Maining some Menus', 'Checkin some options')

	for shit in DirAccess.get_files_at('res://assets/sounds/hitsounds'):
		if !shit.ends_with('.ogg'): continue
		gameplay[6][2].append(shit.replace('.ogg', ''))

	var b = JSON.new()
	b.parse(FileAccess.open('res://assets/data/prefInfo.json', FileAccess.READ).get_as_text())
	descriptions = b.data
	for i in catagories.size():
		var item = catagories[i]
		var text = Alphabet.new(item)
		text.scale = Vector2(0.9, 0.9)
		$Header.add_child(text)
		text.position.y = $Header.size.y / 2.0 - (text.height / 2.0) + 3

		var head_size = $Header.size.x
		#if i == 0:
		text.position.x = head_size / 2.0 - (text.width / 2.0)
		#else:
		#	text.position.x = head_size + (text.width)
		main_text.append(text)
	$Description/Text.text = 'Choose a Catagory'
	update_scroll()

func _exit_tree() -> void: Audio.stop_all_sounds()
func _unhandled_key_input(_event:InputEvent) -> void:
	if in_sub:
		if Input.is_action_pressed('menu_up'): update_scroll(-1)
		if Input.is_action_pressed('menu_down'): update_scroll(1)

		var da_pref = pref_list[sub_option]
		if ['array', 'int', 'float'].has(da_pref.type):
			var update = da_pref.step
			if da_pref.type == 'float' and Input.is_key_pressed(KEY_CTRL): update *= 0.5
			if Input.is_action_pressed('menu_left'): da_pref.update_option(-update)
			if Input.is_action_pressed('menu_right'): da_pref.update_option(update)
		if da_pref.type == 'bool' and Input.is_action_just_pressed('accept'):
			da_pref.update_option()
		if Input.is_action_just_pressed('back'): show_main()
	else:
		if Input.is_action_just_pressed('menu_left'): update_scroll(-1)
		if Input.is_action_just_pressed('menu_right'): update_scroll(1)

		if Input.is_action_just_pressed('back'):
			Audio.play_sound('cancelMenu')
			if from_play:
				queue_free()
			else:
				Game.switch_scene('menus/main_menu')

		if Input.is_action_just_pressed("accept"):
			show_catagory(catagories[cur_option].to_lower())

func show_main() -> void:
	Audio.play_sound('cancelMenu')
	Audio.volume = 0.7

	for i in pref_list.size():
		var o = pref_list[i]
		o.lock.y = 60 + (75 * i)

	in_sub = false
	$Options/SelectBox.visible = false
	$Description/Text.text = 'Choose a Catagory'

func show_catagory(catagory:String) -> void:
	Audio.play_sound('confirmMenu')
	in_sub = true
	sub_option = 0
	if catagory != 'controls':
		update_scroll()
	else:
		Game.switch_scene('menus/options/change_keybinds')

var last_scroll:int
func update_scroll(diff:int = 0) -> void:
	var play_snd:bool = diff != 0

	if !in_sub:
		cur_option = wrapi(cur_option + diff, 0, main_text.size())
	else:
		sub_option = clampi(sub_option + diff, 0, pref_list.size() - 1)
		play_snd = (sub_option != last_scroll and play_snd)
		last_scroll = sub_option

	if play_snd: Audio.play_sound('scrollMenu')

	$Options/SelectBox.visible = in_sub
	if in_sub:
		$Description/Alert.visible = pref_list[sub_option].type == 'float'
		$Description/AlertShift.visible = ['float', 'int'].has(pref_list[sub_option].type)

		if sub_option - 3 >= 0 and sub_option + 3 <= pref_list.size() - 1:
			for i in pref_list.size():
				var o = pref_list[i]
				o.target_y = i - sub_option
				o.lock.y = 60 + (75 * (o.target_y + 3))

		Audio.volume = 0.15 if pref_list[sub_option].option == 'hitsound' else 0.7
		$Description/Text.text = pref_list[sub_option].description
		$Options/SelectBox.position.y = pref_list[sub_option].lock.y - 60
	else:
		for i in main_text.size():
			main_text[i].visible = i == cur_option

		while pref_list.size() > 0:
			$Options/List.remove_child(pref_list[0])
			pref_list[0].queue_free()
			pref_list.remove_at(0)

		var loops:int = 0
		if catagories[cur_option].to_lower() != 'controls':
			for pref in get(catagories[cur_option].to_lower()):
				var desc = descriptions[pref[0]] if descriptions.has(pref[0]) else 'Missing Description'
				var new_pref = Option.new(pref, desc)
				new_pref.is_menu = true
				new_pref.lock.y = 60 + (75 * loops)
				new_pref.target_y = loops

				$Options/List.add_child(new_pref)
				pref_list.append(new_pref)
				loops += 1


class Option extends Alphabet:
	var option:String = ''
	var description:String = 'nothing'
	var type:String = 'bool' # the option's type: int, bool, array n shit
	var check:Checkbox  # for bools
	var vis:Alphabet   # for not bools

	var step:float = 1.0
	var cur_op:int = 0
	var choices:Array = [] # if the option is an array, will hold all possible options
	var audio:AudioStreamPlayer

	var min_val:float = 0.0;  var max_val:float = 0.0
	var cur_val:float = 0.0

	func _init(option_array, info:String = 'nothin'):
		option = option_array[0]
		description = info
		type = option_array[1]
		text = option.capitalize()
		lock.x = Game.screen[0] / 2.0 - 500
		scale = Vector2(0.9, 0.9)
		if type != 'bool':
			vis = Alphabet.new('Nothing', false)
			add_child(vis)
			vis.position.x += 750

		if audio:
			add_child(audio)
		#color = Color.WHITE

		match type:
			'array':
				choices = option_array[2]
				cur_op = choices.find(str(Prefs.get(option)))
				vis.text = str(choices[cur_op]).capitalize()
			'int', 'float':
				min_val = option_array[2][0]
				max_val = option_array[2][1]
				if option_array.size() == 4: step = option_array[3]
				cur_val = Prefs.get(option)
				vis.text = str(cur_val)
			_:
				check = Checkbox.new()
				add_child(check)
				check.scale = Vector2(0.5, 0.5)
				check.offsets.x += 1350
				check.follow_spr = self
				check.checked = Prefs.get(option)

	# update the preference and the option text
	func update_option(diff:float = 0.0) -> void: # diff for arrays/nums
		if audio: audio.stop()
		match type:
			'array':
				cur_op = wrapi(cur_op + round(diff), 0, choices.size())
				Prefs.set(option, choices[cur_op].to_lower())
				if option == 'hitsound':
					audio = Audio.return_sound('hitsounds/'+ choices[cur_op])
					audio.play()
			'int', 'float':
				if Input.is_key_pressed(KEY_SHIFT): diff *= 10
				cur_val = snapped(clamp(cur_val + diff, min_val, max_val), 0.001)
				Prefs.set(option, cur_val)
			'bool':
				var a_bool = Prefs.get(option)
				Prefs.set(option, !a_bool)
				check.checked = !a_bool
		if type != 'bool':
			vis.text = str(Prefs.get(option)).capitalize()
		Prefs.save_prefs()
