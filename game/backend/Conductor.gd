extends Node2D

signal beat_hit(beat:int)
signal step_hit(step:int)
signal section_hit(section:int)
signal song_end

var bpm:float = 100.0
# 128 practice
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
	get: return audio.pitch_scale
	set(rate):
		playback_rate = rate
		audio.pitch_scale = rate
		#AudioServer.playback_speed_scale = rate
		for i in Game.scene.get_children(true):
			if i is AnimatedSprite2D:
				i.speed_scale = rate

var safe_zone:float = 166.0
var song_length:float = INF

var beat_time:float = 0.0
var step_time:float = 0.0

var cur_beat:int = 0
var beat_dec:float = 0.0
var cur_step:int = 0
var cur_section:int = 0

## If the song audio files are actually loaded/added
var song_loaded:bool = false
## If the song has begun/song position is greater than 0
var song_started:bool = false
## To pause the Conductor
var paused:bool = false:
	set(pause):
		paused = pause
		audio.stream_paused = pause
		set_process(!pause)

var mult_vocals:bool = false
var total_streams:int:
	get: return audio.stream.stream_count if audio.stream else 0
	set(total): if audio.stream: audio.stream.stream_count = abs(total)

var audio:AudioStreamPlayer
var inst:AudioStream
var vocals:AudioStream # make this an array for vocals at this rate
var vocals_opp:AudioStream
var ex_audio:Array[AudioStream] = []

var bpm_changes = {}
func _ready():
	audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.bus = 'Instrumental'
	audio.finished.connect(func(): # need this so it ends the song consistently
		print('Song Finished')
		song_end.emit()
	)
	#add_child(inst)
	#add_child(vocals)
	#add_child(vocals_opp)
	#inst.bus = 'Instrumental'
	#vocals.bus = 'Vocals'
	#vocals_opp.bus = 'Vocals'

func load_song(song:String = '') -> void:
	if song.is_empty(): song = 'tutorial'

	song = Util.format_str(song)
	mult_vocals = false
	total_streams = 0

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

	audio.stream = AudioStreamSynchronized.new()
	total_streams = grabbed_audios.size()
	for i in total_streams:
		audio.stream.set_sync_stream(i, grabbed_audios[i])
		set(['inst', 'vocals', 'vocals_opp'][i], audio.stream.get_sync_stream(i))

	if inst: song_length = roundf(inst.get_length() * 1000.0)

	audio.stream_paused = true
	song_loaded = true

var _resync_timer:float = 0.0
var _last_time:float = 0.0
var raw_time:float
func _process(delta) -> void:
	if song_loaded:
		if audio and audio.playing:
			var aud_pos:float = audio.get_playback_position() * 1000
			if aud_pos == _last_time:
				_resync_timer += delta * 1000
			else:
				_resync_timer = 0
			_last_time = aud_pos

			song_pos = aud_pos + _resync_timer * playback_rate
		else:
			song_pos += delta * 1000 * playback_rate

	if song_pos > 0:
		if !song_started:
			return start()

		if song_pos > beat_time + crochet:
			beat_time += crochet
			cur_beat += 1
			beat_hit.emit(cur_beat)

			var beats:int = 4
			if JsonHandler.parse_type == 'legacy' and Game.scene:
				var son = Game.scene.get('SONG')
				if son and son.get('notes', []).size() > cur_section:
					beats = son.notes[cur_section].get('sectionBeats', 4)

			if cur_beat % beats == 0:
				cur_section += 1
				section_hit.emit(cur_section)

		if song_pos > step_time + step_crochet:
			step_time += step_crochet
			cur_step += 1
			step_hit.emit(cur_step)

		#if song_pos >= song_length:
		#	print('Song Finished')
		#	song_end.emit()

		# moved to line 118
		#if audio.playing:
			#if absf((audio.get_playback_position() * 1000) - (song_pos + Prefs.offset)) > 20:
				#resync_audio()

func connect_signals(scene = null) -> void: # connect all signals
	var this:Node = scene if scene else Game.scene
	for i in ['beat_hit', 'step_hit', 'section_hit', 'song_end']:
		if this.has_method(i):
			get(i).connect(Callable(this, i))

func add_audio(new_id:int = -1, file_name:String = '', vol:float = 0.7, song_name:String = '') -> void:
	if song_name.is_empty(): song_name = JsonHandler.song_root
	if file_name.is_empty(): file_name = 'Voices'
	if new_id < 0: new_id = total_streams
	var path_to_check:String = 'assets/songs/%s/audio/%s.ogg' % [song_name, file_name]
	if !ResourceLoader.exists('res://'+ path_to_check):
		printerr('No audio file at '+ path_to_check)
		return

	var new_aud = load('res://'+ path_to_check)
	total_streams += 1
	audio.stream.set_sync_stream(new_id, new_aud)
	audio_volume(new_id, vol)
	ex_audio.append(new_aud)

func audio_volume(id:int, vol:float = 1.0, can_wrap:bool = true) -> void:
	var stream_count = audio.stream.stream_count - 1
	#if id > stream_count: printerr('ID '+ str(id) +' doesn\'t exist!')
	if id > stream_count: return
	#id = clampi(id, 0, stream_count)
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

## Start the song and play the audio tracks at the designated point
func start(at_point:float = -1) -> void:
	song_started = true # lol
	if at_point > -1:
		song_pos = at_point
	audio.play(0) # seek is actually stupid i hate it grrr
	#audio.seek(song_pos)

func seek(point:float, auto_pause:bool = true) -> void:
	audio.play(point / 1000.0)
	if auto_pause: paused = true
	_last_time = point
	song_pos = point

func reset() -> void:
	song_started = false
	song_loaded = false
	stop()
	bpm = 100

func reset_beats() -> void:
	beat_time = 0; step_time = 0;
	cur_beat = 0; cur_step = 0; cur_section = 0;
	paused = false
