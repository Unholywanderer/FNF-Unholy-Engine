extends Node2D;

const base_diffs:PackedStringArray = ['easy', 'normal', 'hard']
var song_diffs:PackedStringArray = []
var get_diff:String

var SONG:Dictionary = {} # change name of this to like SONG_DATA or something
var song_variant:String = '' # (erect, pico mix and whatnot)
var song_root:String = ''

var chart_notes:Array = [] # keep loaded chart and events for restarting songs
var song_events:Array[EventData] = []

var parse_type:String = ''
func parse_song(song:String, diff:String, variant:String = '', auto_create:bool = true) -> void:
	SONG.clear()
	song_root = ''
	song_variant = ''
	parse_type = 'legacy'

	if !variant.is_empty():
		if variant != 'normal' and !variant.begins_with('-'):
			variant = '-'+ variant
		else:
			variant = ''

	# TODO figure out a better way to get chart types, this a lil dookie
	song = Util.format_str(song)
	song_variant = variant
	song_root = song

	if Util.file_exists('songs/'+ song +'/chart'+ song_variant +'.json'):
		parse_type = 'v_slice'

	if FileAccess.file_exists('res://assets/songs/'+ song +'/charts/'+ diff +'.osu'):
		parse_type = 'osu'

	get_diff = diff.to_lower()
	if parse_type != 'osu':
		SONG = get_song_data(song)
	else:
		var grossu = Osu.new()
		SONG = grossu.load_file(song)
	if SONG.is_empty(): return

	if SONG.has('scrollSpeed'): parse_type = 'v_slice'
	if SONG.has('codenameChart'): parse_type = 'codename'
	#if SONG.has('gf'): parse_type = 'fps_plus'
	if SONG.has('players'): parse_type = 'maru'

	var meta_path:String = 'songs/'+ song +'/%s.json'
	var meta:Dictionary = {}
	match parse_type:
		'v_slice':
			meta = parse(Util.check_path(meta_path % ['metadata'+ song_variant]))
			SONG.speed = SONG.scrollSpeed.get(diff, SONG.scrollSpeed.get('default', 1))
			SONG.player1 = meta.playData['characters'].player
			SONG.gfVersion = meta.playData['characters'].get('girlfriend')
			SONG.player2 = meta.playData['characters'].opponent
			SONG.stage = stage_to(meta.playData.stage)
			var song_name:String = meta.songName
			if FileAccess.file_exists('res://assets/'+ meta_path % 'manifest'):
				song_name = parse(meta_path % 'manifest').songId
			SONG.song = song_name
			SONG.bpm = meta.timeChanges[0].bpm
			if meta.timeChanges.size() > 1:
				var times = meta.timeChanges.duplicate(true)
				times.remove_at(0) # remove first one
				for i in times:
					SONG.events.append({'t': i.t, 'e': 'ChangeBPM', 'v': i.bpm})
		'maru':
			SONG.player1 = SONG.players[0]
			SONG.player2 = SONG.players[1]
			SONG.gfVersion = SONG.players[2]
		'codename':
			meta = parse(meta_path % ['meta'])
			SONG.speed = SONG.scrollSpeed
			SONG.song = meta.name
			SONG.bpm = meta.bpm
			for i in SONG.strumLines:
				match i.position:
					'boyfriend': SONG.player1 = i.characters[0]
					'girlfriend': SONG.gfVersion = i.characters[0]
					'dad': SONG.player2 = i.characters[0]
			if !SONG.has('player2') and SONG.has('gfVersion'):
				SONG.player2 = SONG.gfVersion

	print('Got "'+ parse_type +'" Chart')
	if auto_create:
		generate_chart(SONG)

func get_song_data(song:String) -> Dictionary:
	var parsed = JSON.parse_string(you_WILL_get_a_json(song))
	if parsed == null:
		parsed = {song = song_root, bpm = 100, speed = 1, notes = [], player1 = 'bf', player2 = 'dad'}

	if parsed.has('song'):
		if parsed.has('format') and parsed.format.contains('psych_v1'):
			parse_type = 'psych_v1'
		if parsed.song is Dictionary:
			parsed = parsed.song # i dont want to have to do no SONG.song.bpm or something

	return parsed

func you_WILL_get_a_json(song:String) -> String:
	var path:String = 'res://assets/songs/%s/charts/' % song
	var returned:String = path + get_diff +'.json'

	if parse_type == 'v_slice':
		returned = path.replace('charts/', '') +'chart'+ song_variant +'.json'

	if !ResourceLoader.exists(returned):
		if FileAccess.file_exists(returned.replace('res://assets/', Game.exe_path +'mods/')):
			returned = returned.replace('res://assets/', Game.exe_path +'mods/')
		else:
			var err_path = returned.replace('res://assets/songs/', '../')
			Alert.make_alert('"%s" has no %s\n%s' % [song, get_diff.to_upper(), err_path], Alert.ERROR)
			return ''

	#ResourceLoader.load_threaded_request(path)
	print('Got json: '+ returned)
	#var le_file = ResourceLoader.load_threaded_request(returned, '', true)
	return FileAccess.get_file_as_string(returned)

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
	if data == null: return []

	var chart = Chart.new()
	var _notes := chart.load_chart(data, parse_type, get_diff) # get diff here only matters for base game as of now
	song_events = chart.get_events(data) # load events whenever chart is made

	if keep_loaded:
		chart_notes = _notes.duplicate(true)

	return _notes

func get_character(Char:String = 'bf'):
	var json_path:String = 'res://assets/data/characters/%s.json' % Char
	var return_json:Dictionary = {}
	if !ResourceLoader.exists(json_path):
		printerr('JSON: get_character | [%s.json] COULD NOT BE FOUND' % Char);
		return null
	return_json = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	return return_json

func parse_week(week:String = 'week1') -> Dictionary: # in week folder
	var week_json:Dictionary = parse('data/weeks/'+ week.strip_edges())
	week_json.file_name = week
	return week_json

func parse(path:String) -> Dictionary:
	path = path.strip_edges()
	if !path.ends_with('.json'): path += '.json'
	if !path.begins_with('res://'): path = 'res://assets/'+ path
	var file:String = FileAccess.get_file_as_string(Util.check_path(path))
	if file.is_empty(): return {}
	var le_json = JSON.parse_string(file)
	if le_json == null: le_json = {}
	return le_json
