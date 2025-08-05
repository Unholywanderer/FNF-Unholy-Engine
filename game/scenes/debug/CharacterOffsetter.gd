extends Node2D

var character:Character
var shadow:Character
var char_json:Dictionary = {}

var anim_list:Array[Label] = []
var offsets:Dictionary[String, Array] = {}
var flipped:Dictionary[String, bool] = {}
var cur_cam_offset:Array[int] = [0, 0]
var cur_pos_offset:Array[int] = [0, 0]

var icon_list:PackedStringArray = []

var char_list:PackedStringArray = []
var cur_char:String = ''
var cur_anim:String = ''
var selected_id:int = 0:
	set(new_id):
		if new_id < anim_list.size():
			if selected_id < anim_list.size():
				anim_list[selected_id].modulate = Color.WHITE  # if this is greater than the new char's anim list, crash
			anim_list[new_id].modulate = Color.YELLOW
			cur_anim = char_json.animations[new_id].name
		selected_id = new_id

		character.play(cur_anim)
		var got:Array = offsets.get(cur_anim, [0, 0])
		character.offset = Vector2(got[0], got[1])
		character.flip_h = flipped.get(cur_anim, false)

		var doop:Dictionary = char_json.animations[selected_id]
		ANIM('Name').text = doop.name
		ANIM('Prefix').text = doop.prefix
		ANIM('Frames').text = Util.array_to_str(doop.frames).replace(' ', '').replace('.0', '')
		ANIM('Framerate').value = doop.framerate
		ANIM('Loop').button_pressed = doop.loop
		ANIM('Flip/X').button_pressed = doop.get('flip_x', false)
		ANIM('Flip/Y').button_pressed = doop.get('flip_y', false)

@onready var _ui = $UILayer
func _ready() -> void:
	Prefs.auto_pause = false
	Game.set_mouse_visibility()
	Audio.play_music('artisticExpression')

	shadow = Character.new(Vector2.ZERO, 'bf-dead', true)
	add_child(shadow)
	shadow.modulate = Color(0.3, 0.3, 0.3, 0.6)

	character = Character.new(Vector2.ZERO, 'bf-dead', true) # load a random fuckass character
	character.debug = true
	add_child(character)
	move_child(character, 2)
	change_char('bf') # then load bf so the position isnt fucked

	move_child(shadow, character.get_index() - 1)

	MAIN('CharacterSelect').get_popup().connect("id_pressed", func(id:int): change_char(char_list[id]))
	MAIN('IconSelect').get_popup().connect("id_pressed", func(id:int): change_icon(icon_list[id]))
	MAIN('Shadow/AnimSelect').get_popup().connect("id_pressed", shadow_anim_change)

	%Icon.default_scale = 0.7

	var thing_change = func(_val, thing_name:String): # we dont use the '_val' for this
		var new_vals:Array[int]
		new_vals.assign([MAIN(thing_name +'/X').value, MAIN(thing_name +'/Y').value])
		match thing_name:
			'Cam':
				character.focus_offsets -= Vector2(cur_cam_offset[0], cur_cam_offset[1])
				cur_cam_offset = new_vals
				character.focus_offsets += Vector2(cur_cam_offset[0], cur_cam_offset[1])
				$Point.position = character.get_cam_pos()
			'Pos':
				character.position -= Vector2(cur_pos_offset[0], cur_pos_offset[1])
				cur_pos_offset = new_vals
				character.position += Vector2(cur_pos_offset[0], cur_pos_offset[1])

	for i in ['Pos', 'Cam']:
		MAIN(i +'/X').connect('value_changed', thing_change.bind(i))
		MAIN(i +'/Y').connect('value_changed', thing_change.bind(i))

	MAIN('Anti').connect('toggled', func(tog:bool):
		character.antialiasing = tog
		shadow.antialiasing = tog
	)
	$UILayer/Reset.pressed.connect(func():
		var heh = cur_char
		cur_char = ''
		change_char(heh)
	)
	$Cam.position = get_viewport_rect().size / 2.0

	var grab:PackedStringArray = FileAccess.get_file_as_string('res://assets/data/order.txt').split(',')
	grab.append_array(ResourceLoader.list_directory('res://assets/data/characters'))
	for i in grab:
		i = i.replace('.json', '')
		if !char_list.has(i):
			char_list.append(i)
			MAIN('CharacterSelect').get_popup().add_item(i)

	for i in ResourceLoader.list_directory('res://assets/images/icons'):
		if !i.ends_with('.png'): continue
		i = i.replace('.png', '')
		if !icon_list.has(i):
			icon_list.append(i)
			MAIN('IconSelect').get_popup().add_item(i)

