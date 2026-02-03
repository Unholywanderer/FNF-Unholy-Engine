extends Node
# Node with functions
func _ready() -> void: process_mode = Node.PROCESS_MODE_ALWAYS # heh

func center_obj(obj = null, axis:String = 'xy') -> void:
	if obj == null: return
	var obj_size:Vector2 = obj.size * obj.scale if obj.get('size') else Vector2.ZERO
	match axis:
		'x': obj.position.x = (Game.screen[0] / 2) - (obj_size.x / 2)
		'y': obj.position.y = (Game.screen[1] / 2) - (obj_size.y / 2)
		_: obj.position = Vector2(Game.screen[0] / 2, Game.screen[1] / 2) - (obj_size / 2)

func format_str(string:String = '') -> String:
	const change:String = ' ~&;:<>#' # replace with dashes
	const clear:String = '.,\'"%?' # remove completely

	string = string.replace_chars(change, '-'.unicode_at(0))
	for i in clear.split(): string = string.replace(i, '')
	return string.to_lower().strip_edges()

func array_to_str(arr:Array) -> String:
	return str(arr).strip_edges().substr(1).replace(']', '') # i do NOT care brah

func round_d(num:float, digit:int) -> float: # bowomp
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func rand_bool(chance:float = 50.0) -> bool:
	return (randi() % 100) < chance

func get_percent(val:float, of:float) -> float:
	return round_d(abs(val / of) * 100.0, 2)

func remove_all(array:Array[Array], node:Node = null) -> void:
	if node == null: node = Game.scene
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

func set_dropdown(dropdown:OptionButton, to_val:String = '') -> void:
	if dropdown == null: return print_debug('No dropdown to set!')
	var items:Array[String] = []
	for i in dropdown.item_count:
		items.append(dropdown.get_item_text(i))

	if items.has(to_val):
		dropdown.select(items.find(to_val))
	else:
		dropdown.modulate = Color.RED
		dropdown.add_item(to_val)
		dropdown.select(items.size())

func quick_tween(obj:Variant, prop:String, to:Variant, dur:float, trans = 0, ease_type = 0) -> PropertyTweener:
	if trans is String: trans = trans_from_string(trans)
	if ease_type is String: ease_type = ease_from_string(ease_type)
	return create_tween().tween_property(obj, prop, to, dur).set_trans(trans).set_ease(ease_type)

func quick_label(t:String = '', s:int = 15, ol_s:int = int(s / 3.0), f:String = 'vcr.ttf') -> Label:
	var new_label:Label = Label.new()
	new_label.text = t
	new_label.add_theme_font_override('font', ResourceLoader.load('res://assets/fonts/'+ f))
	new_label.add_theme_font_size_override('font_size', s)
	new_label.add_theme_constant_override('outline_size', ol_s)
	return new_label

func quick_rect(color:Color = Color.WHITE, pos:Vector2 = Vector2.ZERO) -> ColorRect:
	var new_col_rect:ColorRect = ColorRect.new()
	new_col_rect.color = color
	new_col_rect.position = pos
	return new_col_rect

# Welcome back Psych Engine
func ease_from_string(ease_type:StringName = &'linear') -> Tween.EaseType:
	match ease_type.to_lower().strip_edges().replace(' ', ''):
		&'in'   : return Tween.EASE_IN
		&'out'  : return Tween.EASE_OUT
		&'outin': return Tween.EASE_OUT_IN
		_: return Tween.EASE_IN_OUT

func trans_from_string(trans:StringName = &'linear') -> Tween.TransitionType:
	match trans.to_lower().strip_edges().replace(' ', ''):
		&'back'   : return Tween.TRANS_BACK
		&'bounce' : return Tween.TRANS_BOUNCE
		&'circ'   : return Tween.TRANS_CIRC
		&'cubic'  : return Tween.TRANS_CUBIC
		&'elastic': return Tween.TRANS_ELASTIC
		&'expo'   : return Tween.TRANS_EXPO
		&'quad'   : return Tween.TRANS_QUAD
		&'quart'  : return Tween.TRANS_QUART
		&'quint'  : return Tween.TRANS_QUINT
		&'sine'   : return Tween.TRANS_SINE
		&'smooth' : return Tween.TRANS_SPRING
		_: return Tween.TRANS_LINEAR

func shake_cam(cam:Camera2D, _power:float = 0.05, _axis:String = 'xy', _length:float = 0.5) -> void:
	cam = get_viewport().get_camera_2d() if cam == null else cam
	if cam == null: return printerr('No Camera to shake!')


