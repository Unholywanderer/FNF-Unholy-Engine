class_name Maru; extends Chart;

var last_must:bool = false
func parse_chart(data) -> Array:
	for sec in data.notes:
		last_must = sec.get('mustHitSection', true)
		if !sec.has('sectionNotes'): continue
		for note in sec.sectionNotes:
			if note[1] < 0: continue
			var time:float = maxf(0, note[0])

			if note[2] is String: continue
			var sustain_len:float = maxf(0, note[2])
			var is_sustain:bool = sustain_len > 0

			var n_data:int = int(note[1])
			var must_hit:bool = last_must if note[1] <= 3 else !last_must

			var n_type:String = str(note[3]) if note.size() > 3 else ''
			if n_type == 'true': n_type = 'Alt'

			add_note([time, n_data, is_sustain, sustain_len, must_hit, n_type])

	return_notes.sort_custom(func(a, b): return a.strum_time < b.strum_time)
	return return_notes
