class_name VSlice; extends Chart;

var diff:String = 'hard'
func _init(d:String): diff = d

func parse_chart(data) -> Array:
	for note in data.notes[diff]:
		var time:float = maxf(0, note.t)
		var sustain_len:float = maxf(0.0, note.l) if note.has('l') else 0.0
		var n_type:String = str(note.k) if note.has('k') else ''
		if n_type == 'true': n_type = 'alt'

		add_note([time, int(note.d), sustain_len > 0, sustain_len, note.d <= 3, n_type])

	return_notes.sort_custom(func(a, b): return a[0] < b[0])
	return return_notes
