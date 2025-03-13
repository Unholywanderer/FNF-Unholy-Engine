extends Node2D

var character:Character
var shadow:Character
var char_json = {}
var anim_list:Array[Label] = []
var offsets:Dictionary[String, Array] = {}
var cur_cam_offset:Array = [0, 0]
var cur_pos_offset:Array = [0, 0]

var icon_list:Array = []

var char_list:Array = []
var cur_char:String = ''
var cur_anim:String = ''
var selected_id:int = 0:
	set(new_id):
		if new_id < anim_list.size():
			anim_list[selected_id].modulate = Color.WHITE  # if this is greater than the new char's anim list, crash
			anim_list[new_id].modulate = Color.YELLOW
			cur_anim = anim_list[new_id].text.split('[')[0].strip_edges()
		selected_id = new_id
		
		character.play(cur_anim)
		var got = offsets[cur_anim] if offsets.has(cur_anim) else [0, 0]
		character.offset = Vector2(got[0], got[1])

func _ready() -> void:
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

	MAIN('IconSelect/Icon').default_scale = 0.7
	MAIN('IconSelect/Icon').scale = Vector2(0.7, 0.7)
	
	var thing_change = func(_val, thing_name:String): # we dont use the '_val' for this
		var new_vals = [MAIN(thing_name +'/X').value, MAIN(thing_name +'/Y').value]
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
	MAIN('Center').connect('toggled', func(tog:bool):
		character.centered = tog
	)
	$Cam.position = get_viewport_rect().size / 2.0
	
	var grab = FileAccess.get_file_as_string('res://assets/data/order.txt').split(',')
	grab.append_array(DirAccess.get_files_at('res://assets/data/characters'))
	for i in grab:
		i = i.replace('.json', '')
		if !char_list.has(i):
			char_list.append(i)
			MAIN('CharacterSelect').get_popup().add_item(i)
	
	for i in DirAccess.get_files_at('res://assets/images/icons'):
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
	var sc = MAIN('ScaleBox').value
	character.scale = Vector2(sc, sc)
	shadow.scale = character.scale
		
	DATA('Anim').text = cur_anim
	DATA('Offset').text = str(offsets[cur_anim])
	DATA('Frame').text = 'Frame:\n'+ str(character.frame) +' / '+ str(character.sprite_frames.get_frame_count(character.animation) - 1)
	

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and !event.is_released():
		get_viewport().gui_release_focus()
	
	if Input.is_action_just_pressed('back'): Game.switch_scene('menus/Main_Menu')
	
	var ctrl = Input.is_key_pressed(KEY_CTRL)
	var shift = Input.is_key_pressed(KEY_SHIFT)
	## CAMERA ZOOM
	if Input.is_key_pressed(KEY_U): $Cam.zoom -= Vector2(0.01, 0.01)
	if Input.is_key_pressed(KEY_O): $Cam.zoom += Vector2(0.01, 0.01)
	## CAMERA MOVE
	if Input.is_key_pressed(KEY_J): $Cam.position.x -= 5 * (5 if shift else 1)
	if Input.is_key_pressed(KEY_L): $Cam.position.x += 5 * (5 if shift else 1)
	if Input.is_key_pressed(KEY_I): $Cam.position.y -= 5 * (5 if shift else 1)
	if Input.is_key_pressed(KEY_K): $Cam.position.y += 5 * (5 if shift else 1)
	## CHARACTER OFFSETTING
	var replay_anim = false
	if Input.is_key_pressed(KEY_LEFT) : offsets[cur_anim][0] -= (1 if !shift else 10); replay_anim = true
	if Input.is_key_pressed(KEY_RIGHT): offsets[cur_anim][0] += (1 if !shift else 10); replay_anim = true
	if Input.is_key_pressed(KEY_UP)   : offsets[cur_anim][1] -= (1 if !shift else 10); replay_anim = true
	if Input.is_key_pressed(KEY_DOWN) : offsets[cur_anim][1] += (1 if !shift else 10); replay_anim = true
	if Input.is_key_pressed(KEY_SPACE): replay_anim = true
		
	if replay_anim:
		character.frame = 0
		anim_list[selected_id].text = cur_anim +' '+ str(offsets[cur_anim])
		character.offset = Vector2(offsets[cur_anim][0], offsets[cur_anim][1])
		character.play()
		
	if Input.is_key_pressed(KEY_W): selected_id = wrapi(selected_id - 1, 0, anim_list.size())
	if Input.is_key_pressed(KEY_S): selected_id = wrapi(selected_id + 1, 0, anim_list.size())
	if Input.is_key_pressed(KEY_Q):
		character.pause() 
		character.frame -= 1
	if Input.is_key_pressed(KEY_E):
		character.pause()
		character.frame += 1
	
func change_icon(new_icon:String = 'bf') -> void:
	var ic:Icon = MAIN('IconSelect/Icon')
	var hi:ColorRect = MAIN('IconSelect/Highlight')
	var lo:ColorRect = MAIN('IconSelect/Lowlight')
	
	char_json.icon = new_icon
	ic.change_icon(new_icon.strip_edges())
	var ic_size = Vector2(ic.texture.get_width() * 0.7, ic.texture.get_height() * 0.7)
	ic.position = Vector2(-845, 590)
	ic.hframes = 1
	
	hi.custom_minimum_size = ic_size
	hi.position = ic.position - hi.custom_minimum_size / 2.0
	lo.visible = ic.has_lose
	if ic.has_lose:
		hi.custom_minimum_size.x = ic_size.x / 2.0
		hi.size = hi.custom_minimum_size
		lo.custom_minimum_size = hi.custom_minimum_size
		lo.position = hi.position
		lo.position.x += hi.size.x
	
