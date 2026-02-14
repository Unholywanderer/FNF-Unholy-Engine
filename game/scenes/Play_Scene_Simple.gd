extends Node2D

@onready var cam:Camera2D = $Camera
@onready var ui:CanvasLayer = $UI
@onready var other:CanvasLayer = $OtherUI # like psych cam other, above ui, and unaffected by ui zoom

@onready var Judge:Rating = Rating.new()

const key_names:PackedStringArray = ['note_left', 'note_down', 'note_up', 'note_right']
var SONG:Dictionary

var story_mode:bool = false
var playlist:Array[String] = []
var song_idx:int = 0
var died:bool = false

var default_zoom:float = 0.8
var cur_skin:String = 'default': # yes
	set(new_skin):
		ui.cur_skin = new_skin
		cur_skin = ui.cur_skin
var cur_speed:float = 1.0:
	set(new_speed):
		cur_speed = new_speed
		for note in notes: note.speed = cur_speed

var zoom_beat:int = 4
var zoom_add:Dictionary = {ui = 0.04}

var chart_notes:Array = []
var notes:Array[Note] = []
var events:Array[EventData] = []
var spawn_time:int = 2000

var should_save:bool = !Prefs.auto_play
@onready var auto_play:bool:
	set(auto):
		if auto: should_save = false
		auto_play = auto
		ui.get_group('player').is_cpu = auto_play
		ui.mark.visible = auto_play
		ui.health_bar.set_colors(Color.RED, Color.SLATE_GRAY if auto else Color('66ff33'))

var score:float = 0:
	set(sc):
		if died: return
		score = sc
var combo:int = 0
var misses:int = 0
var max_combo:int = -1

func _ready():
	var spl_path = 'res://assets/images/ui/notesplashes/'+ Prefs.splash_sprite.to_upper() +'.res'
	if Prefs.daniel: spl_path = 'res://assets/images/ui/notesplashes/FOREVER.res'
	Game.persist.note_splash = load(spl_path)
	Game.persist.note_skin = SkinInfo.new()

	auto_play = Prefs.auto_play # there is a reason
	if Game.persist.song_list.size() > 0:
		story_mode = true
		playlist = Game.persist.song_list

	if JsonHandler.SONG.is_empty(): #i love fallbacks !! !
		JsonHandler.parse_song("test", "hard")

	SONG = JsonHandler.SONG

	Conductor.add_bpm_changes(SONG)
	Conductor.load_song(SONG.song)
	Conductor.bpm = SONG.bpm

	Conductor.paused = false
	Conductor.connect_signals()
	cur_speed = SONG.speed
	if Prefs.scroll_speed > 0: cur_speed = Prefs.scroll_speed

	ui.icon_p1.change_icon(JsonHandler.get_character(Character.get_closest(SONG.player1)).icon, true)
	ui.icon_p2.change_icon(JsonHandler.get_character(Character.get_closest(SONG.player2)).icon)

	if SONG.get('stage', 'stage').begins_with('school'):
		cur_skin = 'pixel'

	Judge.skin = ui.SKIN
	if Prefs.rating_cam == 'game':
		Judge.rating_pos = cam.position + Vector2(0, -40)
		Judge.combo_pos = cam.position + Vector2(-50, 50)
	elif Prefs.rating_cam == 'hud':
		Judge.rating_pos = Vector2(580, 300)
		Judge.combo_pos = Vector2(420, 420)

	Discord.change_presence('Starting '+ SONG.song.capitalize())

	if JsonHandler.chart_notes.is_empty():
		JsonHandler.generate_chart(SONG)

	chart_notes = JsonHandler.chart_notes.duplicate(true)
	events = JsonHandler.song_events.duplicate(true)

	print(SONG.song +' '+ JsonHandler.cur_diff.to_upper())
	ui.countdown_start.connect(countdown_start)
	ui.countdown_tick.connect(countdown_tick)
	ui.song_start.connect(song_start)

	ui.start_countdown(true)

	section_hit(0) #just for 1st section stuff

