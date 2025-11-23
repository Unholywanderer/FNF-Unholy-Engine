@tool
class_name Atlas extends AnimateSymbol

signal anim_changed
var _added_anims:Dictionary[String, AnimData] = {}
var frame_index:int = -1
var cur_anim:StringName = '':
	set(an):
		if _added_anims.has(an):
			cur_anim = an
			anim_changed.emit()

func add_anim_by_frames(alias:String, frames:Array = [], fps:float = 24.0, loop:bool = false):
	var new_anim := AnimData.new()
	if frames.size() == 2:
		var le_arr:Array[int] = []
		for i in range(frames[0], frames[1]):
			le_arr.append(i)
		frames = le_arr

	new_anim.frames = frames
	new_anim.framerate = fps
	new_anim.loop = loop
	print('added %s, with %s frames and %s fps' % [alias, frames.size(), fps])
	_added_anims.set(alias, new_anim)

func add_anim_by_symbol(alias:String, symb:String, frames:Array = [], fps:float = 24.0, loop:bool = false) -> void:
	var new_anim := AnimData.new()
	new_anim.anim = symb
	if frames.size() == 2:
		var le_arr:Array[int] = []
		for i in range(frames[0], frames[1]):
			le_arr.append(i)
		frames = le_arr

	new_anim.frames = frames
	new_anim.framerate = fps
	new_anim.loop = loop
	print('added %s (%s), with %s custom frames at %s fps' % [alias, symb, frames.size(), fps])
	_added_anims.set(alias, new_anim)

func get_frame_count(anim:String) -> int:
	# TODO does not return count if animation is added by a symbol i think
	var count:int = 0
	if _added_anims.has(anim):
		count = _added_anims[anim].frames.size()

	return count

func play_anim(anim:String, force:bool = false) -> void:
	if !_added_anims.has(anim): return
	var da_anim:AnimData = _added_anims[anim]
	if !force and cur_anim == anim and \
	 frame_index < da_anim.frames.size() - 1: return
	playing = true
	_timer = 0.0
	frame_index = 0

	if !da_anim.anim.is_empty():
		symbol = da_anim.anim

	frame = da_anim.frames[0] if !da_anim.frames.is_empty() else 0
	cur_anim = anim

func pause() -> void: playing = false

func _process(delta:float) -> void:
	if not is_instance_valid(_animation):
		if frame > 0:
			frame = 0
		return

	if not playing: return
	# no reason to use the custom _process, so just go back to the normal one
	if cur_anim.is_empty(): return super(delta)

	_timer += delta
	var _le_data:AnimData = _added_anims[cur_anim]
	if _timer >= 1.0 / _le_data.framerate:
		_timer = 0.0
		var symb_anim:bool = !symbol.is_empty()

		if symb_anim and _le_data.frames.is_empty() and frame < _timeline.length - 1:
			frame += 1
			return
		if _le_data.frames.size() - 1 > frame_index:
			frame_index += 1
			frame = _le_data.frames[frame_index]
		else:
			if _le_data.loop:
				if _le_data.frames.size() > 0:
					frame_index = 0
					frame = _le_data.frames[0]
				else:
					frame = 0
				playing = true
				return

			playing = false
			finished.emit()
			if _le_data.frames.is_empty():
				frame = _timeline.length - 1
			else:
				frame = _le_data.frames[-1]

class AnimData extends Resource:
	var anim:String = ''
	var framerate:float = 24.0
	var frames:Array = []
	var loop:bool = false
