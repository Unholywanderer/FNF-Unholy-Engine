@tool
class_name Atlas extends AnimateSymbol

## Emitted whenever the [code]cur_anim[/code] is changed, be it from the [code]play_anim[/code] function
## or by setting it manually.
signal anim_changed(new_anim:String)
signal finished
var _added_anims:Dictionary[String, AnimData] = {}
var cur_data:AnimData = AnimData.new()

## If the current animation is empty and there are no other animations playing.
## Once the animation is complete, it automatically returns to this frame to loop.
var loop_frame:int = -1

## The index of an animation's frame array. Use only if an animation has a custom frame array, otherwise
## just use [code]frame[/code].
var frame_index:int = -1

## The current animation being played. If the animation specified isn't added, it will not be updated.
var cur_anim:StringName = '':
	set(an):
		if _added_anims.has(an):
			cur_anim = an
			anim_changed.emit(an)

## Load an atlas. [code]atlas_path[/code] will start in 'res://assets/' if not specified.
## Set [code]clear_prev[/code] to true to automatically remove previously added atlases if needed.
func add_atlas(atlas_path:String = '', clear_prev:bool = false) -> void:
	var new_dobe := AdobeAtlas.new()
	if !atlas_path.begins_with('res://assets/'): atlas_path = 'res://assets/'+ atlas_path
	if !atlas_path.ends_with('/'): atlas_path += '/'
	if !FileAccess.file_exists(atlas_path +'Animation.json'):
		return printerr('ATLAS: "%s" is not a valid atlas!' % atlas_path)
	new_dobe.folder_path = atlas_path
	if clear_prev: atlases.clear()
	atlases.append(new_dobe)

## Add an animation with frames. Useful for if you are using the entire animation timeline.
func add_anim_by_frames(alias:String, frames:Array = [], fps:float = 24.0, looped:bool = false) -> void:
	_add_anim(alias, frames, fps, looped)

## Add an animation with a symbol, with frames optionally.
func add_anim_by_symbol(alias:String, symb:String, frames:Array = [], fps:float = 24.0, looped:bool = false) -> void:
	_add_anim(alias, frames, fps, looped, symb)

func _add_anim(a:String, f:Array, fps:float, l:bool, s:String = '') -> void:
	if atlases.is_empty(): return printerr('No Atlas Dummy!')
	var new_anim := AnimData.new()
	if f.size() == 2:
		f = range(f[0], f[1])

	if !s.is_empty(): new_anim.anim = s
	new_anim.frames = f
	new_anim.framerate = fps
	new_anim.loop = l
	print('added %s (%s), with %s custom frames at %s fps' % [
		a, ('None' if s.is_empty() else s), f.size(), fps
	])
	_added_anims.set(a, new_anim)

func get_frame_count(anim:String) -> int:
	var count:int = 0
	if _added_anims.has(anim):
		var _anim := _added_anims[anim]
		if _anim.anim.is_empty() or !_anim.frames.is_empty():
			count = _anim.frames.size()
		else:
			count = (atlases[atlas_index] as AdobeAtlas).get_length_of(_anim.anim)

	return count

func play_anim(anim:String, force:bool = false) -> void:
	if !_added_anims.has(anim): return
	var da_anim:AnimData = _added_anims[anim]
	var el_use:int = frame_index if da_anim.frames.size() > 0 else frame
	if !force and cur_anim == anim and el_use < get_frame_count(anim) - 1: return
	playing = true

	if !da_anim.anim.is_empty() and symbol != da_anim.anim:
		symbol = da_anim.anim

	frame_index = 0
	frame = da_anim.frames[0] if !da_anim.frames.is_empty() else 0
	frame_timer = 0
	cur_anim = anim
	cur_data = da_anim

func pause() -> void: playing = false

func _process(delta:float) -> void:
	# no reason to use the custom _process, so just go back to the normal one
	if cur_anim.is_empty(): return super(delta)

	if atlases.size() != last_atlases_size:
		last_atlases_size = atlases.size()
		notify_property_list_changed()

	if atlas_index > atlases.size() - 1:
		atlas_index = atlases.size() - 1

	var atlas: AnimateAtlas = atlases[atlas_index]
	if atlas.wants_redraw():
		frame = frame
		queue_redraw()
	if atlas.wants_reload_list():
		notify_property_list_changed()

	if not playing or atlases.is_empty() or not is_instance_valid(atlas): return

	#var _anim:AnimData = _added_anims[cur_anim]
	frame_timer += delta * speed_scale
	if frame_timer >= 1.0 / cur_data.framerate:
		var _total_frames:int = max(cur_data.frames.size() - 1, 0)
		var _diff:int = floori(frame_timer * cur_data.framerate)
		frame_timer = wrapf(frame_timer, 0.0, 1.0 / cur_data.framerate)

		if !symbol.is_empty() and _total_frames == 0 and frame < get_animation_length() - 1:
			frame += _diff
			return
		if _total_frames > frame_index:
			frame_index += _diff
			frame = cur_data.frames[frame_index]
		else:
			if cur_data.loop:
				if _total_frames > 0:
					frame_index = 0
					frame = cur_data.frames[0]
				else:
					frame = 0
				playing = true
				return

			playing = false
			finished.emit()
			frame = cur_data.frames[-1] if _total_frames > 0 else get_animation_length() - 1

func validate_frame(value: int, length: int = -1) -> int:
	if loop_frame < 0 or value < length:
		return super(value, length)
	return wrapi(value, loop_frame, length - 1)

## Returns an array with every symbol name, sorted alphabetically by the first letter.
func get_symbol_list() -> Array[StringName]:
	var _symbols:Array[StringName] = (atlases[atlas_index] as AdobeAtlas).symbols.keys()
	_symbols.sort_custom(func(a, b): return a.left(1) < b.left(1)) # make it alphabetical before returning
	return _symbols

## Clear atlases and reset some variables.
func clear() -> void:
	atlases.clear()
	_added_anims.clear()
	frame = 0
	loop_frame = -1
	frame_index = -1

class AnimData extends Resource:
	var anim:String = ''
	var framerate:float = 24.0
	var frames:Array = []
	var has_frames:bool:
		get: return !frames.is_empty()
	var loop:bool = false