func flash_screen(flash_color:Color = Color.WHITE, duration:float = 1.0) -> void:
	var flash:ColorRect = ColorRect.new() # i unno ill figure it out later
	flash.color = flash_color
	flash.size = Vector2(Game.screen[0], Game.screen[1])

	if get_viewport().get_camera_2d():
		get_viewport().get_camera_2d().add_child(flash)
	else:
		Game.scene.add_child(flash)
	quick_tween(flash, 'modulate:a', 0, duration).finished.connect(flash.queue_free)

func shake_obj(obj:Node, intensity:float = 5.0, dur:float = 1.0, axis:String = 'xy') -> void:
	if obj == null or !obj.get('position'): return
	var shake = Shaker.new()
	shake.shake(obj, intensity, dur, axis)
	add_child(shake)
	shake.finished.connect(func():
		if obj != null: obj.position = shake.default_pos
		shake.queue_free()
	)

func get_alias(antialiased:bool = true) -> CanvasItem.TextureFilter:
	return CanvasItem.TEXTURE_FILTER_LINEAR if antialiased else CanvasItem.TEXTURE_FILTER_NEAREST

func check_path(path:String) -> String:
	var new_path:String = path.replace('res://assets/', '').replace(Game.exe_path, '')

	if new_path.get_extension().is_empty():
		return ''#return DirAccess.dir_exists_absolute(new_path)

	if FileAccess.file_exists(Game.exe_path +'mods/'+ new_path):
		return Game.exe_path +'mods/'+ new_path

	if ResourceLoader.exists('res://assets/'+ new_path):
		return 'res://assets/'+ new_path
	return path

func dir_exists(path:String) -> bool:
	path = path.replace('res://', '').replace(Game.exe_path, '')
	return DirAccess.dir_exists_absolute('res://'+ path) or \
	  DirAccess.dir_exists_absolute(Game.exe_path + path)

## Like [code]DirAccess.get_files_at()[/code], except it only returns an array with
## the files that match the specified file extension. Use the [code]root[/code] param to
## get files outside of the "res://" folder
func only_get(path:String, ext:String, root:String = 'res://assets/') -> PackedStringArray:
	if !DirAccess.dir_exists_absolute(root + path): return []
	var found_files:PackedStringArray = []
	for i in DirAccess.get_files_at(root + path):
		if i.ends_with('.'+ ext):
			found_files.append(i)

	return found_files

func file_exists(path:String) -> bool:
	path = path.replace('res://assets/', '').replace(Game.exe_path, '')
	return FileAccess.file_exists(Game.exe_path +'mods/'+ path) or \
	  ResourceLoader.exists('res://assets/'+ path)

## Loads an .ogg audio file, without it needing to be imported
func load_audio(path:String) -> AudioStreamOggVorbis:
	#var file = FileAccess.open(path, FileAccess.READ)
	return AudioStreamOggVorbis.load_from_file(path)

func load_texture(path:String) -> Image:
	#ImageTexture.create_from_image()
	#load(path)
	return Image.load_from_file(path)

func get_closest_anim(frames:SpriteFrames, anim:String) -> String:
	for i in frames.get_animation_names():
		if anim.begins_with(i): return i
	return ''

func to_time(secs:float, is_milli:bool = true, show_ms:bool = false) -> String:
	if is_milli: secs = secs / 1000.0
	secs = abs(secs) # hmm, i dont think theres much of a reason for negative times
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

class Shaker extends Node2D:
	signal finished
	var obj:Node = null
	var default_pos:Vector2 = Vector2.ZERO
	var cur_shake:float = 0.0:
		set(shake):
			if cur_shake == shake: return
			if shake <= 0:
				shake = 0
				finished.emit()
			cur_shake = shake

	var axis:String = 'xy'

	var intensity:float = 5.0
	var duration:float = 1.0

	func shake(i:Node, inten:float = 5.0, dur:float = 1.0, ax:String = 'xy') -> void:
		obj = i
		default_pos = obj.position
		intensity = inten
		duration = dur
		axis = ax.to_lower().strip_edges()
		cur_shake = intensity
		print('hah')

	func _process(delta:float) -> void:
		cur_shake -= intensity * delta / duration
		var shook:Vector2 = Vector2(randf_range(-cur_shake, cur_shake), randf_range(-cur_shake, cur_shake))
		match axis:
			'x': obj.position.x = default_pos.x + shook.x
			'y': obj.position.y = default_pos.y + shook.y
			_: obj.position = default_pos + shook
