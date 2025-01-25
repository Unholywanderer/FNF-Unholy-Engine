class_name Chart; extends Resource;
# makes a chart from a json

enum FORMAT {
	LEGACY, # old base game, old psych
	V_SLICE, 
	PSYCH_V1,
	FPS_PLUS,
	CODENAME,
	MARU,
	OSU
}
var format:FORMAT = FORMAT.LEGACY

var return_notes:Array = []
func load_chart(data, chart_type:String = 'psych', diff:String = 'normal') -> Array:
	if data == null: return []
	return_notes.clear()
	format = get_format(chart_type)
	
	var le_parse
	match format:
		FORMAT.LEGACY, FORMAT.PSYCH_V1, FORMAT.FPS_PLUS:
			le_parse = Legacy.new(format == FORMAT.PSYCH_V1)
		FORMAT.V_SLICE: 
			le_parse = VSlice.new(diff)
		FORMAT.CODENAME:
			le_parse = Codename.new()
		FORMAT.MARU:
			le_parse = Maru.new()
		FORMAT.OSU:
			le_parse = Osu.new()
			le_parse.load_file(data.song)
		_: 
			printerr('Couldn\'t get chart type')
			return []
	
	return le_parse.parse_chart(data)
	
# for loading a chart that isnt named a difficulty
# used for pico speaker # assumes its legacy by default, should fix that later
func load_named_chart(song_name:String, chart_name:String = ''):
	var le_parse := Legacy.new()
	var path:String = 'res://assets/songs/%s/charts/%s.json' % [Game.format_str(song_name), chart_name]
	print(path)
	if ResourceLoader.exists(path):
		var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
		return le_parse.parse_chart(json.song)
	return []

func get_must_hits(player_hit:bool = true) -> Array:
	var notes:Array = []
	for i in return_notes:
		print(i[4])
		if i[4] == player_hit: notes.append(i)
	return notes

func add_note(note_data:Array) -> void:
	if note_data.size() > 0 and !return_notes.has(note_data): # skip adding a note that exists
		return_notes.append(note_data)

func get_events(SONG:Dictionary) -> Array[EventData]:
	var path_to_check = 'res://assets/songs/%s/events.json' % Game.format_str(SONG.song)

	var events_found:Array = []
	var events:Array[EventData] = []
	if SONG.has('events'): # check current song json for any events
		events_found.append_array(SONG.events)
	
	if format != FORMAT.V_SLICE and ResourceLoader.exists(path_to_check): # then check if there is a event json
		print(path_to_check)
		
		var json = JSON.parse_string(FileAccess.open(path_to_check, FileAccess.READ).get_as_text())
		if json.has('song'): json = json.song
		if format == FORMAT.FPS_PLUS:
			json = json.events
		
		if json.has('notes') and json.notes.size() > 0: # if events are a -1 note
			for sec in json.notes:
				for note in sec.sectionNotes:
					if note[1] == -1: 
						events_found.append([note[0], [[note[2], note[3], note[4]]]])
		elif json.has('events'):
			events_found.append_array(json.events)
	
	for event in events_found:
		match format:
			FORMAT.V_SLICE: events.append(EventData.new(event, 'v_slice'))
			FORMAT.CODENAME: pass
			FORMAT.FPS_PLUS: pass
			FORMAT.MARU: pass
			_:
				for i in event[1]:
					events.append(EventData.new([event[0], i]))
	
	events.sort_custom(func(a, b): return a.strum_time < b.strum_time)
	return events

func get_format(f:String) -> FORMAT:
	var e:FORMAT = FORMAT.LEGACY
	match f.to_lower().strip_edges():
		'v_slice': e = FORMAT.V_SLICE
		'psych_v1': e = FORMAT.PSYCH_V1
		'codename': e = FORMAT.CODENAME
		'fps_plus': e = FORMAT.FPS_PLUS
		'osu': e = FORMAT.OSU
		'maru': e = FORMAT.MARU
	return e
