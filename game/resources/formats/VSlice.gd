class_name VSlice; extends Chart;

var diff:String = 'hard'
func _init(d:String): diff = d

func parse_chart(data) -> Array:
	for note in data.notes[diff]:
		var time:float = maxf(0, note.t)
		var sustain_len:float = maxf(0.0, note.get('l', 0.0))
		var n_type:String = str(note.get('k', ''))
		if n_type == 'true': n_type = 'alt'

		add_note([time, int(note.d), sustain_len > 0, sustain_len, note.d <= 3, n_type])

	return_notes.sort_custom(func(a, b): return a[0] < b[0])
	return return_notes

static func fix_json(data:Dictionary) -> Dictionary:
	# make vslice char json mine grrr
	var vslice_anim:Dictionary = {
		"looped": "loop",
		"flipX": "flip_x",
		"flipY": "flip_y",
		"offsets": "offsets",
		"name": "name",
		"frameRate": "framerate",
		"prefix": "prefix",
		"frameIndices": "frames"
	}
	var vslice_data:Dictionary = {
		"is_pixel": "antialiasing",
		"assetPath": "path",
		"offsets": "pos_offset",
		"healthIcon": "icon",
		"flipX": "facing_left",
		"cameraOffsets": "cam_offset",
		"singTime": "sing_dur",
		"scale": "scale",
		"speaker": "speaker"
	}

	var new_json:Dictionary = UnholyFormat.CHAR_JSON.duplicate(true)
	for anim:Dictionary in data.animations:
		var anis:Dictionary = UnholyFormat.CHAR_ANIM.duplicate()
		for key in vslice_anim:
			if key == 'offsets':
				var off:Array[int] = [-anim[key][0], -anim[key][1]]
				if off[0] == -0: off[0] = 0
				if off[1] == -0: off[1] = 0
				anis[vslice_anim[key]] = off
			else:
				anis[vslice_anim[key]] = anim.get(key, UnholyFormat.CHAR_ANIM[vslice_anim[key]])
		new_json.animations.append(anis)

	for i in data.keys():
		if i == 'animations' or !vslice_data.has(i): continue
		if i == 'healthIcon':
			new_json[vslice_data[i]] = data[i].get('id', 'face')
			continue

		new_json[vslice_data[i]] = data[i] if i != 'is_pixel' else !data[i]

	#new_json['cam_offset'][0] *= -1 # the x goes in the opposite direction

	return new_json
