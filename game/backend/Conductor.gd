extends Node2D

signal beat_hit(beat:int)
signal step_hit(step:int)
signal section_hit(section:int)
signal song_end

var bpm:float = 100.0

var crochet:float:
	get: return ((60.0 / bpm) * 1000.0)
var step_crochet:float:
	get: return crochet / 4.0
	
var song_pos:float = 0.0:
	set(new_pos): 
		song_pos = new_pos
		if song_pos < 0: 
			song_started = false
			audio.stop()
			
var playback_rate:float = 1.0:
	get: return AudioServer.playback_speed_scale
	set(rate): 
		playback_rate = rate
		AudioServer.playback_speed_scale = rate
		for i in Game.scene.get_child_count():
			if Game.scene.get_child(i) is AnimatedSprite2D:
				Game.scene.get_child(i).speed_scale = rate

var safe_zone:float = 166.0
var song_length:float = INF

var beat_time:float = 0.0
var step_time:float = 0.0

var cur_beat:int = 0
var cur_step:int = 0
var cur_section:int = 0

var song_loaded:bool = false # song audio files have been added
var song_started:bool = false # song has begun to/is playing
var paused:bool = false:
	set(pause): 
		paused = pause
		pause()

var mult_vocals:bool = false
var total_streams:int:
	get: return audio.stream.stream_count if audio.stream else 0
	set(total): if audio.stream: audio.stream.stream_count = abs(total)
	
var audio:AudioStreamPlayer
var inst:AudioStream
var vocals:AudioStream # make this an array for vocals at this rate
var vocals_opp:AudioStream

var bpm_changes = {}
func _ready():
	audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.bus = 'Instrumental'
	#add_child(inst)
	#add_child(vocals)
	#add_child(vocals_opp)
	#inst.bus = 'Instrumental'
	#vocals.bus = 'Vocals'
	#vocals_opp.bus = 'Vocals'
	
func load_song(song:String = '') -> void:
	if song.is_empty(): song = 'tutorial'
	print('Cond 1')

	song = Game.format_str(song)
	mult_vocals = false
	total_streams = 0
	print('Cond 2')

	var grabbed_audios:Array = []
	var path:String = 'res://assets/songs/'+ song +'/audio/%s.ogg' # myehh
	if JsonHandler.song_variant != '':
		var inf = [JsonHandler.song_root, JsonHandler.song_variant.substr(1)]
		path = 'res://assets/songs/'+ inf[0] +'/audio/'+ inf[1] +'/%s.ogg'
	
	if JsonHandler.parse_type == 'osu':
		if ResourceLoader.exists('res://assets/songs/'+ song +'/audio.mp3'):
			grabbed_audios.append(load('res://assets/songs/'+ song +'/audio.mp3'))
	else:
		var suffix:String = ''
		if JsonHandler._SONG.has('variant'): suffix += ('-'+ JsonHandler._SONG.variant)
		
		if ResourceLoader.exists(path % ['Inst'+ suffix]):
			grabbed_audios.append(load(path % ['Inst'+ suffix]))
		if ResourceLoader.exists(path % ['Voices-player'+ suffix]):
			mult_vocals = true
			grabbed_audios.append(load(path % ['Voices-player'+ suffix]))
			grabbed_audios.append(load(path % ['Voices-opponent'+ suffix]))
		elif ResourceLoader.exists(path % ['Voices'+ suffix]):
			grabbed_audios.append(load(path % ['Voices'+ suffix]))
	print('Cond 3')
	
	audio.stream = AudioStreamSynchronized.new()
	total_streams = grabbed_audios.size()
	for i in total_streams:
		audio.stream.set_sync_stream(i, grabbed_audios[i])
		set(['inst', 'vocals', 'vocals_opp'][i], audio.stream.get_sync_stream(i))
		
	if inst:
		song_length = inst.get_length() * 1000.0
	print('Cond 4')
	
	audio.stream_paused = true
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
			
		if song_pos >= song_length:
			print('Song Finished')
			song_end.emit()
		
		if audio.playing:
			if absf((audio.get_playback_position() * 1000) - (song_pos + Prefs.offset)) > 20: 
				resync_audio()
			
func connect_signals(scene = null) -> void: # connect all signals
	var this_scene = scene if scene != null else Game.scene
	for i in ['beat_hit', 'step_hit', 'section_hit', 'song_end']:
		if Game.scene.has_method(i):
			get(i).connect(Callable(this_scene, i))

func add_voice(new_id:int, file_name:String, song_name:String) -> void:
	if song_name.is_empty(): song_name = JsonHandler.song_root
	var path_to_check:String = 'assets/songs/%s/audio/%s.ogg' % [song_name, file_name]
	if !ResourceLoader.exists('res://'+ path_to_check):
		printerr('No voice file at '+ path_to_check)
		return
	
	var voc = load('res://'+ path_to_check)
	audio.stream.stream_count += 1
	audio.stream.set_sync_stream(new_id, voc)

func audio_volume(id:int, vol:float = 1.0) -> void:
	var stream_count = audio.stream.stream_count - 1
	if id > stream_count: printerr('ID '+ str(id) +' doesn\'t exist!')
	id = clamp(id, 0, stream_count)
	audio.stream.set_sync_stream_volume(id, linear_to_db(vol))

func resync_audio() -> void:
	audio.seek((song_pos + Prefs.offset) / 1000.0)
	print('resynced audios')

func stop() -> void:
	song_pos = 0
	audio.stop()
	#for i in [inst, vocals, vocals_opp]: 
	#	if i != null and is_instance_valid(i): i.unreference()
	audio.stream = null
	reset_beats()

# NOTE: you shouldn't call this function, you should set Conductor.paused instead
func pause() -> void: audio.stream_paused = paused

func start(at_point:float = -1) -> void:
	song_started = true # lol
	if at_point > -1:
		song_pos = at_point
	audio.play(song_pos)

func reset() -> void:
	song_started = false
	song_loaded = false
	stop()
	bpm = 100

func reset_beats() -> void:
	beat_time = 0; step_time = 0;
	cur_beat = 0; cur_step = 0; cur_section = 0;
	paused = false
