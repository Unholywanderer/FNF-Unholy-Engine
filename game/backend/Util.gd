extends Node
# Node with functions

func center_obj(obj = null, axis:String = 'xy') -> void:
	if obj == null: return
	match axis:
		'x': obj.position.x = (Game.screen[0] / 2) #- (obj_size.x / 2)
		'y': obj.position.y = (Game.screen[1] / 2) #- (obj_size.y / 2)
		_: obj.position = Vector2(Game.screen[0] / 2, Game.screen[1] / 2)

func format_str(string:String = '') -> String:
	return string.to_lower().strip_edges().replace(' ', '-').replace('\'', '').replace(':', '')

func array_to_str(arr:Array) -> String:
	return str(arr).strip_edges().substr(1).replace(']', '') # i do NOT care brah

func round_d(num:float, digit:int) -> float: # bowomp
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func rand_bool(chance:float = 50.0) -> bool:
	return (randi() % 100) < chance

func remove_all(array:Array[Array], node:Node) -> void:
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

func quick_tween(obj:Variant, prop:String, to:Variant, dur:float, trans:int = 0,ease_type:int = 0) -> Tweener:
	return create_tween().tween_property(obj, prop, to, dur).set_trans(trans).set_ease(ease_type)

func quick_label(t:String = '', s:int = 15, ol_s:int = int(s / 3.0), f:String = 'vcr.ttf') -> Label:
	var new_label:Label = Label.new()
	new_label.text = t
	new_label.add_theme_font_override('font', ResourceLoader.load('res://assets/fonts/'+ f))
	new_label.add_theme_font_size_override('font_size', s)
	new_label.add_theme_constant_override('outline_size', ol_s)
	return new_label

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
		&'spring' : return Tween.TRANS_SPRING
		_: return Tween.TRANS_LINEAR


@warning_ignore("unused_parameter")
func flash_screen(flash_color:Color = Color.WHITE) -> void:
	pass

func get_alias(antialiased:bool = true) -> CanvasItem.TextureFilter:
	return CanvasItem.TEXTURE_FILTER_LINEAR if antialiased else CanvasItem.TEXTURE_FILTER_NEAREST

func get_closest_anim(frames:SpriteFrames, anim:String) -> String:
	for i in frames.get_animation_names():
		if i.begins_with(anim): return i
	return ''

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
