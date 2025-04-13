extends Node2D;

const base_diffs:PackedStringArray = ['easy', 'normal', 'hard']
var song_diffs:Array = []
var get_diff:String

var _SONG:Dictionary = {} # change name of this to like SONG_DATA or something
var song_variant:String = '' # (erect, pico mix and whatnot)
var song_root:String = ''
var note_count:int = 0

var chart_notes:Array = [] # keep loaded chart and events for restarting songs
var song_events:Array[EventData] = []

var parse_type:String = ''
func parse_song(song:String, diff:String, variant:String = '', auto_create:bool = true):
	_SONG.clear()
	song_root = ''
	song_variant = ''
	parse_type = 'legacy'
	note_count = 0

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
	#if _SONG.has('gf'): parse_type = 'fps_plus'
	if _SONG.has('players'): parse_type = 'maru'

	var meta_path:String = 'res://assets/songs/'+ song +'/%s.json'
	var meta:Dictionary = {}
	match parse_type:
		'v_slice':
			meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path % ['metadata'+ song_variant]))
			_SONG.speed = _SONG.scrollSpeed[diff] if _SONG.scrollSpeed.has(diff) else _SONG.scrollSpeed.default
			_SONG.player1 = meta.playData['characters'].player
			_SONG.gfVersion = meta.playData['characters'].girlfriend
			_SONG.player2 = meta.playData['characters'].opponent
			_SONG.stage = stage_to(meta.playData.stage)
			_SONG.song = meta.songName
			_SONG.bpm = meta.timeChanges[0].bpm
			if meta.timeChanges.size() > 1:
				var times = meta.timeChanges.duplicate(true)
				times.remove_at(0) # skip first one
				for i in times:
					_SONG.events.append({'t': i.t, 'e': 'ChangeBPM', 'v': i.bpm})
		'maru':
			_SONG.player1 = _SONG.players[0]
			_SONG.player2 = _SONG.players[1]
			_SONG.gfVersion = _SONG.players[2]
		'codename':
			meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path % ['meta']))
			_SONG.speed = _SONG.scrollSpeed
			_SONG.song = meta.name
			_SONG.bpm = meta.bpm
			for i in _SONG.strumLines:
				match i.position:
					'boyfriend': _SONG.player1 = i.characters[0]
					'girlfriend': _SONG.gfVersion = i.characters[0]
					'dad': _SONG.player2 = i.characters[0]
			if !_SONG.has('player2') and _SONG.has('gfVersion'):
				_SONG.player2 = _SONG.gfVersion
	
	print('Got "'+ parse_type +'" Chart')
	if auto_create:
		generate_chart(_SONG)

func get_song_data(song:String) -> Dictionary:
	var json = you_WILL_get_a_json(song)
	var parsed = JSON.parse_string(json.get_as_text())
	if parsed.has('song'):
		if parsed.has('format') and parsed.format.contains('psych_v1'):
			parse_type = 'psych_v1'
		if parsed.song is Dictionary:
			parsed = parsed.song # i dont want to have to do no SONG.song.bpm or something
		
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
		var err_path = returned.replace('res://assets/songs/', '../')
		Alert.make_alert('"%s" has no %s\n%s' % [song, get_diff.to_upper(), err_path], Alert.ERROR) #printerr(song +' has no '+ get_diff +' | '+ returned)
		get_diff = 'hard'
		return you_WILL_get_a_json('tutorial')

	#ResourceLoader.load_threaded_request(path)
	print('Got json: '+ returned)
	return FileAccess.open(returned, FileAccess.READ)

func stage_to(stage:String) -> String:
	var le_stage:String = 'stage'
	match stage.replace('Erect', '').replace('Pico', ''):
		'spookyMansion': le_stage = 'spooky'
		'limoRide'     : le_stage = 'limo'
		'phillyTrain'  : le_stage = 'philly'
		'phillyStreets': le_stage = 'philly-streets'
		'phillyBlazin' : le_stage = 'philly-blazin'
		'mallXmas'     : le_stage = 'mall'
		'mallEvil'     : le_stage = 'mall-evil'
		'school'       : le_stage = 'school'
		'schoolEvil'   : le_stage = 'school-evil'
		'tankmanBattlefield': le_stage = 'tank'
	if stage.ends_with('Erect') or stage.ends_with('Pico'): 
		le_stage += '-erect'
	return le_stage

func generate_chart(data, keep_loaded:bool = true) -> Array:
	if data == null: 
		return parse_song('tutorial', get_diff)
	
	var chart = Chart.new()
	var _notes := chart.load_chart(data, parse_type, get_diff) # get diff here only matters for base game as of now
	song_events = chart.get_events(data) # load events whenever chart is made
	#note_count = chart.get_must_hits(_notes).size() # change this later future me
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
	return return_json

func parse_week(week:String = 'week1') -> Dictionary: # in week folder
	week = week.strip_edges().replace('.json', '')
	var week_json = FileAccess.open('res://assets/data/weeks/'+ week +'.json', FileAccess.READ)
	if week_json == null: return {}
	var json = JSON.parse_string(week_json.get_as_text())
	json.file_name = week
	return json
