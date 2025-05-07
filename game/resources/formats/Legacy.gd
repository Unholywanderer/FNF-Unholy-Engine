class_name Legacy; extends Chart

const sec_format = {
	'lengthInSteps': 16,
	'changeBPM': false,
	'bpm': 0,
	'sectionNotes': [],
	'mustHitSection': false,
	'altAnim': false
}
const chart_format = {
	'song': 'Test',
	'events': [],
	'notes': [],
	'bpm': 100,
	'speed': 1.0,
	'player1': 'bf',
	'player2': 'dad',
	'gfVersion': 'gf'
}


var p_v1:bool = false
func _init(s:bool = false): p_v1 = s

func parse_chart(data) -> Array:
	for sec in data.notes:
		for note in sec.sectionNotes:
			if note[1] < 0: continue
			var time:float = maxf(0, note[0])

			if note[2] is String: continue
			var sustain_len:float = maxf(0, note[2])
			var is_sustain:bool = sustain_len > 0

			var n_data:int = int(note[1])
			var must_hit:bool = sec.mustHitSection if note[1] <= 3 else not sec.mustHitSection
			if p_v1: must_hit = n_data < 4

			var n_type:String = str(note[3]) if note.size() > 3 else ''
			if n_type == 'true': n_type = 'Alt'

			add_note([time, n_data, is_sustain, sustain_len, must_hit, n_type])

	return_notes.sort_custom(func(a, b): return a[0] < b[0])
	return return_notes

static func fix_json(data:Dictionary) -> Dictionary:
	# make psych char json mine grrr
	var psych_anim:Dictionary = {
		"loop": "loop",
		"offsets": "offsets",
		"anim": "name",
		"fps": "framerate",
		"name": "prefix",
		"indices": "frames"
	}
	var psych_data:Dictionary = {
		"no_antialiasing": "antialiasing",
		"image": "path",
		"position": "pos_offset",
		"healthicon": "icon",
		"flip_x": "facing_left",
		"camera_position": "cam_offset",
		"sing_duration": "sing_dur",
		"scale": "scale",
		"speaker": "speaker"
	}

	var new_json:Dictionary = UnholyFormat.CHAR_JSON.duplicate(true)
	for anim:Dictionary in data.animations:
		var anis:Dictionary = UnholyFormat.CHAR_ANIM.duplicate()
		for key in psych_anim:
			if key == 'offsets':
				var off = [-anim[key][0], -anim[key][1]]
				if off[0] == -0: off[0] = 0
				if off[1] == -0: off[1] = 0
				anis[psych_anim[key]] = off
			else:
				anis[psych_anim[key]] = anim[key] if anim.has(key) else UnholyFormat.CHAR_ANIM[psych_anim[key]]
		new_json.animations.append(anis)

	for i in data.keys():
		if i == 'animations' or !psych_data.has(i): continue
		new_json[psych_data[i]] = data[i] if i != 'no_antialiasing' else !data[i]

	return new_json