var note_count:int = 0
var section_data:Dictionary = {}
var chunk:int = 0
func _process(delta):
	if ui.hp <= 0 and !died: try_death()
	if Input.is_action_just_pressed('accept'):
		get_tree().paused = true
		other.add_child(load('res://game/scenes/pause_screen.tscn').instantiate())

	if Prefs.allow_rpc and ui.finished_countdown:
		Discord.change_presence('Playing '+ SONG.song +' - '+ JsonHandler.cur_diff.to_upper(),\
		 Util.to_time(Conductor.song_pos) +' / '+ Util.to_time(Conductor.song_length) +' | '+ \
		  str(Util.get_percent(Conductor.song_pos, Conductor.song_length)) +'% Complete')

	var scale_ratio:float = 5.0 / Conductor.step_crochet * 100.0
	ui.zoom = lerpf(1.0, ui.zoom, exp(-delta * scale_ratio))

	var fixed_time:float = (spawn_time / cur_speed)
	while chunk < chart_notes.size() and chart_notes[chunk].strum_time - Conductor.song_pos < fixed_time:
		if chart_notes[chunk].strum_time - Conductor.song_pos > fixed_time: break # no notes to find, fuck off for now

		var new_note:Note = Note.new(chart_notes[chunk])
		new_note.speed = cur_speed
		notes.append(new_note)

		if new_note.must_press and new_note.should_hit: note_count += 1

		var to_add:String = 'player' if new_note.must_press else 'opponent'

		if chart_notes[chunk].length > 0: # if it has a sustain
			var new_sustain:Note = Note.new(new_note, true)
			new_sustain.speed = new_note.speed

			notes.append(new_sustain)
			ui.add_to_strum_group(new_sustain, to_add)

		ui.add_to_strum_group(new_note, to_add)
		chunk += 1

	if !notes.is_empty():
		for note:Note in notes:
			if !note.spawned: continue
			note.follow_song_pos(ui.player_strums[note.dir] if note.must_press else ui.opponent_strums[note.dir])

			if note.strum_time <= Conductor.song_pos:
				if note.must_press:
					var del_note:bool = note.strum_time < (Conductor.song_pos - (300.0 / note.speed))
					if note.is_sustain:
						if note.can_hit and !note.was_good_hit:
							note.holding = (auto_play and note.should_hit) or Input.is_action_pressed(key_names[note.dir])
							good_sustain_press(note)
						if !note.should_hit and !note.holding and del_note: kill_note(note) # probably gonna change this
					else:
						if auto_play and note.should_hit:
							good_note_hit(note)
						if del_note and !note.was_good_hit:
							var note_func = note_miss if note.should_hit and !auto_play else kill_note
							note_func.call(note)
				else:
					if note.is_sustain:
						opponent_sustain_press(note)
						if note.visual_len <= 0: kill_note(note)
					else:
						opponent_note_hit(note)

	if !events.is_empty():
		for event in events:
			if event.strum_time <= Conductor.song_pos:
				event_hit(event)
				events.pop_front()

func beat_dance(_b:int) -> void:
	ui.icon_p1.bump(1.1)
	ui.icon_p2.bump(1.1)

func countdown_start() -> void: pass
func countdown_tick(tick) -> void:
	beat_dance(tick)

func song_start() -> void:
	if ui.time_circ.modulate.a == 0:
		Util.quick_tween(ui.time_circ, 'modulate:a', 1, 0.3)

func beat_hit(beat:int) -> void:
	beat_dance(beat)

	if zoom_beat == 0: return
	if beat % zoom_beat == 0:
		ui.zoom += zoom_add.ui
		#cam.zoom += Vector2(zoom_add.game, zoom_add.game)
		ui.mark.scale += Vector2(0.1, 0.1)

func step_hit(_step) -> void: pass
func section_hit(_section) -> void: pass

func _unhandled_key_input(event:InputEvent) -> void:
	if Input.is_key_pressed(KEY_R): try_death()

	if event.is_action_pressed("back"): auto_play = !auto_play

	if event.is_action_pressed("debug_1"):
		await RenderingServer.frame_post_draw
		Game.switch_scene('debug/Charting_Scene')

	if auto_play: return
	for i in 4:
		if event.is_action_pressed(key_names[i]): key_press(i)
		if event.is_action_released(key_names[i]): key_release(i)

func key_press(key:int = 0) -> void:
	var hittable_notes:Array[Note] = notes.filter(func(i:Note):
		return i.can_hit and i.dir == key and i.spawned and !i.is_sustain and i.must_press and !i.was_good_hit
	)
	hittable_notes.sort_custom(func(a, b): return a.strum_time < b.strum_time)

	if hittable_notes.is_empty():
		if Prefs.ghost_tapping != 'on': ghost_tap()
		var strum = ui.player_strums[key]
		strum.play_anim('press')
		strum.reset_timer = 0
		return

	# side note you should throw this in note parsing instead :3 -rudy # im keeping this here, i dont care
	good_note_hit(hittable_notes[0])

func key_release(key:int = 0) -> void:
	ui.player_strums[key].play_anim('static')

func try_death() -> void:
	Game.persist['deaths'] += 1
	should_save = false
	died = true

func _exit_tree() -> void:
	Game.persist.set('seen_cutscene', false)
	Audio.stop_all_sounds()

