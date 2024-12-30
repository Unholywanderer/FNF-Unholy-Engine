extends Node2D

signal beat_hit(beat:int)
signal step_hit(step:int)
signal section_hit(section:int)
signal song_end

var bpm:float = 100.0:
	set(new_bpm):
		bpm = new_bpm
		#crochet = ((60.0 / bpm) * 1000.0)
		#step_crochet = crochet / 4.0

var crochet:float:
	get: return ((60.0 / bpm) * 1000.0)
var step_crochet:float:
	get: return crochet / 4.0
	
var song_pos:float = 0.0:
	set(new_pos): 
		song_pos = new_pos
		if song_pos < 0: 
			song_started = false
			for_all_audio('stop')

var playback_rate:float = 1.0:
	get: return AudioServer.playback_speed_scale
	set(rate): 
		playback_rate = rate
		AudioServer.playback_speed_scale = rate
		for i in Game.scene.get_child_count():
			if Game.scene.get_child(i) is AnimatedSprite2D:
				Game.scene.get_child(i).speed_scale = rate
		#Engine.time_scale = 1
		
var safe_zone:float = 166.0
var song_length:float = INF

var beat_time:float = 0.0
var step_time:float = 0.0

var cur_beat:int = 0
var cur_step:int = 0
var cur_section:int = 0

var last_beat:int = -1
var last_step:int = -1
var last_section:int = -1

var song_loaded:bool = false # song audio files have been added
var song_started:bool = false # song has begun to/is playing
var paused:bool = false:
	set(pause): 
		paused = pause
		pause()

var mult_vocals:bool = false
var inst = AudioStreamPlayer.new()
var vocals = AudioStreamPlayer.new()
var vocals_opp = AudioStreamPlayer.new()

var bpm_changes
func _ready():
	add_child(inst)
	add_child(vocals)
	add_child(vocals_opp)
	inst.bus = 'Instrumental'
	vocals.bus = 'Vocals'
	vocals_opp.bus = 'Vocals'
	
func load_song(song:String = '') -> void:
	if song.is_empty():
		printerr('Conductor.load_song: NO SONG ENTERED')
		song = 'tutorial'
	
	song = Game.format_str(song)
	var path:String = 'res://assets/songs/'+ song +'/audio/%s.ogg' # myehh
	if JsonHandler.song_variant != '':
		var inf = [JsonHandler.song_root, JsonHandler.song_variant.substr(1)]
		path = 'res://assets/songs/'+ inf[0] +'/audio/'+ inf[1] +'/%s.ogg'

	if JsonHandler.parse_type == 'osu':
		if ResourceLoader.exists('res://assets/songs/'+ song +'/audio.mp3'):
			inst.stream = load('res://assets/songs/'+ song +'/audio.mp3')
	else:
		var suffix:String = ''
		if JsonHandler._SONG.has('variant'): suffix += ('-'+ JsonHandler._SONG.variant)
		
		if ResourceLoader.exists(path % ['Inst'+ suffix]):
			inst.stream = load(path % ['Inst'+ suffix])
		if ResourceLoader.exists(path % ['Voices-player'+ suffix]):
			mult_vocals = true
			vocals.stream = load(path % ['Voices-player'+ suffix])
			vocals_opp.stream = load(path % ['Voices-opponent'+ suffix])
		elif ResourceLoader.exists(path % ['Voices'+ suffix]):
			mult_vocals = false
			vocals.stream = load(path % ['Voices'+ suffix])
	
	if inst.stream:
		song_length = inst.stream.get_length() * 1000.0
		
	song_loaded = true

func _process(delta):
	if paused: return

	if song_loaded:
		song_pos += (1000 * delta) * playback_rate
	
	if song_pos > 0:
		if !song_started: 
			start()
			return

		if song_pos > beat_time + crochet:
			beat_time += crochet
			cur_beat += 1
			beat_hit.emit(cur_beat)
			
			var beats:int = 4
			if JsonHandler.parse_type == 'legacy' and Game.scene != null and Game.scene.get('SONG') != null:
				var son = Game.scene.SONG
				if son.notes.size() > cur_section and son.has('notes') and son.notes[cur_section].has('sectionBeats'):
					beats = son.notes[cur_section].sectionBeats
				
			if cur_beat % beats == 0:
				cur_section += 1
				section_hit.emit(cur_section)
			
		if song_pos > step_time + step_crochet:
			step_time += step_crochet
			cur_step += 1
			step_hit.emit(cur_step)
			
		if song_pos >= song_length and song_loaded:
			print('Song Finished')
			song_end.emit()
		
		for audio in [inst, vocals, vocals_opp]:
			if audio.stream and audio.playing:
				if absf((audio.get_playback_position() * 1000) - (song_pos + Prefs.offset)) > 20: 
					resync_audio()
				
func connect_signals(scene = null) -> void: # connect all signals
	var sce = scene if scene != null else Game.scene
	for i in ['beat_hit', 'step_hit', 'section_hit', 'song_end']:
		if Game.scene.has_method(i):
			get(i).connect(Callable(sce, i))
	
func check_resync(sound:AudioStreamPlayer) -> void: # resyncs a sound to the song position
	if absf(sound.get_playback_position() * 1000.0 - song_pos) > 20:
		sound.seek(song_pos / 1000.0)
		print('resynced')

func resync_audio() -> void:
	for_all_audio('seek', ((song_pos + Prefs.offset) / 1000.0))
	print('resynced audios')

func stop() -> void:
	song_pos = 0
	for_all_audio('stop', true)
	reset_beats()

func pause() -> void: # NOTE: you shouldn't call this function, you should set Conductor.paused instead
	for_all_audio('stream_paused', paused, true)

func start(at_point:float = -1) -> void:
	song_started = true # lol
	if at_point > -1:
		song_pos = absf(at_point) / 1000.0
	for_all_audio('play', song_pos)

# so you dont have to personally check if a vocal/vocal.stream is null
func vocal_volume(da_vocal:String = 'vocals', to_vol:float = 1.0):
	var le_voices = get(da_vocal.to_lower())
	if le_voices != null and le_voices.stream:
		le_voices.volume_db = linear_to_db(0)
		
func for_all_audio(do:String, arg = null, is_var:bool = false) -> void:
	for audio in [inst, vocals, vocals_opp]:
		if !audio.stream: continue
		if is_var: 
			audio.set(do, arg)
		else:
			if do == 'stop':
				audio.stop()
				if arg == true: audio.stream = null
				continue
			audio.call(do, arg)
			
func reset() -> void:
	song_started = false
	song_loaded = false
	stop()
	bpm = 100

func reset_beats() -> void:
	beat_time = 0; step_time = 0;
	cur_beat = 0; cur_step = 0; cur_section = 0;
	last_beat = -1; last_step = -1; last_section = -1;
	paused = false
