class_name Codename; extends Chart;

func parse_chart(data):
	var possible_types:Array = data.get('noteTypes')
	for line in data.strumLines:
		var init_type:String = 'gf' if line.position == 'girlfriend' else ''
		for note in line.notes:
			var time:float = maxf(0.0, note.time)
			var sustain_len:float = maxf(0.0, note.sLen)
			var n_type:String = init_type # uses int for note type, will check later
			if note.type > 0: n_type = possible_types[int(note.type - 1)]

			add_note([time, int(note.id), sustain_len > 0, sustain_len, line.position == 'boyfriend', n_type])

	return_notes.sort_custom(func(a, b): return a[0] < b[0])
	return return_notes
