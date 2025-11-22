extends Node2D

@onready var cam:Camera2D = $Camera
@onready var ui:CanvasLayer = $UI
@onready var other:CanvasLayer = $OtherUI # like psych cam other, above ui, and unaffected by ui zoom

@onready var Judge:Rating = Rating.new()

var story_mode:bool = false
var SONG

var cur_skin:String = 'default': # yes
	set(new_skin):
		ui.cur_skin = new_skin
		cur_skin = ui.cur_skin
var cur_speed:float = 1.0:
	set(new_speed):
		cur_speed = new_speed
		for note in notes: note.speed = cur_speed

var zoom_beat:int = 4
var zoom_add:Dictionary = {ui = 0.04, game = 0.045}

var chart_notes
var notes:Array[Note] = []
var events:Array[EventData] = []
var spawn_time:int = 2000

var song_idx:int = 0
var playlist:Array[String] = []

var key_names = ['note_left', 'note_down', 'note_up', 'note_right']

var should_save:bool = !Prefs.auto_play
var died:bool = false

@onready var auto_play:bool:
	set(auto):
		if auto: should_save = false
		auto_play = auto
		ui.get_group('player').is_cpu = auto_play
		ui.mark.visible = auto_play

var score:int = 0
var combo:int = 0
var misses:int = 0

func _ready():
	var spl_path = 'res://assets/images/ui/notesplashes/'+ Prefs.splash_sprite.to_upper() +'.res'
	Game.persist.note_splash = load(spl_path)

	auto_play = Prefs.auto_play # there is a reason
	if Game.persist.song_list.size() > 0:
		story_mode = true
		playlist = Game.persist.song_list

	SONG = JsonHandler.SONG

	if Prefs.daniel and !SONG.player1.contains('bf-girl'):
		var try = SONG.player1.replace('bf', 'bf-girl')
		var it_exists = ResourceLoader.exists('res://assets/data/characters/'+ try +'.json')
		SONG.player1 = try if it_exists else 'bf-girl'

	Conductor.load_song(SONG.song)
	Conductor.bpm = SONG.bpm

	Conductor.paused = false
	Conductor.connect_signals()
	cur_speed = SONG.speed

	ui.health_bar.scale = Vector2(0.8, 0.8)
	ui.icon_p1.change_icon(JsonHandler.get_character(Character.get_closest(SONG.player1)).icon, true)
	ui.icon_p2.change_icon(JsonHandler.get_character(Character.get_closest(SONG.player2)).icon)

	if SONG.has('stage') and SONG.stage.begins_with('school'):
		cur_skin = 'pixel'

	Judge.skin = ui.SKIN
	if Prefs.rating_cam == 'game':
		Judge.rating_pos = $Camera.position + Vector2(0, -40)
		Judge.combo_pos = $Camera.position + Vector2(-150, 70)
	elif Prefs.rating_cam == 'hud':
		Judge.rating_pos = Vector2(580, 300)
		Judge.combo_pos = Vector2(420, 420)

	Discord.change_presence('Starting '+ SONG.song.capitalize())

	if JsonHandler.chart_notes.is_empty():
		JsonHandler.generate_chart(SONG)

	chart_notes = JsonHandler.chart_notes.duplicate()
	events = JsonHandler.song_events.duplicate()
	print(SONG.song +' '+ JsonHandler.get_diff.to_upper())
	print('TOTAL EVENTS: '+ str(events.size()))

	ui.countdown_start.connect(countdown_start)
	ui.countdown_tick.connect(countdown_tick)
	ui.song_start.connect(song_start)

	ui.start_countdown(true)

	section_hit(0) #just for 1st section stuff