func song_end() -> void:
	if Game.persist.get('scoring') == null:
		Game.persist.scoring = ScoreData.new()
	var scoring:ScoreData = Game.persist.get('scoring')
	scoring.is_highscore = false
	scoring.is_valid = should_save

	#TODO: clean this up later and change it, rather sloppy fix
	if should_save:
		var save_data = [roundi(score), ui.accuracy, misses, ui.grade, combo]
		var song_name:String = JsonHandler.song_root + JsonHandler.song_variant
		var saved_score = HighScore.get_score(song_name, JsonHandler.cur_diff)

		if save_data[0] > saved_score:
			if playlist.is_empty() or song_idx + 1 >= playlist.size():
				scoring.is_highscore = true
			HighScore.set_score(song_name, JsonHandler.cur_diff, save_data)

	scoring.add_hits(ui.hit_count)
	scoring.total_notes += note_count
	scoring.song_name = SONG.song
	scoring.score += roundi(score)

	if misses == 0:
		scoring.max_combo += note_count
	else:
		scoring.max_combo = max_combo

	Conductor.reset()

	if song_idx + 1 >= playlist.size():
		Game.persist.song_list = []
		Game.persist.scoring.difficulty = JsonHandler.cur_diff
		Game.switch_scene('results_screen')
	else:
		song_idx += 1
		JsonHandler.parse_song(playlist[song_idx], JsonHandler.cur_diff, JsonHandler.song_variant)
		SONG = JsonHandler.SONG
		cur_speed = SONG.speed
		Game.persist.set('seen_cutscene', false)
		Conductor.load_song(SONG.song)
		ui.time_circ.get_node('Song').text = SONG.song
		refresh(true)

func refresh(restart:bool = true) -> void: # start song from beginning with no restarts
	Conductor.reset_beats()
	Conductor.bpm = SONG.bpm # reset bpm to init whoops
	note_count = 0
	if !notes.is_empty(): kill_all_notes()
	events.clear()

	for strum in ui.player_strums:
		strum.play_anim('static')

	chart_notes = JsonHandler.chart_notes.duplicate(true)
	events = JsonHandler.song_events.duplicate(true)

	chunk = 0
	if restart:
		Discord.change_presence('Starting: '+ SONG.song.capitalize())
		ui.time_circ.get_node('Pos').text = '0:00'
		ui.time_circ.value = 0
		Conductor.song_pos = (-Conductor.crochet * 4)
		ui.start_countdown(true)
		ui.hp = 50
	else:
		Conductor.start(0)
	section_hit(0)

func event_hit(event:EventData) -> void:
	print(event.event, event.values)
	match event.event:
		#region PSYCH EVENTS
		'Change Scroll Speed', "Scroll Speed Change": # [true,2.67,16,"cube","In"],"name":"Scroll Speed Change"
			if Prefs.scroll_speed != 0: return
			var data = {'speed': SONG.speed * float(event.values[0]), 'dur': float(event.values[1]), 't': [0, 0]}
			if event.event == 'Scroll Speed Change':
				data.speed = event.values[1]
				data.dur = 0
				if event.values[0]:
					data.dur = (Conductor.step_crochet / 1000) * float(event.values[2])
				data.t = [event.values[3], event.values[4]]
			if abs(data.dur) > 0:
				Util.quick_tween(Game.scene, 'cur_speed', data.speed, data.dur, data.t[0], data.t[1])
			else:
				cur_speed = data.speed
		'Add Camera Zoom':
			if JsonHandler.parse_type == 'codename': return
			var ev_zoom:Array[String] = [event.values[0], event.values[1]]
			var zoom_ui:float = float(ev_zoom[1]) / 2.0 if ev_zoom[1].is_valid_float() else 0.03
			ui.zoom += zoom_ui

		#endregion
		'SetCameraBop':
			zoom_beat = event.values[0].rate
			#zoom_add.game = event.values[0].intensity / (1.0 if event.values[0].intensity == 0 else 25.0)
		'SetHealthIcon':
			var ic_id:int = int(event.values[0].char)
			ui.get('icon_p'+ str(ic_id + 1)).change_icon(event.values[0].id, ic_id == 0)

		'ChangeBPM', 'BPM Change': pass

func good_note_hit(note:Note) -> void:
	if note.type.length() > 0: print(note.type, ' bf')
	if !note.should_hit:
		return note_miss(note)

	if Conductor.vocals:
		Conductor.audio_volume(1, 1.0)

	var time:float = Conductor.song_pos - note.strum_time if !auto_play else 0.0
	note.rating = Rating.get_rating(time)

	var judge_info = Rating.get_score(note.rating)

	ui.get_group('player').note_hit(note)

	combo += 1
	max_combo = max(combo, max_combo)
	grace = combo > 10

	pop_up_combo(note.rating, combo, time <= 0)
	var to_add:int = int(300 * (((1.0 + exp(-0.08 * (abs(time) - 40))) + 66.3)) / (55.0 / judge_info[2]))
	# 500 is the perfect hit score amount

	score += judge_info[0] if Prefs.legacy_score else to_add
	ui.note_percent += judge_info[1]
	ui.total_hit += 1
	ui.hit_count[note.rating] += 1
	if !died: ui.hp += 1.0

	ui.update_score_txt()
	kill_note(note)

	if Prefs.hitsound_volume > 0:
		Audio.play_sound('hitsounds/'+ Prefs.hitsound, Prefs.hitsound_volume / 100.0)

