extends Node2D;

const base_diffs:PackedStringArray = ['easy', 'normal', 'hard']
var song_diffs:Array = []
var get_diff:String

var _SONG:Dictionary = {} # change name of this to like SONG_DATA or something
var song_variant:String = '' # (erect, pico mix and whatnot)
var song_root:String = ''

var chart_notes:Array = [] # keep loaded chart and events for restarting songs
var song_events:Array[EventData] = []

var parse_type:String = ''
func parse_song(song:String, diff:String, variant:String = '', auto_create:bool = true):
	_SONG.clear()
	song_root = ''
	song_variant = ''
	parse_type = ''

	if !variant.is_empty(): 
		if variant != 'normal' and !variant.begins_with('-'):
			variant = '-'+ variant
		else:
			variant = ''
	
	# TODO figure out a better way to get chart types, this a lil dookie
	song = Game.format_str(song)
	song_variant = variant
	song_root = song

	if ResourceLoader.exists('res://assets/songs/'+ song +'/chart'+ song_variant +'.json'):
		parse_type = 'v_slice'
		
	if FileAccess.file_exists('res://assets/songs/'+ song +'/charts/'+ diff +'.osu'):
		parse_type = 'osu'
	
	get_diff = diff.to_lower()
	if parse_type != 'osu':
		_SONG = get_song_data(song)
	else:
		var grossu = Osu.new()
		_SONG = grossu.load_file(song)
	
	if _SONG.has('scrollSpeed'): parse_type = 'v_slice'
	if _SONG.has('codenameChart'): parse_type = 'codename'
	if _SONG.has('gf'): parse_type = 'fps_plus'
	if _SONG.has('players'): parse_type = 'maru'

	var meta_path:String = 'res://assets/songs/'+ song +'/%s.json'
	var meta:Dictionary = {}
	match parse_type:
		'v_slice':
			meta = JSON.parse_string(FileAccess.open(meta_path % ['metadata'+ song_variant], FileAccess.READ).get_as_text())
			_SONG.speed = _SONG.scrollSpeed[diff] if _SONG.scrollSpeed.has(diff) else _SONG.scrollSpeed.default
			_SONG.player1 = meta.playData['characters'].player
			_SONG.gfVersion = meta.playData['characters'].girlfriend
			_SONG.player2 = meta.playData['characters'].opponent
			_SONG.stage = stage_to(meta.playData.stage)
			_SONG.song = meta.songName
			_SONG.bpm = meta.timeChanges[0].bpm
		'maru':
			_SONG.player1 = _SONG.players[0]
			_SONG.player2 = _SONG.players[1]
			_SONG.gfVersion = _SONG.players[2]
		'codename':
			meta = JSON.parse_string(FileAccess.open(meta_path % ['meta'], FileAccess.READ).get_as_text())
			_SONG.speed = _SONG.scrollSpeed
			_SONG.song = meta.displayName
			_SONG.bpm = meta.bpm
			for i in _SONG.strumLines:
				match i.position:
					'boyfriend': _SONG.player1 = i.characters[0]
					'girlfriend': _SONG.gfVersion = i.characters[0]
			if !_SONG.has('player2') and _SONG.has('gfVersion'):
				_SONG.player2 = _SONG.gfVersion
	
	print('Got "'+ parse_type +'" Chart')
	if auto_create:
		generate_chart(_SONG)

func get_song_data(song:String) -> Dictionary:
	if parse_type.is_empty(): parse_type = 'psych_v1'
	
	var json = you_WILL_get_a_json(song)
	var parsed = JSON.parse_string(json.get_as_text())
	if parsed.has('song') and parsed.song is Dictionary:
		parsed = parsed.song # i dont want to have to do no SONG.song.bpm or something
		if parse_type == 'psych_v1': parse_type = 'legacy'
		
	return parsed 

func reform_parts(song:String) -> void:
	parse_type = 'psych'
	var in_folder := DirAccess.get_files_at('res://assets/songs/'+ song +'/charts/')
	var to_parse:Array = []
	for i:String in in_folder:
		if i.begins_with('part'):
			to_parse.append(i)
			
	var chart = Chart.new()
	var temp_SONG = {}
	var added_first:bool = false
	for i in to_parse:
		print(i)
		var le_file = FileAccess.open('res://assets/songs/'+ song +'/charts/'+ i, FileAccess.READ).get_as_text()
		var parsed = JSON.parse_string(le_file)
		if !added_first:
			added_first = true
			temp_SONG = parsed.song
		else:
			temp_SONG.notes.append(parsed.song.notes)
		chart_notes.append(chart.load_common(parsed.song))
		
	_SONG = temp_SONG

func you_WILL_get_a_json(song:String) -> FileAccess:
	var path:String = 'res://assets/songs/%s/charts/' % song
	var returned:String
	
	if parse_type == 'v_slice':
		returned = path.replace('charts/', '') +'chart'+ song_variant
	else:
		returned = path + get_diff
	returned += '.json'
	
	if !ResourceLoader.exists(returned):
		printerr(song +' has no '+ get_diff +' | '+ returned)
		get_diff = 'hard'
		return you_WILL_get_a_json('tutorial')

	#ResourceLoader.load_threaded_request(path)
	print('Got json: '+ returned)
	return FileAccess.open(returned, FileAccess.READ)

func stage_to(stage:String) -> String:
	match stage.replace('Erect', ''):
		'spookyMansion': return 'spooky'
		'limoRide': return 'limo'
		'phillyTrain': return 'philly'
		'phillyStreets': return 'philly-streets'
		'phillyBlazin': return 'philly-blazin'
		'mallXmas': return 'mall'
		'mallXmasEvil': return 'mall-evil'
		'school': return 'school'
		'schoolEvil': return 'school-evil'
		'tankmanBattlefield': return 'tank'
		_: return 'stage'

func generate_chart(data, keep_loaded:bool = true) -> Array:
	if data == null: 
		return parse_song('tutorial', get_diff)
	
	var chart = Chart.new()
	var _notes := chart.load_chart(data, parse_type, get_diff) # get diff here only matters for base game as of now
	song_events = chart.get_events(data) # load events whenever chart is made

	if keep_loaded:
		chart_notes = _notes.duplicate()
		
	return _notes

func get_character(character:String = 'bf'):
	var json_path = 'res://assets/data/characters/%s.json' % character
	var return_json
	if !ResourceLoader.exists(json_path):
		printerr('JSON: get_character | [%s.json] COULD NOT BE FOUND' % character);
		return null
	var file = FileAccess.open(json_path, FileAccess.READ).get_as_text()
	return_json = JSON.parse_string(file)
	if return_json.has('no_antialiasing'): return_json.type = 'psych'
	return return_json

func parse_week(week:String = 'week1') -> Dictionary: # in week folder
	week = week.to_lower().strip_edges().replace('.json', '')
	var week_json = FileAccess.open('res://assets/data/weeks/'+ week +'.json', FileAccess.READ)
	if week_json == null: return {}
	var json = JSON.parse_string(week_json.get_as_text())
	json.file_name = week
	return json