var section_data
var chunk:int = 0
func _process(delta):
	if Input.is_key_pressed(KEY_R): ui.hp = 0
	if ui.hp <= 0 and !died: try_death()

	if Input.is_action_just_pressed("debug_1"):
		if JsonHandler.parse_type == 'v_slice':
			Audio.play_sound('cancelMenu')
			return
		await RenderingServer.frame_post_draw
		Game.switch_scene('debug/Charting_Scene')

	if Input.is_action_just_pressed("back"):
		auto_play = !auto_play
	if Input.is_action_just_pressed("accept"):
		Conductor.resync_audio()
		get_tree().paused = true
		other.add_child(load('res://game/scenes/pause_screen.tscn').instantiate())

	if ui.finished_countdown:
		Discord.change_presence('Playing '+ SONG.song +' - '+ JsonHandler.get_diff.to_upper(),\
		 Util.to_time(Conductor.song_pos) +' / '+ Util.to_time(Conductor.song_length) +' | '+ \
		  str(round(abs(Conductor.song_pos / Conductor.song_length) * 100.0)) +'% Complete')

	var scale_ratio = 5.0 / Conductor.step_crochet * 100.0
	ui.zoom = lerpf(1.0, ui.zoom, exp(-delta * scale_ratio))

	if chart_notes != null:
		while chart_notes.size() > 0 and chunk != chart_notes.size() and chart_notes[chunk][0] - Conductor.song_pos < spawn_time / cur_speed:
			if chart_notes[chunk][0] - Conductor.song_pos > spawn_time / cur_speed:
				break

			var new_note:Note = Note.new(NoteData.new(chart_notes[chunk]))
			new_note.speed = cur_speed
			notes.append(new_note)

			var to_add:String = 'player' if new_note.must_press else 'opponent'

			if chart_notes[chunk][2]: # if it has a sustain
				var new_sustain:Note = Note.new(new_note, true)
				new_sustain.speed = new_note.speed

				notes.append(new_sustain)
				ui.add_to_strum_group(new_sustain, to_add)

			ui.add_to_strum_group(new_note, to_add)
			chunk += 1

	if !notes.is_empty():
		for note in notes:
			if !note.spawned: continue
			note.follow_song_pos(ui.player_strums[note.dir] if note.must_press else ui.opponent_strums[note.dir])
			if note.strum_time <= Conductor.song_pos:
				var kill_zone = Conductor.song_pos - (300.0 / note.speed)
				if note.is_sustain:
					if note.can_hit and !note.was_good_hit:
						if note.must_press:
							note.holding = ((auto_play and note.should_hit) or Input.is_action_pressed(key_names[note.dir]))
							good_sustain_press(note)
							if !auto_play and note.strum_time < kill_zone and !note.holding \
								and note.should_hit: note_miss(note)
						else:
							opponent_sustain_press(note)
					if note.temp_len <= 0: kill_note(note)
				else:
					if note.must_press:
						if auto_play and note.should_hit:
							good_note_hit(note)
						if note.strum_time < kill_zone and !note.was_good_hit:
							var note_func = note_miss if note.should_hit and !auto_play else kill_note
							note_func.call(note)
					else:
						opponent_note_hit(note)

	if events.size() != 0:
		for event in events:
			if event.strum_time <= Conductor.song_pos:
				event_hit(event)
				events.pop_front()

func countdown_start() -> void: pass

func countdown_tick(tick) -> void:
	ui.icon_p1.bump(1.1)
	ui.icon_p2.bump(1.1)

func song_start() -> void: pass

func beat_hit(beat) -> void:
	ui.icon_p1.bump(1.1)
	ui.icon_p2.bump(1.1)

	if beat % zoom_beat == 0:
		ui.zoom += zoom_add.ui / 2.0
		ui.mark.scale += Vector2(0.1, 0.1)

func step_hit(_step) -> void: pass

func section_hit(section) -> void:
	if !['v_slice', 'codename', 'osu'].has(JsonHandler.parse_type) and SONG.notes.size() > section:
		section_data = SONG.notes[section]
		if !section_data.has('mustHitSection'): section_data.mustHitSection = true
		if section_data.has('changeBPM') and section_data.has('bpm'):
			if section_data.changeBPM and Conductor.bpm != section_data.bpm:
				Conductor.bpm = section_data.bpm
				print('Changed BPM: ' + str(section_data.bpm))

func _unhandled_key_input(event) -> void:
	if auto_play: return
	for i in 4:
		if event.is_action_just_pressed(key_names[i]): key_press(i)
		if event.is_action_just_released(key_names[i]): key_release(i)

func key_press(key:int = 0) -> void:
	var hittable_notes:Array[Note] = notes.filter(func(i:Note):
		return i.dir == key and i.spawned and !i.is_sustain and i.must_press and i.can_hit and !i.was_good_hit
	)
	hittable_notes.sort_custom(func(a, b): return a.strum_time < b.strum_time)

	if hittable_notes.is_empty():
		if Prefs.ghost_tapping != 'on': ghost_tap(key)
	else:
		var note:Note = hittable_notes[0]
		if hittable_notes.size() > 1: # mmm idk anymore
			for funny in hittable_notes: # temp dupe note thing killer bwargh i hate it
				if note == funny: continue
				if absf(funny.strum_time - note.strum_time) < 1.0:
					kill_note(funny)
		good_note_hit(note)

	var strum = ui.player_strums[key]
	if !strum.animation.contains('confirm'):
		strum.play_anim('press')
		strum.reset_timer = 0

