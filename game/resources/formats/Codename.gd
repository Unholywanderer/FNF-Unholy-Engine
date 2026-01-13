class_name Codename; extends Chart;

func parse_chart(data):
	var possible_types:Array = data.get('noteTypes', [])
	for line in data.strumLines:
		var init_type:String = 'gf' if line.position == 'girlfriend' else ''
		for note in line.notes:
			var time:float = maxf(0.0, note.time)
			var sustain_len:float = maxf(0.0, note.sLen)
			var n_type:String = init_type
			if note.type > 0: n_type = possible_types[int(note.type - 1)]

			add_note([time, int(note.id), sustain_len > 0, sustain_len, line.position == 'boyfriend', n_type])

	return_notes.sort_custom(func(a, b): return a.strum_time < b.strum_time)
	return return_notes

# see this is funny because its not a json
static func fix_json(character:String) -> Dictionary:
	var parsed_data:Dictionary = {}
	var le_xml:XMLParser = XMLParser.new()
	le_xml.open('res://assets/data/characters/'+ character +'.xml')
	return parsed_data

# convert a chart to a simplier format, so its easier to mess with
#? maybe make it so it has a "section data" array, seperate from the notes for any formats that have them
static func convert_to_simple(chart:Dictionary) -> Dictionary:
	var simple:Dictionary = UnholyFormat.EDITOR_CHART.duplicate(true)
	#simple.events = chart.events
	var possible_types:Array = chart.get('noteTypes', [])
	for line in chart.strumLines:
		var init_type:String = 'gf' if line.position == 'girlfriend' else ''
		for note in line.notes:
			var time:float = maxf(0.0, note.time)
			var sustain_len:float = maxf(0.0, note.sLen)
			var n_type:String = init_type
			if note.type > 0: n_type = possible_types[int(note.type - 1)]

			simple.notes.append([
				time, int(note.id), sustain_len > 0, sustain_len, line.position == 'boyfriend', n_type
			])

	simple.notes.sort_custom(func(a, b): return a[0] < b[0])
	return simple
