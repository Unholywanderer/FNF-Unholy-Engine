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

func parse_chart(data:Dictionary) -> Array: #very simple very demure
	var data_unparsed:Array = data.get('notes',[])
	if !data.get('events'): data.set('events', [])
	
	for step in data_unparsed:
		var section:Array = step.get('sectionNotes',[])
		var must_hit:bool = step.get('mustHitSection',false)
		
		for note in section:
			var direction:int = note[1]
			var time:float = note[0]
			var sus_length:float = note[2]
			var type:String = note[3] if note.size() > 3 else ''
			var is_sustain:bool = sus_length > 0.0
			var is_must_hit:bool = must_hit if direction <= 3 else not must_hit
			if p_v1: is_must_hit = direction < 4
			if type == 'true': type = 'Alt'
			
			if direction < 0:
				if direction != -1: # thats an event note, dont skip it
					continue
				var event:Array = [time, [[sus_length, type, note[4]]]]
				if data.events.has(event): continue
				data.events.append(event)
			add_note([time, direction, is_sustain, sus_length, is_must_hit, type])
	
	return_notes.sort_custom(func(a, b): return a.strum_time < b.strum_time) ; _added_data.clear()
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
				var off:Array[int] = [-anim[key][0], -anim[key][1]]
				if off[0] == -0: off[0] = 0
				if off[1] == -0: off[1] = 0
				anis[psych_anim[key]] = off
			else:
				anis[psych_anim[key]] = anim.get(key, UnholyFormat.CHAR_ANIM[psych_anim[key]])
		new_json.animations.append(anis)

	for i in data.keys():
		if i == 'animations' or !psych_data.has(i): continue
		new_json[psych_data[i]] = data[i] if i != 'no_antialiasing' else !data[i]

	new_json['cam_offset'][0] *= -1 # the x goes in the opposite direction

	return new_json