func key_release(key:int = 0) -> void:
	ui.player_strums[key].play_anim('static')

func try_death() -> void:
	Game.persist['deaths'] += 1
	died = true

func song_end() -> void:
	if should_save and !died and JsonHandler.song_variant == '':
		var save_data = [score, ui.accuracy, misses, ui.fc, combo]
		var saved_score = HighScore.get_score(SONG.song, JsonHandler.get_diff)

		if save_data[0] > saved_score:
			HighScore.set_score(SONG.song, JsonHandler.get_diff, save_data)

	Conductor.reset()
	if playlist.is_empty() or song_idx >= playlist.size() - 1:
		Game.persist.song_list = []
		var back_to = 'story_mode' if story_mode else 'freeplay'
		Game.switch_scene("menus/"+ back_to)
	else:
		song_idx += 1
		JsonHandler.parse_song(playlist[song_idx], JsonHandler.get_diff, JsonHandler.song_variant)
		SONG = JsonHandler.SONG
		cur_speed = SONG.speed
		Conductor.load_song(SONG.song)
		refresh(true)

func refresh(restart:bool = true) -> void: # start song from beginning with no restarts
	Conductor.reset_beats()
	Conductor.bpm = SONG.bpm # reset bpm to init whoops
	died = false

	if !notes.is_empty(): kill_all_notes()
	events.clear()

	for strum in ui.player_strums:
		strum.play_anim('static')

	chart_notes = JsonHandler.chart_notes.duplicate()
	events = JsonHandler.song_events.duplicate()

	chunk = 0
	if restart:
		for item in ['combo', 'score', 'misses']: set(item, 0)
		ui.reset_stats()
		Discord.change_presence('Starting: '+ SONG.song.capitalize())
		ui.get_node('Left').text = '0:00'
		ui.time_bar.value = 0
		Conductor.song_pos = (-Conductor.crochet * 4)
		ui.start_countdown(true)
		ui.hp = 50
	else:
		Conductor.start(0)
	section_hit(0)

func char_from_string(peep:String) -> String:
	match peep.to_lower().strip_edges():
		'2', 'girlfriend', 'gf', 'spectator': return 'gf'
		'1', 'dad', 'opponent': return 'dad'
		_: return 'boyfriend'

func event_hit(event:EventData) -> void:
	print(event.event, event.values)
	match event.event:
		'Change Scroll Speed':
			var new_speed = SONG.speed * float(event.values[0])
			var tween_dur := float(event.values[1])
			if abs(tween_dur) > 0:
				create_tween().tween_property(Game.scene, 'cur_speed', new_speed, tween_dur)
			else:
				cur_speed = new_speed
		'Add Camera Zoom':
			var ev_zoom = [float(event.values[0]), float(event.values[1])]
			var zoom_ui = 0.03 if is_nan(ev_zoom[0]) else ev_zoom[0] / 2.2

			ui.zoom += zoom_ui
		'Change Character':
			var peep := char_from_string(event.values[0])
			if peep == 'boyfriend':
				if Prefs.daniel: event.values[1] = event.values[1].replace('bf', 'bf-girl')
				#if Prefs.femboy: event.values[1] = 'bf-femboy'

			var gotted = JsonHandler.get_character(Character.get_closest(event.values[1]))
			if gotted != null:
				if peep == 'boyfriend': ui.icon_p1.change_icon(gotted.icon, true)
				if peep == 'dad': ui.icon_p2.change_icon(gotted.icon)
		'SetCameraBop':
			zoom_beat = event.values[0].rate
			zoom_add.game = event.values[0].intensity / 15.0

func good_note_hit(note:Note) -> void:
	if note.type.length() > 0: print(note.type, ' bf')
	if !note.should_hit:
		note_miss(note)
		return

	if Conductor.vocals:
		Conductor.audio_volume(1, 1)

	var time:float = Conductor.song_pos - note.strum_time if !auto_play else 0.0
	note.rating = Judge.get_rating(time)

	var judge_info = Judge.get_score(note.rating)

	ui.get_group('player').note_hit(note)

	combo += 1
	grace = combo > 10
	pop_up_combo([note.rating, combo, time])
	if !died:
		var to_add = int(300 * (((1.0 + exp(-0.08 * (abs(time) - 40))) + 66.3)) / (55.0 / judge_info[2]))
		score += judge_info[0] if Prefs.legacy_score else to_add
		ui.hp += 1.0

	ui.note_percent += judge_info[1]
	ui.total_hit += 1
	ui.hit_count[note.rating] += 1

	ui.update_score_txt()
	kill_note(note)

	if Prefs.hitsound_volume > 0:
		Audio.play_sound('hitsound', Prefs.hitsound_volume / 100.0)