func _process(delta:float) -> void:
	if MAIN('Cam/Lock').button_pressed:
		$Cam.position = $Point.position
	$Backdrop.scale = Vector2.ONE / $Cam.zoom
	$Backdrop.position = $Cam.position

	character.speed_scale = $UILayer/Anim/AnimSpeed.value
	var sc:float = MAIN('ScaleBox').value
	character.scale = Vector2(sc, sc)
	shadow.scale = character.scale

	DATA('Anim').text = cur_anim
	DATA('Offset').text = str(offsets.get(cur_anim, '[No Offsets]'))
	DATA('Frame').text = 'Frame\n'+ str(character.frame) +' / '+ str(character.sprite_frames.get_frame_count(character.animation) - 1)

var press_time:float = 0.0
func _unhandled_input(event:InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and !event.is_released():
		get_viewport().gui_release_focus()
	if get_viewport().gui_get_focus_owner() != null: return

	if event is InputEventMouse: return

	if event.is_action_pressed('back'):
		Prefs.auto_pause = true
		Game.switch_scene('menus/Main_Menu')

	if event.is_pressed(): press_time += get_process_delta_time()
	if event.is_released(): press_time = 0
	if event is not InputEventKey or (event.is_pressed() and press_time < 0.01): return
	var ctrl:bool = Input.is_key_pressed(KEY_CTRL)
	var shift:bool = Input.is_key_pressed(KEY_SHIFT)

	var replay_anim:bool = false
	match event.keycode:
		## CAMERA ZOOM
		KEY_U: $Cam.zoom -= Vector2(0.01, 0.01)
		KEY_O: $Cam.zoom += Vector2(0.01, 0.01)
		## CAMERA MOVE
		KEY_J: $Cam.position.x -= 5 * (5 if shift else 1)
		KEY_L: $Cam.position.x += 5 * (5 if shift else 1)
		KEY_I: $Cam.position.y -= 5 * (5 if shift else 1)
		KEY_K: $Cam.position.y += 5 * (5 if shift else 1)

		KEY_W: selected_id = wrapi(selected_id - 1, 0, anim_list.size())
		KEY_S: selected_id = wrapi(selected_id + 1, 0, anim_list.size())
		KEY_Q, KEY_E:
			character.pause()
			character.frame += 1 if event.keycode == KEY_E else -1

		## CHARACTER OFFSETTING
		KEY_LEFT : offsets[cur_anim][0] -= (1 if !shift else 10); replay_anim = true
		KEY_RIGHT: offsets[cur_anim][0] += (1 if !shift else 10); replay_anim = true
		KEY_UP   : offsets[cur_anim][1] -= (1 if !shift else 10); replay_anim = true
		KEY_DOWN : offsets[cur_anim][1] += (1 if !shift else 10); replay_anim = true

		KEY_SPACE: replay_anim = true

	if replay_anim:
		character.frame = 0
		anim_list[selected_id].text = cur_anim +' '+ str(offsets[cur_anim])
		character.offset = Vector2(offsets[cur_anim][0], offsets[cur_anim][1])
		character.play()

func change_icon(new_icon:String = 'bf') -> void:
	MAIN('IconSelect/CurIconLabel').text = new_icon

	var ic:Icon = %Icon
	var hi:ColorRect = %Icon/Highlight
	var lo:ColorRect = %Icon/Lowlight

	char_json.icon = new_icon
	ic.change_icon(new_icon.strip_edges())
	ic.default_scale = (5 if new_icon.ends_with('pixel') else 1) * 0.7
	ic.position = Vector2(120, 655)
	ic.hframes = 1

	hi.size = Vector2(ic.width, ic.height) #/ (2.0 if ic.has_lose else 1)
	hi.position = -(hi.size / 2.0)
	lo.visible = ic.has_lose
	if ic.has_lose:
		hi.size.x = ic.width / 2.0
		lo.size = hi.size
		lo.position = hi.position + Vector2(hi.size.x, 0)

func change_char(new_char:String = 'bf') -> void:
	char_json = JsonHandler.get_character(new_char)
	if char_json == null or cur_char == new_char: return
	cur_char = new_char
	MAIN('CharName').text = cur_char
	if char_json.has('no_antialiasing'):
		char_json = Legacy.fix_json(char_json)
	if char_json.has('assetPath'):
		char_json = VSlice.fix_json(char_json)

	_ui.get_node('ResPath').text = char_json.path
	DATA('Warn').visible = !ResourceLoader.exists('res://assets/images/'+ char_json.path +'.res')
	reload_list(char_json.animations)

	# update character
	character.position = get_viewport_rect().size / 2.0 - Vector2(300, 450)
	character.is_player = char_json.facing_left
	MAIN('FacesLeft').button_pressed = char_json.facing_left
	MAIN('ScaleBox').value = char_json.scale
	character.load_char(new_char)

	$Point.position = character.get_cam_pos()

	change_icon(char_json.icon)
	character.play(cur_anim) # play first loaded anim to fix offsets
	character.offset = Vector2(offsets[cur_anim][0], offsets[cur_anim][1])

	cur_cam_offset.assign(char_json.cam_offset)
	cur_pos_offset.assign(char_json.pos_offset)

	MAIN('Anti').button_pressed = char_json.antialiasing

	MAIN('Pos/X').value = int(char_json.pos_offset[0])
	MAIN('Pos/Y').value = int(char_json.pos_offset[1])

	MAIN('Cam/X').value = int(char_json.cam_offset[0])
	MAIN('Cam/Y').value = int(char_json.cam_offset[1])

	if !MAIN('Cam/Lock').button_pressed:
		$Cam.position = character.position + Vector2(character.width / 2.0, character.height / 2.5)

	# then update the shadow
	shadow.copy(character)
	shadow.antialiasing = !character.antialiasing # uhm??
	shadow.frame = shadow.sprite_frames.get_frame_count(cur_anim) - 1
	shadow_anim_change(0)

func reload_list(anims:Array) -> void:
	Util.remove_all([anim_list], $UILayer/Animations)
	offsets.clear()
	MAIN('Shadow/AnimSelect').get_popup().clear()

	#var temp_arr:Array[int] = [] # fix for the dumb floats
	for i in anims.size():
		var anim:Dictionary = anims[i]
		#temp_arr.clear()
		#temp_arr.assign(anim.offsets) # make sure they are ints to remove the extra '.0'
		offsets[anim.name] = anim.offsets #temp_arr
		flipped[anim.name] = anim.get('flip_x', false)

		var lab := make_label()
		lab.position.x += 15
		lab.position.y = 70 + (17 * i)
		lab.text = anim.name +' '+ str(anim.offsets)#temp_arr)

		$UILayer/Animations.add_child(lab)
		MAIN('Shadow/AnimSelect').get_popup().add_item(anim.name)

		anim_list.append(lab)

	if anim_list.is_empty():
		var lab = make_label()
		lab.text = 'NO ANIMATIONS'
		lab.modulate = Color.RED
		lab.position.x += 15
		lab.position.y = 87
		lab.add_theme_font_size_override('font_size', 20)
		$UILayer/Animations.add_child(lab)
		anim_list.append(lab)
	else:
		selected_id = 0
		anim_list[0].modulate = Color.YELLOW

func make_label() -> Label:
	var lab = Label.new()
	lab.add_theme_font_override('font', load('res://assets/fonts/vcr.ttf'))
	lab.add_theme_font_size_override('font_size', 17)
	lab.add_theme_constant_override('outline_size', 3)
	return lab

func MAIN(to_get:String): return _ui.get_node('Main/'+ to_get)
func DATA(to_get:String): return _ui.get_node('CurData/'+ to_get)
func ANIM(to_get:String): return _ui.get_node('Anim/'+ to_get)

func new_pressed() -> void:
	MAIN('Shadow/AnimSelect').get_popup().clear()
	cur_anim = ''
	var new = UnholyFormat.CHAR_JSON.duplicate(true)

	char_json.clear()
	offsets.clear()
	reload_list([])
	char_json = new
	character.load_char('bf')

	shadow.copy(character)
	shadow.antialiasing = !character.antialiasing # uhm??
	shadow.frame = shadow.sprite_frames.get_frame_count('idle') - 1

func save_pressed() -> void:
	var to_check:String = MAIN('CharName').text.strip_edges() # check the char name box
	if to_check.is_empty(): to_check = cur_char # if its empty, just use stored char name

	var save_json:Dictionary = UnholyFormat.CHAR_JSON.duplicate(true)
	for i in char_json.animations:
		var new_anim = UnholyFormat.CHAR_ANIM.duplicate(true)
		new_anim.offsets = offsets[i.name]
		new_anim.name = i.name
		new_anim.prefix = i.prefix
		new_anim.frames = i.frames
		new_anim.loop = i.loop
		if i.get('flip_x', false): new_anim.set('flip_x', true)
		if i.get('flip_y', false): new_anim.set('flip_y', true)
		save_json.animations.append(new_anim)

	save_json.path = char_json.path # and this
	save_json.icon = char_json.icon
	save_json.antialiasing = MAIN('Anti').button_pressed
	save_json.facing_left = MAIN('FacesLeft').button_pressed
	save_json.cam_offset = cur_cam_offset
	save_json.pos_offset = cur_pos_offset
	save_json.scale = MAIN('ScaleBox').value
	#if old_json.has('speaker'):
	#	save_json.speaker = old_json.speaker

	var file:FileAccess = FileAccess.open("res://assets/data/characters/"+ to_check +".json", FileAccess.WRITE)
	file.resize(0) # clear the file, if it has stuff in it
	file.store_string(JSON.stringify(save_json, '\t', false))
	file.close()

func _res_path_updated() -> void:
	var new_path:String = _ui.get_node('ResPath').text
	if ResourceLoader.exists('res://assets/images/'+ new_path +'.res'):
		character.sprite_frames = load('res://assets/images/'+ new_path +'.res')

func add_anim() -> void:
	get_viewport().gui_release_focus() # make sure you arent focused on anything

	var anim_name:String = ANIM('Name').text.strip_edges()
	if anim_name.is_empty():
		return Alert.make_alert('ADD ANIMATION NAME', Alert.WARN)

	var fixed_frames:Array[int] = []
	if !ANIM('Frames').text.is_empty():
		var temp = ANIM('Frames').text.strip_edges()
		if temp.contains('-'):
			temp = temp.split('-')
			for i in range(int(temp[0]), int(temp[1]) + 1):
				fixed_frames.append(i)
			ANIM('Frames').text = Util.array_to_str(fixed_frames).replace(' ', '')
		else:
			temp = temp.split(',')
			for i in temp:
				fixed_frames.append(int(i))

	for i in char_json.animations:
		if i.name == anim_name: # Animation exists, just update it with new info
			i.prefix = ANIM('Prefix').text
			i.frames = fixed_frames
			i.loop = ANIM('Loop').button_pressed
			i.framerate = ANIM('Framerate').value
			i.flip_x = ANIM('Flip/X').button_pressed
			i.flip_y = ANIM('Flip/Y').button_pressed

			character.add_anim(i.name, i.prefix, i.frames, i.framerate, i.loop)
			if cur_anim == i.name:
				character.play(i.name)
				character.offset = Vector2(offsets[i.name][0], offsets[i.name][1])
			return

	# Animation doesn't exist, make a new one
	var _data := UnholyFormat.CHAR_ANIM.duplicate(true)
	_data.name = anim_name
	_data.prefix = ANIM('Prefix').text
	_data.frames = fixed_frames

	_data.framerate = ANIM('Framerate').value
	_data.loop = ANIM('Loop').button_pressed

	_data.flip_x = ANIM('Flip/X').button_pressed
	_data.flip_y = ANIM('Flip/Y').button_pressed

	char_json.animations.append(_data)

	character.add_anim(anim_name, _data.prefix, fixed_frames, _data.framerate, _data.loop)
	reload_list(char_json.animations)

func shadow_anim_change(id:int) -> void:
	var new_anim:String = char_json.animations[id].name
	var frame_lim:int = shadow.sprite_frames.get_frame_count(new_anim) - 1
	MAIN('Shadow/Anim').text = new_anim
	shadow.play(new_anim)
	shadow.pause()
	MAIN('Shadow/Frame').max_value = frame_lim
	MAIN('Shadow/Frame').value = frame_lim
	shadow.offset = Vector2(offsets[new_anim][0], offsets[new_anim][1])
	shadow.flip_h = flipped.get(new_anim, false)

func shadow_frame_change(value:int) -> void:
	shadow.frame = value
	MAIN('Shadow/Frame/Txt').text = 'Frame: '+ str(value)

func shadow_color_changed(color:Color) -> void:
	shadow.modulate = color
