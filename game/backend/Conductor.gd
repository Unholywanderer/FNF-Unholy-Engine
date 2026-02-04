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

## Changes the song's rate. Higher = faster
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

var cur_beat:float = 0.0

var cur_step:float = 0.0:
	get: return cur_beat * 4

var cur_section:int = 0:
	# NOTE to self, change this when you want to figure out time sigs
	get: return floori(cur_beat / 4.0)

## If the song audio files are actually loaded/added
var song_loaded:bool = false
## If the song has begun/song position is greater than 0
var song_started:bool = false
## Pauses the Conductor. Prevents the audio and song position from changing automatically.
var paused:bool = false:
	set(pause):
		paused = pause
		audio.stream_paused = pause
		audio.process_mode = Node.PROCESS_MODE_DISABLED if pause else Node.PROCESS_MODE_INHERIT
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

var bpm_changes:Array[BPMChange] = []
func _ready():
	audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.bus = 'Instrumental'
	audio.finished.connect(func(): # need this so it ends the song consistently
		print('Song Finished')
		song_end.emit()
	)

	#inst.bus = 'Instrumental'
	#vocals.bus = 'Vocals'
	#vocals_opp.bus = 'Vocals'

func load_song(song:String = '') -> void:
	if song.is_empty(): song = 'tutorial'
	reset_beats()

	song = Util.format_str(song)
	mult_vocals = false
	total_streams = 0

	var grabbed_audios:Array = []
	var path:String = 'res://assets/songs/'+ song +'/audio/%s.ogg' # myehh
	if !JsonHandler.song_variant.is_empty():
		var inf = [JsonHandler.song_root, JsonHandler.song_variant.substr(1)]
		path = 'res://assets/songs/'+ inf[0] +'/audio/'+ inf[1] +'/%s.ogg'

	var grab_audio = func(mod_folder:bool = false):
		#var pa = Util.file_path(path)
		if JsonHandler.parse_type == 'osu':
			if ResourceLoader.exists('res://assets/songs/'+ song +'/audio.mp3'):
				grabbed_audios.append(load('res://assets/songs/'+ song +'/audio.mp3'))
		else:
			var suffix:String = ''
			if JsonHandler.SONG.has('variant'): suffix += ('-'+ JsonHandler.SONG.variant)

			var check_func:Callable = ResourceLoader.exists
			var load_func:Callable = load
			var check_path:String = path
			if mod_folder:
				check_func = FileAccess.file_exists
				load_func = Util.load_audio
				check_path = path.replace('res://assets/', Game.exe_path +'mods/')

			if check_func.call(check_path % ['Inst'+ suffix]):
				grabbed_audios.append(load_func.call(check_path % ['Inst'+ suffix]))
			if check_func.call(check_path % ['Voices-player'+ suffix]):
				mult_vocals = true
				grabbed_audios.append(load_func.call(check_path % ['Voices-player'+ suffix]))
				grabbed_audios.append(load_func.call(check_path % ['Voices-opponent'+ suffix]))
			elif check_func.call(check_path % ['Voices'+ suffix]):
				grabbed_audios.append(load_func.call(check_path % ['Voices'+ suffix]))

	grab_audio.call()
	if grabbed_audios.is_empty():
		grab_audio.call(true)

	audio.stream = AudioStreamSynchronized.new()
	total_streams = grabbed_audios.size()
	for i in total_streams:
		audio.stream.set_sync_stream(i, grabbed_audios[i])
		set(['inst', 'vocals', 'vocals_opp'][i], audio.stream.get_sync_stream(i))

	if inst: song_length = roundf(inst.get_length() * 1000.0)

	audio.stream_paused = true
	song_loaded = true
	print('there are (%s) bpm changes!' % bpm_changes.size())

var _resync_timer:float = 0.0
var _last_time:float = 0.0
func _process(delta) -> void:
	if song_loaded:
		if audio and audio.playing:
			var aud_pos:float = (audio.get_playback_position() + AudioServer.get_time_since_last_mix()) * 1000
			if aud_pos == _last_time:
				_resync_timer += AudioServer.get_time_to_next_mix()
			else:
				_resync_timer = 0

			_last_time = aud_pos
			song_pos = aud_pos + _resync_timer * playback_rate
		else:
			song_pos += delta * 1000 * playback_rate

	if song_pos > 0:
		if !song_started:
			return start()

		var prev_beat:int = floori(cur_beat)
		var prev_step:int = floori(cur_step)
		var prev_sec:int = floori(cur_section)

		update_beats()

		if prev_beat != floori(cur_beat):
			beat_hit.emit(floori(cur_beat))
		if prev_step != floori(cur_step):
			step_hit.emit(floori(cur_step))
		if prev_sec != floori(cur_section):
			section_hit.emit(floori(cur_section))

		for i in bpm_changes:
			if i.time <= song_pos and !i.test:
				i.test = true
				print('BPM Change [%s] at %s' % [i.bpm, i.time])