func change_char(new_char:String = 'bf') -> void:
	char_json = JsonHandler.get_character(new_char)
	if char_json == null or cur_char == new_char: return
	selected_id = 0
	cur_char = new_char
	MAIN('CharacterSelect').text = cur_char
	if char_json.has('no_antialiasing'):
		char_json = Legacy.fix_json(char_json)
	
	DATA('Warn').visible = !ResourceLoader.exists('res://assets/images/'+ char_json.path +'.res')
	MAIN('CharacterSelect/CurCharLabel').text = cur_char
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
	
	cur_cam_offset = char_json.cam_offset
	cur_pos_offset = char_json.pos_offset
	
	MAIN('Anti').button_pressed = char_json.antialiasing

	MAIN('Pos/X').value = char_json.pos_offset[0]
	MAIN('Pos/Y').value = char_json.pos_offset[1]
	
	MAIN('Cam/X').value = char_json.cam_offset[0]
	MAIN('Cam/Y').value = char_json.cam_offset[1]
	
	if !MAIN('Cam/Lock').button_pressed:
		$Cam.position = character.position + Vector2(character.width / 2.0, character.height / 2.5)
		
	# then update the shadow
	shadow.copy(character)
	shadow.antialiasing = !character.antialiasing # uhm??
	var frame_limit = shadow.sprite_frames.get_frame_count(cur_anim) - 1
	shadow.frame = frame_limit
	shadow_anim_change(0)
	
func reload_list(anims:Array) -> void:
	Game.remove_all([anim_list], $UILayer/Animations)
	offsets.clear()
	MAIN('Shadow/AnimSelect').get_popup().clear()
	
	for i in anims.size():
		var anim = anims[i]
		offsets[anim.name] = anim.offsets
		
		var lab = make_label()
		lab.position.x += 15
		lab.position.y = 70 + (20 * i)
		lab.text = anim.name +' '+ str(anim.offsets)
		
		$UILayer/Animations.add_child(lab)
		MAIN('Shadow/AnimSelect').get_popup().add_item(anim.name)
		
		anim_list.append(lab)
	
	if anim_list.size() == 0:
		var lab = make_label()
		lab.text = 'NO ANIMATIONS'
		lab.modulate = Color.RED
		lab.position.x -= 20
		lab.position.y = 50
		$UILayer/Animations.add_child(lab)
		anim_list.append(lab)
	else:
		selected_id = 0
		anim_list[0].modulate = Color.YELLOW

func on_char_change(id:int) -> void:
	var got_char = char_list[id]
	if cur_char != got_char:
		change_char(got_char)

func make_label() -> Label:
	var lab = Label.new()
	lab.add_theme_font_override('font', load('res://assets/fonts/vcr.ttf'))
	lab.add_theme_font_size_override('font_size', 20)
	lab.add_theme_constant_override('outline_size', 4)
	return lab

func MAIN(to_get:String): return $UILayer.get_node('Main/'+ to_get)
func DATA(to_get:String): return $UILayer.get_node('CurData/'+ to_get)

func save_pressed() -> void:
	var old_json = JsonHandler.get_character(cur_char) # should remove this once you can actually add prefixes
	if old_json != null and old_json.has('no_antialiasing'):
		old_json = Legacy.fix_json(old_json)
		
	var new_json:Dictionary = UnholyFormat.CHAR_JSON.duplicate(true)
	for i in offsets.keys():
		var new_anim = UnholyFormat.CHAR_ANIM.duplicate()
		new_anim.offsets = offsets[i]
		new_anim.name = i
		if old_json != null:
			for a in old_json.animations:
				if a.name == i: new_anim.prefix = a.prefix
		new_json.animations.append(new_anim)
		
	new_json.path = old_json.path # and this
	new_json.icon = char_json.icon
	new_json.antialiasing = MAIN('Anti').button_pressed
	new_json.facing_left = MAIN('FacesLeft').button_pressed
	new_json.cam_offset = cur_cam_offset
	new_json.pos_offset = cur_pos_offset
	new_json.scale = MAIN('ScaleBox').value
	if old_json.has('speaker'):
		new_json.speaker = old_json.speaker
	
	var file:FileAccess = FileAccess.open("res://assets/data/characters/"+ cur_char +".json", FileAccess.WRITE)
	file.resize(0) # clear the file, if it has stuff in it
	file.store_string(JSON.stringify(new_json, '\t', false))
	file.close()


func shadow_anim_change(id:int) -> void:
	var new_anim = anim_list[id].text.split('[')[0].strip_edges()
	var frame_lim = shadow.sprite_frames.get_frame_count(new_anim) - 1
	MAIN('Shadow/Anim').text = new_anim
	shadow.play(new_anim)
	shadow.pause()
	MAIN('Shadow/Frame').max_value = frame_lim
	MAIN('Shadow/Frame').value = frame_lim
	shadow.offset = Vector2(offsets[new_anim][0], offsets[new_anim][1])
	
func shadow_frame_change(value:int) -> void:
	shadow.frame = value
	MAIN('Shadow/Frame/Txt').text = 'Frame: '+ str(value)
