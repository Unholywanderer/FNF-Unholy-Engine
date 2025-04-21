extends Node

var song_scores:ConfigFile = ConfigFile.new()
const PASSWORD = 'am i am?' # kinda like a version control, if changed, will delete data and start anew
const DEFAULT_DATA = [0, 0, 0, 'N/A', 0] # score, accuracy, misses, FC, last combo
const DEFAULT_LAYOUT = {
	'easy' = DEFAULT_DATA,
	'normal' = DEFAULT_DATA,
	'hard' = DEFAULT_DATA
}

# high scores wont all save at once now
# it will only save once you actually play and beat the song
func _ready() -> void:
	var save_check
	save_check = song_scores.load_encrypted_pass('user://highscores.cfg', PASSWORD) #.load_encrypted_pass('user://highscores.cfg', PASSWORD)
	if save_check != OK:
		if FileAccess.file_exists('user://highscores.cfg'):
			DirAccess.remove_absolute('user://highscores.cfg')
		save_n_load()
	#if ResourceLoader.exists('user://highscores.cfg'):
		#if save_check != OK:
		# old format and not encrypted, delete it
	#else:
	#	save_n_load()

func init_save():
	pass

func get_data(song:String, diff:String = ''):
	var data = song_scores.get_value(get_section(), Util.format_str(song), DEFAULT_LAYOUT)
	if !diff.is_empty():
		diff = diff.to_lower()
		data = data[diff] if data.has(diff) else DEFAULT_DATA
	return data

func get_score(song:String, diff:String = 'hard'): # just need the score, for readability
	return get_data(song, diff)[0]
	
func add_week(week_name:String, diffs:Array = ['easy', 'normal', 'hard']):
	pass
	
func get_week_score(week_name:String, diff:String = 'hard'):
	var DEFAULT_WEEK = {}
	var week_data = song_scores.get_value(get_section(), week_name.to_lower().strip_edges())
	
	pass

func compile_data(song_list:Array[String], diff:String = 'hard') -> Array[int]: # get all score + misses from selected songs
	var totals:Array[int] = [0, 0]
	for song in song_list:
		var to_add = get_data(song, diff)
		totals[0] += to_add[0] # da score
		totals[1] += to_add[2] # da misses
		
	return totals
	
func set_score(song:String, diff:String = 'hard', data:Array = DEFAULT_DATA) -> void:
	var sec = get_section()
	song = Util.format_str(song)
	diff = diff.to_lower()
	if !song_scores.has_section_key(sec, song):
		add_key(song, [diff])
	
	var saved_data:Dictionary = get_data(song)
	saved_data[diff] = data
	song_scores.set_value(sec, song, saved_data)
	print('HighScore: saved score for '+ song +' | '+ diff)
	save_n_load()
	
func set_data(song:String, data:Dictionary = DEFAULT_LAYOUT):
	var sec = get_section()
	song = Util.format_str(song)
	if !song_scores.has_section_key(sec, song):
		add_key(song)
	song_scores.set_value(sec, song, data)
	
func clear_score(song:String, diff:String = 'hard', clear_all:bool = false,) -> void:
	song_scores.load_encrypted_pass('user://highscores.cfg', PASSWORD)
	var sec = get_section()
	song = Util.format_str(song)
	if !song_scores.has_section_key(sec, song):
		print('HighScore: No data exists for "'+ song +'"')
		return
	
	diff = diff.to_lower()
	var saved_data:Dictionary = get_data(song)
	if !saved_data.has(diff) or saved_data[diff] == DEFAULT_DATA:
		print('HighScore: No "'+ diff +'" data in "'+ song +'" to clear')
		return
		
	if clear_all:
		for i in saved_data.keys(): 
			saved_data[i] = DEFAULT_DATA
	else:
		saved_data[diff] = DEFAULT_DATA
		
	song_scores.set_value(sec, song, saved_data)
	
	save_n_load()
	
func save_n_load() -> void: # very
	#if FileAccess.file_exists('user://highscores.cfg'):
	#	song_scores.load_encrypted_pass('user://highscores.cfg', PASSWORD)
	song_scores.save_encrypted_pass('user://highscores.cfg', PASSWORD)
	song_scores.load_encrypted_pass('user://highscores.cfg', PASSWORD)
	
func add_key(key:String, diffs:Array = ['easy', 'normal', 'hard']) -> void:
	if key.is_empty(): 
		printerr('HighScore: add_key() | Value is empty')
		return
	
	key = Util.format_str(key)
	var layout = {}
	for i:String in diffs:
		if get_data(key, i.to_lower()) != DEFAULT_DATA:
			layout[i] = get_data(key, i.to_lower())
	song_scores.set_value(get_section(), key, layout)
	#print('added '+ key +': '+ str(diffs))
	#save_n_load()
	
func get_section() -> String: return 'Legacy Scores' if Prefs.legacy_score else 'Song Scores'