func connect_signals(scene = null) -> void: # connect all signals
	var this:Node = scene if scene else Game.scene
	for i in ['beat_hit', 'step_hit', 'section_hit', 'song_end']:
		if this.has_method(i):
			get(i).connect(Callable(this, i))

func add_audio(new_id:int = -1, file_name:String = 'Voices', vol:float = 0.7, song_name:String = '') -> void:
	if song_name.is_empty(): song_name = JsonHandler.song_root
	if file_name.is_empty(): file_name = 'Voices'
	if new_id < 0: new_id = total_streams
	if new_id >= total_streams:
		for i in range(total_streams, new_id):
			total_streams += 1
	var path_to_check:String = 'assets/songs/%s/audio/%s.ogg' % [song_name, file_name]
	if !ResourceLoader.exists('res://'+ path_to_check):
		return printerr('No audio file at '+ path_to_check)

	var new_aud = load('res://'+ path_to_check)
	audio.stream.set_sync_stream(new_id, new_aud)
	audio_volume(new_id, vol)
	ex_audio.append(new_aud)

func audio_volume(id:int, vol:float = 1.0, _can_wrap:bool = true) -> void:
	if !audio or !audio.stream: return
	var stream_count:int = total_streams - 1
	#if id > stream_count: printerr('ID '+ str(id) +' doesn\'t exist!')
	if id > stream_count: return
	#id = clampi(id, 0, stream_count)
	audio.stream.set_sync_stream_volume(id, linear_to_db(vol))

func stop() -> void:
	song_pos = 0
	audio.stop()
	audio.stream = null
	reset_beats()

## Start the song and play the audio tracks at the designated point
func start(at:float = -1) -> void:
	song_started = true # lol
	if at > -1:
		song_pos = at
	audio.play(max(at, 0)) # seek is actually stupid i hate it grrr
	#audio.seek(song_pos)

func seek(point:float, auto_pause:bool = true, incriment:bool = false) -> void:
	if point < 0: point = 0
	if incriment: point = song_pos + point
	audio.play(point / 1000.0)
	if auto_pause: paused = true
	_last_time = point
	song_pos = point
	update_beats()

func reset() -> void:
	song_started = false
	song_loaded = false
	stop()
	bpm = 100
	bpm_changes.clear()

func reset_beats() -> void:
	beat_time = 0; step_time = 0;
	cur_beat = 0; cur_step = 0; cur_section = 0;
	paused = false

func add_bpm_changes(SONG:Dictionary) -> void:
	var _time:float = 0.0
	var _bpm:float = SONG.bpm

	var first := BPMChange.new() # staring bpm
	first.bpm = _bpm
	bpm_changes.push_front(first)

	match JsonHandler.parse_type:
		'v_slice':
			for i in JsonHandler.META.timeChanges:
				var new_change := BPMChange.new()
				new_change.time = i.t
				new_change.bpm = i.bpm
				bpm_changes.append(new_change)
		'codename':
			for i in SONG.events:
				if i.name != 'BPM Change': continue
				var new_change := BPMChange.new()
				new_change.time = i.time
				new_change.bpm = i.params[0]
				bpm_changes.append(new_change)
		_:
			for sec in SONG.notes:
				if sec.get('changeBPM', false) and sec.get('bpm', _bpm) != _bpm:
					_bpm = sec.bpm
					var new_change := BPMChange.new()
					new_change.time = _time
					new_change.bpm = _bpm
					print('BPM change (%s) at (%s)' % [_bpm, _time])

					bpm_changes.append(new_change)
				var _sec_beats:int = sec.get('sectionBeats', 4) # psych thangs
				_time += ((60.0 / _bpm) * 1000.0) * _sec_beats

	bpm_changes.sort_custom(func(a, b): return a.time < b.time)

func update_beats() -> void: # stole a lot of this from cherry
	if bpm_changes.is_empty():
		cur_beat = song_pos / crochet
		return

	cur_beat = 0
	bpm = bpm_changes[0].bpm

	var prev_time:float = 0.0
	for change:BPMChange in bpm_changes:
		if song_pos < change.time: break

		cur_beat += (change.time - prev_time) / crochet
		prev_time = change.time
		bpm = change.bpm

	cur_beat += (song_pos - prev_time) / crochet

class BPMChange extends Resource:
	var bpm:float = 100
	var time:float = 0.0
	var signature:String = '4/4'
	var test:bool = false
