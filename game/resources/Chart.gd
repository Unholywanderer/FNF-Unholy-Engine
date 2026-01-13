class_name Chart; extends Resource;
# makes a chart from a json

enum {
	LEGACY, # old base game, old psych
	V_SLICE,
	PSYCH_V1,
	FPS_PLUS,
	CODENAME,
	MARU,
	OSU
}
var format:int = LEGACY

var return_notes:Array[NoteData] = []
func load_chart(data, chart_type:String = 'psych', diff:String = 'normal') -> Array:
	if data == null: return []
	return_notes.clear()
	format = get_format(chart_type)

	var le_parse = get_parse(format, diff)
	if le_parse is Osu:
		le_parse.load_file(data.song)

	return le_parse.parse_chart(data)

## For loading a chart that isn't specifically named a difficulty
static func load_named_chart(song:String, chart_name:String, chart_format:String = 'legacy'):
	var path:String = 'res://assets/songs/%s/charts/%s.json' % [Util.format_str(song), chart_name]
	if chart_format == 'v_slice':
		path = 'res://assets/songs/%s/chart%s.json' % [Util.format_str(song), JsonHandler.song_variant]
	var le_parse = get_parse(get_format(chart_format), chart_name)
	print(path)
	if ResourceLoader.exists(path):
		var json = JsonHandler.parse(path)
		if json.get('song') is Dictionary: json = json.song
		return le_parse.parse_chart(json)
	return []

static func get_must_hits(chart_notes:Array, player_hit:bool = true) -> Array:
	return chart_notes.filter(func(n): return n.must_press == player_hit)

var _added_data:Array[Array] = [] # dupe note shit
func add_note(new_note:Array) -> void:
	if new_note.size() > 0 and !_added_data.has([new_note[0], new_note[1], new_note[4]]):
		return_notes.append(NoteData.new(new_note))
		_added_data.append([new_note[0], new_note[1], new_note[4]])
		return
	print('dupe note!')
		#return_notes.append(note_data)

func get_events(SONG:Dictionary) -> Array[EventData]:
	var path_to_check:String = 'songs/%s/events.json' % Util.format_str(SONG.song)

	var events_found:Array = []
	if SONG.has('events'): # check current song json for any events
		events_found.append_array(SONG.events)

	if format != V_SLICE:
		#if format == LEGACY:
			#for sec in SONG.notes: # check song json for any -1 event notes
			#	for note in sec.sectionNotes:
			#		if note[1] != -1: continue
			#		events_found.append([note[0], [[note[2], note[3], note[4]]]])

		# then check if there is a event json
		if Util.file_exists(path_to_check):
			print('res://assets/'+ path_to_check)

			var json:Dictionary = JsonHandler.parse(path_to_check)
			if json.get('song') is not String: json = json.song
			if format == FPS_PLUS:
				json = json.events

			if json.get('notes', []).size() > 0: # if events are a -1 note
				for sec in json.notes:
					for note in sec.sectionNotes:
						if note[1] != -1: continue
						events_found.append([note[0], [[note[2], note[3], note[4]]]])

			if json.has('events'): events_found.append_array(json.events)

	var events:Array[EventData] = []
	for event in events_found:
		match format:
			V_SLICE: events.append(EventData.new(event, 'v_slice'))
			CODENAME: events.append(EventData.new(event, 'codename'))
			FPS_PLUS: pass
			MARU: pass
			_:
				for i in event[1]:
					events.append(EventData.new([event[0], i]))

	events.sort_custom(func(a, b): return a.strum_time < b.strum_time)
	return events

static func get_format(f:String):
	var e:= LEGACY
	match f.to_lower().strip_edges():
		'v_slice': e = V_SLICE
		'psych_v1': e = PSYCH_V1
		'codename': e = CODENAME
		'fps_plus': e = FPS_PLUS
		'osu': e = OSU
		'maru': e = MARU
	return e

static func get_parse(f:int, d:String):
	match f:
		LEGACY, PSYCH_V1, FPS_PLUS:
			return Legacy.new(f == PSYCH_V1)
		V_SLICE:
			return VSlice.new(d)
		CODENAME:
			return Codename.new()
		MARU:
			return Maru.new()
		OSU:
			return Osu.new()
		_:
			printerr('Couldn\'t get chart type')
			return Legacy.new()