var time_dropped:float = 0
func good_sustain_press(sustain:Note) -> void:
	if !auto_play and Input.is_action_just_released(key_names[sustain.dir]) and !sustain.was_good_hit:
		#sustain.dropped = true
		sustain.strum_time = Conductor.song_pos
		sustain.holding = false
		print('let go too soon ', sustain.length)
		sustain.drop_time += get_process_delta_time() #testing something
		if sustain.drop_time >= 0.3:
			note_miss(sustain)
		return

	if sustain.holding:
		if !sustain.should_hit:
			note_miss(null)
		else:
			if Conductor.vocals:
				Conductor.audio_volume(1, 1)

			ui.get_group('player').note_hit(sustain)

			grace = true
			if !died:
				if !Prefs.legacy_score:
					score += floor((550 * get_process_delta_time()) * Conductor.playback_rate)
				ui.hp += (4 * get_process_delta_time())
			ui.update_score_txt()

func opponent_note_hit(note:Note) -> void:
	if note.type.length() > 0: print(note.type, ' dad')

	if Conductor.vocals:
		Conductor.audio_volume((2 if Conductor.mult_vocals else 1), 1)

	ui.get_group('opponent').note_hit(note)
	kill_note(note)

func opponent_sustain_press(sustain:Note) -> void:
	if Conductor.vocals:
		Conductor.audio_volume((2 if Conductor.mult_vocals else 1), 1)

	ui.get_group('opponent').note_hit(sustain)

var grace:bool = true
func note_miss(note:Note) -> void:
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)

	misses += 1
	ui.hit_count['miss'] = misses
	if note != null:
		if !died:
			var away = floor(note.length * 2) if note.is_sustain else int(30 + (15 * floor(misses / 3.0)))
			score -= 10 if Prefs.legacy_score else away

			var hp_diff:float = ((note.length / 30.0) if note.is_sustain else 5.0)
			if note.is_sustain and grace and ui.hp - hp_diff <= 0: # big ass sustains wont kill you instantly
				grace = false
				hp_diff = ui.hp - 0.1

			ui.hp -= hp_diff

		ui.total_hit += 1

		kill_note(note)

	pop_up_combo(['miss', ('000' if combo >= 10 else '')], true)
	combo = 0

	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt()
	#if !note.sustain:

func ghost_tap(dir:int) -> void:
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)
	if Prefs.ghost_tapping == 'insta-kill':
		ui.hp = 0
		return try_death()

	misses += 1
	ui.hit_count['miss'] = misses
	if !died:
		var away = int(30 + (15 * floor(misses / 3.0)))
		score -= 10 if Prefs.legacy_score else away
		ui.hp -= 2.5

	ui.total_hit += 1

	pop_up_combo(['miss', ''], true)

	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt()

func pop_up_combo(_info:Array = ['sick', -1], is_miss:bool = false) -> void:
	if Prefs.rating_cam != 'none':
		var layer:Callable = ui.add_behind if Prefs.rating_cam == 'hud' else add_child

		if _info[0].length() != 0:
			var new_rating = Judge.make_rating(_info[0])
			layer.call(new_rating)

			if new_rating != null: # opening chart editor at the wrong time would fuck it
				var fade = [new_rating]
				if _info.size() == 3 and !['epic', 'sick'].has(_info[0]):
					var new_timing = Judge.make_timing(new_rating, _info[2])
					layer.call(new_timing)
					fade.append(new_timing)

				for i in fade:
					var new_tween = create_tween()
					new_tween.tween_property(i, "modulate:a", 0, 0.2).set_delay(Conductor.crochet * 0.001)
					new_tween.finished.connect(i.queue_free)

		if (_info[1] is int and _info[1] > -1) or (_info[1] is String and _info[1].length() > 0):
			for num in Judge.make_combo(_info[1]):
				layer.call(num)

				if num != null:
					var n_tween = create_tween()
					if is_miss: num.modulate = Color.DARK_RED
					n_tween.tween_property(num, "modulate:a", 0, 0.2).set_delay(Conductor.crochet * 0.002)
					n_tween.finished.connect(num.queue_free)

func kill_note(note:Note) -> void:
	if notes.find(note) != -1:
		note.spawned = false
		notes.remove_at(notes.find(note))
		note.queue_free()
	else:
		note.queue_free()

func kill_all_notes() -> void:
	while notes.size() != 0:
		kill_note(notes[0])
	notes.clear()