func good_sustain_press(sustain:Note) -> void: # may or may not fuse the note_hit and sustain_press funcs
	if !auto_play and !Input.is_action_pressed(key_names[sustain.dir]) and !sustain.was_good_hit and sustain.should_hit:
		sustain.strum_time = Conductor.song_pos + sustain.length
		sustain.holding = false
		if sustain.drop_time >= 0.1:
			print(sustain.visual_len, ' MISS')
			note_miss(sustain)
		return

	if sustain.holding:
		if !sustain.should_hit:
			note_miss(sustain)
		else:
			if Conductor.vocals:
				Conductor.audio_volume(1, 1.0)

			ui.get_group('player').note_hit(sustain)

			grace = true
			if !Prefs.legacy_score:
				score += (550 * get_process_delta_time()) * Conductor.playback_rate
			if !died: ui.hp += (4 * get_process_delta_time())
			ui.update_score_txt()
			if sustain.visual_len <= 0: kill_note(sustain)

func opponent_note_hit(note:Note) -> void:
	if note.type.length() > 0: print(note.type, ' dad')

	if Conductor.vocals:
		Conductor.audio_volume(1 + int(Conductor.mult_vocals), 1.0)

	ui.get_group('opponent').note_hit(note)
	kill_note(note)

func opponent_sustain_press(sustain:Note) -> void:
	if Conductor.vocals:
		Conductor.audio_volume(2 if Conductor.mult_vocals else 1, 1.0)

	ui.get_group('opponent').note_hit(sustain)

var grace:bool = true
func note_miss(note:Note) -> void:
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)

	misses += 1
	ui.hit_count['miss'] = misses
	if note:
		if !note.no_anim:
			ui.get_group('player').note_miss(note)
		var away:float = floor(note.length * 2) if note.is_sustain else int(30 + (15 * floor(misses / 3.0)))
		score -= 10.0 if Prefs.legacy_score else away
		ui.total_hit += 1

		var hp_diff:float = ((note.visual_len / 30.0) if note.is_sustain else 5.0)
		if note.is_sustain and grace and ui.hp - hp_diff <= 0: # big ass sustains wont kill you instantly
			grace = false
			hp_diff = ui.hp - 0.1

		ui.hp -= hp_diff

		ui.player_strums[note.dir].play_anim('press', true)
		ui.player_strums[note.dir].reset_timer = 0.15
		kill_note(note)

	pop_up_combo('miss', ('000' if combo >= 10 else ''), true)
	combo = 0

	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt()

func ghost_tap() -> void:
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)
	if Prefs.ghost_tapping == 'insta-kill':
		return try_death()

	score -= 10 if Prefs.legacy_score else 1500
	ui.hp -= 2.5

	pop_up_combo('miss', '', true)

	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt()

func pop_up_combo(_r:String = 'sick', _com = -1, _early:bool = true, is_miss:bool = false) -> void:
	if Prefs.rating_cam == 'none': return
	var layer:Callable = ui.add_behind if Prefs.rating_cam == 'hud' else add_child

	if !_r.is_empty():
		var new_rating := Judge.make_rating(_r)
		layer.call(new_rating)
		if new_rating: # opening chart editor at the wrong time would fuck it
			var fade:Array[VelocitySprite] = [new_rating]
			if Rating.ratings_data[Rating.get_index(_r)].show_timing:
				var new_timing = Judge.make_timing(new_rating, _r, _early)
				layer.call(new_timing)
				fade.append(new_timing)

			for i in fade:
				create_tween().tween_property(i, "modulate:a", 0, 0.2)\
				.set_delay(Conductor.crochet * 0.001).finished.connect(i.queue_free)
	# its like this so you can go '000' and not have it default to a 0
	if (_com is int and _com > -1) or (_com is String and !_com.is_empty()):
		for num in Judge.make_combo(_com):
			layer.call(num)
			if num:
				if is_miss: num.modulate = Color.DARK_RED
				create_tween().tween_property(num, "modulate:a", 0, 0.2)\
				  .set_delay(Conductor.crochet * 0.002).finished.connect(num.queue_free)

func kill_note(note:Note) -> void:
	var _index:int = notes.find(note)
	if _index > -1:
		note.spawned = false
		notes.remove_at(_index)
	note.queue_free()

func kill_all_notes() -> void:
	while notes.size() != 0:
		kill_note(notes[0])
	notes.clear()
