class_name PlayScene extends Node2D

@onready var cam:Camera2D = $Camera
@onready var ui:CanvasLayer = $UI
@onready var other:CanvasLayer = $OtherUI # like psych cam other, above ui, and unaffected by ui zoom

@onready var Judge:Rating = Rating.new()

var SONG:Dictionary

var key_names:PackedStringArray = ['note_left', 'note_down', 'note_up', 'note_right']
var GAME_OVER

var story_mode:bool = false
var playlist:Array[String] = []
var song_idx:int = 0

var default_zoom:float = 0.8
var cur_skin:String = 'default': # yes
	set(new_skin):
		ui.cur_skin = new_skin
		cur_skin = ui.cur_skin
var cur_speed:float = 1.0:
	set(new_speed):
		cur_speed = new_speed
		for note in notes: note.speed = cur_speed

var cur_stage:String = 'stage'
var stage:StageBase

var zoom_beat:int = 4
var zoom_add:Dictionary = {ui = 0.04, game = 0.045}

var chart_notes:Array = []
var notes:Array[Note] = []
var events:Array[EventData] = []
var start_time:float = 0 # when the first note is actually loaded
var spawn_time:int = 2000

var boyfriend:Character
var dad:Character
var gf:Character
var characters:Array[Character] = []
var speaker

var should_save:bool = !Prefs.auto_play
var can_pause:bool = true
var lerp_zoom:bool = true
var can_end:bool = true
@onready var auto_play:bool:
	set(auto):
		if auto: should_save = false
		auto_play = auto
		ui.get_group('player').is_cpu = auto_play
		ui.mark.visible = auto_play
		ui.health_bar.set_colors(Color.RED, Color.SLATE_GRAY if auto else Color('66ff33'))

var score:float = 0
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

	if !LuaHandler.active_lua.is_empty():
		LuaHandler.remove_all()

	if JsonHandler.SONG.is_empty(): #i love fallbacks !! !
		JsonHandler.parse_song("test", "hard")

	SONG = JsonHandler.SONG

	if Prefs.daniel and !SONG.player1.contains('bf-girl'):
		var try = SONG.player1.replace('bf', 'bf-girl')
		var it_exists = ResourceLoader.exists('res://assets/data/characters/'+ try +'.json')
		SONG.player1 = try if it_exists else 'bf-girl'

	#if JsonHandler.parse_type == 'legacy':
	Conductor.add_bpm_changes(SONG)
	Conductor.load_song(SONG.song)
	Conductor.bpm = SONG.bpm

	Conductor.paused = false
	Conductor.connect_signals()
	cur_speed = SONG.speed
	if Prefs.scroll_speed > 0: cur_speed = Prefs.scroll_speed

	cur_stage = SONG.get('stage', 'stage').to_lower().replace(' ', '-')
	if !ResourceLoader.exists('res://game/scenes/stages/'+ cur_stage +'.tscn'):
		cur_stage = 'stage'

	stage = load('res://game/scenes/stages/%s.tscn' % [cur_stage]).instantiate() # im sick of grey bg FUCK
	add_child(stage)

	default_zoom = stage.default_zoom
	cam.zoom = Vector2(default_zoom, default_zoom)

	var gf_ver = SONG.get('gfVersion', SONG.get('player3', 'gf'))
	if gf_ver == null: gf_ver = 'gf'

	var has_group:bool = stage.has_node('CharGroup')
	var add:Callable = stage.get_node('CharGroup').add_child if has_group else add_child

	gf = Character.new(stage.gf_pos, gf_ver)
	add.call(gf)

	if !gf.speaker_data.keys().is_empty():
		var _data:Dictionary = gf.speaker_data
		match _data.sprite:
			'ABot': speaker = load('res://game/objects/a_bot.tscn').instantiate()
			'ABot-pixel': speaker = load('res://game/objects/a_bot_pixel.tscn').instantiate()
			_: speaker = Speaker.new(_data.sprite)
		speaker.offset = Vector2(_data.offsets[0], _data.offsets[1])
		gf.add_child(speaker)
		speaker.show_behind_parent = true
		speaker.use_parent_material = true

		if _data.has('addons'):
			for i in _data.addons:
				# [sprite_name, [offset_x, offset_y], scale, flip_x, layer]
				var new := Speaker.Addon.new(i[0], i[1])

				new.scale = Vector2(i[2], i[2])
				new.flip_h = i[3]

				gf.add_child(new)
				if i.size() >= 5:
					match i[4].to_lower():
						'back': new.reparent(speaker)
						'front': new.show_behind_parent = false
						#_: gf.add_child(new)
				speaker.addons.append(new)

	if gf.cur_char.to_lower().ends_with('-speaker') and cur_stage.contains('tank'):
		stage.init_tankmen()

	dad = Character.new(stage.dad_pos, SONG.player2)
	add.call(dad)
	if dad.cur_char == gf.cur_char and dad.cur_char.contains('gf'): #and SONG.song == 'Tutorial':
		dad.position = gf.position
		dad.focus_offsets.x -= dad.width / 4
		gf.visible = false
		if speaker:
			speaker.reparent(dad)

	boyfriend = Character.new(stage.bf_pos, SONG.player1, true)
	add.call(boyfriend)
	boyfriend.cache_char(boyfriend.death_char)

	ui.icon_p1.change_icon(boyfriend.icon, true)
	ui.icon_p2.change_icon(dad.icon)

	characters = [boyfriend, dad, gf]

	ui.get_group('player').singer = boyfriend
	ui.get_group('opponent').singer = dad

	if cur_stage.begins_with('school'):
		cur_skin = 'pixel'

	Judge.skin = ui.SKIN
	if Prefs.rating_cam == 'game':
		Judge.rating_pos = boyfriend.get_cam_pos() - Vector2(120, 50)
		Judge.combo_pos = boyfriend.get_cam_pos() - Vector2(260, -60)
	elif Prefs.rating_cam == 'hud':
		Judge.rating_pos = Vector2(580, 300)
		Judge.combo_pos = Vector2(420, 420)

	Discord.change_presence('Starting '+ SONG.song.capitalize())

	if JsonHandler.chart_notes.is_empty():
		JsonHandler.generate_chart(SONG)

	chart_notes = JsonHandler.chart_notes.duplicate(true)
	events = JsonHandler.song_events.duplicate(true)
	for i in events:
		if i.event != 'Change Character': continue
		var peep = char_from_string(str(i.values[0]))
		peep.cache_char(i.values[1])

	print(SONG.song +' '+ JsonHandler.cur_diff.to_upper())
	print('TOTAL EVENTS: '+ str(events.size()))
	for i in [self, stage]:
		ui.countdown_start.connect(Callable(i, 'countdown_start'))
		ui.countdown_tick.connect(Callable(i, 'countdown_tick'))
		ui.song_start.connect(Callable(i, 'song_start'))

	Conductor.connect_signals(stage)

	var to_check:PackedStringArray = ['data/scripts', 'songs/'+ JsonHandler.song_root]
	for i in to_check.size() * 2:
		var folder:String = to_check[i % to_check.size()]
		var prefix:String = 'res://assets/' if i < to_check.size() else Game.exe_path +'mods/'
		for file in Util.only_get(folder, 'lua', prefix):
			LuaHandler.add_script(folder +'/'+ file)

	if GAME_OVER == null:
		var char_suff = '-pico' if boyfriend.cur_char.contains('pico') else ''
		GAME_OVER = load('res://game/scenes/game_over'+ char_suff +'.tscn').instantiate()

	stage.post_ready()
	LuaHandler.call_func('post_ready')

	ui.start_countdown(true)

	if JsonHandler.parse_type == 'v_slice': move_cam('dad')
	section_hit(0) #just for 1st section stuff

var note_count:int = 0
var section_data:Dictionary = {}
var chunk:int = 0

func _notification(what:int) -> void:
	if what == NOTIFICATION_PREDELETE and GAME_OVER:
		GAME_OVER.queue_free()

func _process(delta):
	if LuaHandler.call_func('process', [delta]) == LuaHandler.RETURN_TYPE.STOP: return

	if ui.hp <= 0: try_death()
	if Input.is_action_just_pressed('accept') and can_pause:
		get_tree().paused = true
		other.add_child(load('res://game/scenes/pause_screen.tscn').instantiate())

	if Prefs.allow_rpc and ui.finished_countdown:
		Discord.change_presence('Playing '+ SONG.song +' - '+ JsonHandler.cur_diff.to_upper(),\
		 Util.to_time(Conductor.song_pos) +' / '+ Util.to_time(Conductor.song_length) +' | '+ \
		  str(Util.get_percent(Conductor.song_pos, Conductor.song_length)) +'% Complete')

	var scale_ratio:float = 5.0 / Conductor.step_crochet * 100.0
	ui.zoom = lerpf(1.0, ui.zoom, exp(-delta * scale_ratio))
	if lerp_zoom:
		cam.zoom.x = lerpf(default_zoom, cam.zoom.x, exp(-delta * scale_ratio))
		cam.zoom.y = cam.zoom.x

	var fixed_time:float = (spawn_time / cur_speed)
	while chunk < chart_notes.size() and chart_notes[chunk].strum_time - Conductor.song_pos < fixed_time:
		if chart_notes[chunk].strum_time - Conductor.song_pos > fixed_time: break # no notes to find, fuck off for now
		make_note(chart_notes[chunk])
		chunk += 1

	if !notes.is_empty():
		for note:Note in notes:
			if !note.spawned: continue
			note.follow_song_pos(ui.player_strums[note.dir] if note.must_press else ui.opponent_strums[note.dir])

			if note.strum_time <= Conductor.song_pos:
				var del_note:bool = note.strum_time < (Conductor.song_pos - (300.0 / note.speed))
				if note.must_press:
					if note.is_sustain:
						if note.can_hit and !note.was_good_hit:
							note.holding = (auto_play and note.should_hit) or Input.is_action_pressed(key_names[note.dir])
							if note.holding: good_note_hit(note)

						if !note.holding:
							if del_note and note.should_hit: note_miss(note)
							if note.strum_time + note.length < (Conductor.song_pos - (300.0 / note.speed)):
								kill_note(note)
					else:
						if auto_play and note.should_hit:
							good_note_hit(note)
						if del_note and !note.was_good_hit:
							var note_func = note_miss if note.should_hit and !auto_play else kill_note
							note_func.call(note)
				else:
					opponent_note_hit(note)
					if note.is_sustain and note.visual_len <= 0:
						kill_note(note)

	if !events.is_empty():
		for event in events:
			if event.strum_time <= Conductor.song_pos:
				event_hit(event)
				events.pop_front()

	LuaHandler.call_func('post_process', [delta])

func beat_dance(b:int) -> void:
	ui.icon_p1.bump()
	ui.icon_p2.bump()
	for i in characters:
		if !i.get_anim().begins_with('sing') and b % i.dance_beat == 0:
			i.dance()
	if speaker: speaker.bump()

func countdown_start() -> void:
	LuaHandler.call_func('countdown_start')
	#if !Game.persist.get('seen_cutscene'):
	#	ui.pause_countdown = true
	#	can_pause = false
	#	Cutscene.start_dialogue('test')

func countdown_tick(tick) -> void:
	beat_dance(tick)

func song_start() -> void:
	Game.persist.seen_cutscene = true
	if ui.time_circ.modulate.a == 0:
		Util.quick_tween(ui.time_circ, 'modulate:a', 1, 0.3)

func beat_hit(beat:int) -> void:
	if LuaHandler.call_func('beat_hit', [beat]) == LuaHandler.RETURN_TYPE.STOP: return
	beat_dance(beat)

	if zoom_beat == 0: return
	if beat % zoom_beat == 0:
		ui.zoom += zoom_add.ui
		if !_cam_tween:
			cam.zoom += Vector2(zoom_add.game, zoom_add.game)
		ui.mark.scale += Vector2(0.1, 0.1)

func step_hit(step) -> void:
	if LuaHandler.call_func('step_hit', [step]) == LuaHandler.RETURN_TYPE.STOP: return

func section_hit(section) -> void:
	if LuaHandler.call_func('section_hit', [section]) == LuaHandler.RETURN_TYPE.STOP: return

	if !['v_slice', 'codename', 'osu'].has(JsonHandler.parse_type) and SONG.notes.size() > section:
		section_data = SONG.notes[section]

		var point_at:String = 'boyfriend' if section_data.get_or_add('mustHitSection', true) else 'dad'
		if section_data.get('gfSection', false):
			point_at = 'gf'

		move_cam(point_at)

var focus_offset:Vector2 = Vector2.ZERO
func move_cam(to_char:Variant) -> void:
	var peep:Character
	var cam_off:Vector2
	match typeof(to_char):
		TYPE_STRING, TYPE_INT:
			peep = char_from_string(str(to_char))
			match peep:
				gf: cam_off = stage.gf_cam_offset
				dad: cam_off = stage.dad_cam_offset
				_: cam_off = stage.bf_cam_offset
		_:
			peep = boyfriend if to_char else dad
			cam_off = stage.bf_cam_offset if to_char else stage.dad_cam_offset
	if speaker and peep != gf and speaker.has_method('look'):
		speaker.look(peep == boyfriend)
	var new_pos:Vector2 = peep.get_cam_pos()
	cam.position = new_pos + cam_off #+ focus_offset
	focus_offset = Vector2.ZERO

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
		if Prefs.ghost_tapping != 'on': ghost_tap(key)
		var strum:Strum = ui.player_strums[key]
		strum.play_anim('press')
		strum.reset_timer = 0
		return

	# side note you should throw this in note parsing instead :3 -rudy # im keeping this here, i dont care
	good_note_hit(hittable_notes[0])

func key_release(key:int = 0) -> void:
	ui.player_strums[key].play_anim('static')

func try_death() -> void:
	if LuaHandler.call_func('on_death_start') == LuaHandler.RETURN_TYPE.STOP: return
	Game.persist['deaths'] += 1
	kill_all_notes()
	boyfriend.process_mode = Node.PROCESS_MODE_ALWAYS
	if gf.has_anim('sad'):
		gf.play_anim('sad')
	get_tree().paused = true
	stage.game_over_start()
	if GAME_OVER.get_parent() == null:
		add_child(GAME_OVER)

func _exit_tree() -> void:
	Game.persist.set('seen_cutscene', false)
	Audio.stop_all_sounds()

func song_end() -> void:
	stage.song_end()
	if !can_end:
		Conductor.paused = true
		return

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

	boyfriend.dance(true)
	dad.dance(true)

	chart_notes = JsonHandler.chart_notes.duplicate(true)
	events = JsonHandler.song_events.duplicate(true)

	chunk = 0
	if restart:
		#for item in ['combo', 'score', 'misses']: set(item, 0)
		#ui.reset_stats()
		Discord.change_presence('Starting: '+ SONG.song.capitalize())
		ui.time_circ.get_node('Pos').text = '0:00'
		ui.time_circ.value = 0
		Conductor.song_pos = (-Conductor.crochet * 4)
		ui.start_countdown(true)
		ui.hp = 50
	else:
		Conductor.start(0)
	section_hit(0)

func char_from_string(peep:String) -> Character:
	match peep.to_lower().strip_edges():
		'2', 'girlfriend', 'gf', 'spectator': return gf
		'1', 'dad', 'opponent': return dad
		_: return boyfriend

var _cam_tween
func event_hit(event:EventData) -> void:
	var luad = LuaHandler.call_func('event_hit', [event.event, event.values])
	if luad == LuaHandler.RETURN_TYPE.STOP: return
	stage.event_hit(event)
	print(event.event, event.values)
	match event.event:
		#region PSYCH EVENTS
		'Hey!':
			var time:float = float(event.values[1])
			if is_nan(time): time = 0.6
			match event.values[0].to_lower():
				'bf', 'boyfriend', '0':
					boyfriend.play_anim('hey', true)
					boyfriend.anim_timer = time
				'gf', 'girlfriend', '2':
					gf.play_anim('cheer', true)
					gf.anim_timer = time
				_:
					boyfriend.play_anim('hey', true)
					boyfriend.anim_timer = time
					gf.play_anim('cheer', true)
					gf.anim_timer = time
		'Play Animation':
			if event.values[1] == '1': event.values[1] = '0'
			var peep := char_from_string(event.values[1])
			if peep.has_anim(str(event.values[0])):
				peep.play_anim(event.values[0], true)
				peep.special_anim = true
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
			var ev_zoom:Array[String] = [event.values[0], event.values[1]]

			var zoom_game:float = float(ev_zoom[0]) / 2.0 if ev_zoom[0].is_valid_float() else 0.015
			var zoom_ui:float = float(ev_zoom[1]) / 2.0 if ev_zoom[1].is_valid_float() else 0.03

			ui.zoom += zoom_ui
			cam.zoom += Vector2(zoom_game, zoom_game)
		'Change Character':
			var peep := char_from_string(str(event.values[0]))
			if peep == boyfriend:
				if Prefs.daniel: event.values[1] = event.values[1].replace('bf', 'bf-girl')
				#if Prefs.femboy: event.values[1] = 'bf-femboy'

			var new_char = Character.get_closest(event.values[1])

			var last_anim:String = peep.get_anim()
			var last_frame:int = peep.frame
			var last_pos:Vector2
			match peep:
				dad: last_pos = stage.dad_pos
				gf: last_pos = stage.gf_pos
				_: last_pos = stage.bf_pos

			if JsonHandler.get_character(new_char) and new_char != peep.cur_char:
				peep.position = last_pos
				peep.load_char(event.values[1])
				if peep.speaker_data.is_empty(): pass

				if peep.has_anim(last_anim):
					peep.play_anim(last_anim, true)
					peep.frame = last_frame
				if peep == boyfriend:
					Judge.rating_pos = boyfriend.get_cam_pos() - Vector2(120, 50)
					Judge.combo_pos = boyfriend.get_cam_pos() - Vector2(260, -60)
					ui.icon_p1.change_icon(peep.icon, true)
				if peep == dad: ui.icon_p2.change_icon(peep.icon)

		'Set GF Speed':
			var new_speed:int = int(event.values[0])
			gf.dance_beat = new_speed if event.values[0].is_valid_int() else 1
		#endregion
		'FocusCamera', 'Camera Movement':
			var char_int = event.values[0] # a little fix
			if event.values[0] is Dictionary:
				if event.values[0].is_empty(): return
				char_int = char_int.char
				focus_offset.x = float(event.values[0].get('x', 0))
				focus_offset.y = float(event.values[0].get('y', 0))
			if int(char_int) == -1:
				cam.position = focus_offset
			else:
				move_cam(int(char_int))
		'PlayAnimation':
			var data = event.values[0]
			var peep := char_from_string(data.target)
			if peep.has_anim(data.anim):
				peep.play_anim(data.anim, data.force)
				peep.special_anim = true
				#peep.can_sing = !data.force
		'SetCameraBop':
			zoom_beat = event.values[0].get('rate', 4)
			zoom_add.game = event.values[0].intensity / (1.0 if event.values[0].intensity == 0 else 25.0)
		'ZoomCamera':
			var data:Dictionary = event.values[0]
			var zoom_mode:String = data.get('mode', 'direct')
			var new_zoom:float = data.zoom if zoom_mode == 'direct' else stage.default_zoom * data.zoom
			var dur:float = 4.0
			if data.has('duration'):
				dur = (Conductor.step_crochet * data.duration / 1000.0)

			default_zoom = new_zoom
			if dur <= 0 or data.ease == 'INSTANT':
				cam.zoom = Vector2(new_zoom, new_zoom)
			else:
				var ease_shit:Array = data.ease.to_snake_case().split('_')
				if data.has('easeDir'): ease_shit.append(data.easeDir)
				_cam_tween = create_tween()
				_cam_tween.tween_property(cam, 'zoom', Vector2(new_zoom, new_zoom), dur)
				_cam_tween.set_trans(Util.trans_from_string(ease_shit[0]))
				if ease_shit.size() > 1:
					_cam_tween.set_ease(Util.ease_from_string(ease_shit[1]))
				_cam_tween.finished.connect(func(): _cam_tween = null)

		'SetHealthIcon':
			var ic_id:int = int(event.values[0].char)
			ui.get('icon_p'+ str(ic_id + 1)).change_icon(event.values[0].id, ic_id == 0)

		'ChangeBPM', 'BPM Change': pass
			#var fun:Conductor.BPMChange = Conductor.BPMChange.new()
			#fun.time = event.strum_time
			#fun.bpm = event.values[0]
			#Conductor.bpm_changes.append(fun)
			#print('Changed BPM: '+ str(Conductor.bpm))

func good_note_hit(note:Note) -> void:
	if note.type.length() > 0 and !note.is_sustain: print(note.type, ' bf')
	var luad = LuaHandler.call_func('good_note_hit', [notes.find(note), note.dir, note.type, note.is_sustain])
	if luad == LuaHandler.RETURN_TYPE.STOP: return
	if !note.should_hit:
		return note_miss(note)

	if Conductor.vocals:
		Conductor.audio_volume(1, 1.0)

	var time:float = Conductor.song_pos - note.strum_time if !auto_play else 0.0
	note.rating = Rating.get_rating(time)

	if section_data:
		if section_data.get('gfSection', false) and section_data.mustHitSection:
			note.gf = true

	stage.good_note_hit(note)
	var group:Strum_Line = ui.get_group('player')
	#if note.gf: group = ui.get_group('gf')
	group.singer = gf if note.gf else boyfriend
	group.note_hit(note)

	var to_add:float = 0.0
	if note.is_sustain:
		grace = true
		if !Prefs.legacy_score:
			to_add = (550 * get_process_delta_time()) * Conductor.playback_rate
		ui.hp += (4 * get_process_delta_time())
	else:
		var judge_info:Array = Rating.get_score(note.rating)
		to_add = int(500 - abs(time)) # 500 is the perfect hit score amount
		if Prefs.legacy_score: to_add = judge_info[0]

		combo += 1
		max_combo = max(combo, max_combo)
		grace = combo > 10

		ui.note_percent += judge_info[1]
		ui.total_hit += 1
		ui.hit_count[note.rating] += 1
		ui.hp += 1.0

		pop_up_combo(note.rating, combo, time <= 0)

		kill_note(note)
		if Prefs.hitsound_volume > 0:
			Audio.play_sound('hitsounds/'+ Prefs.hitsound, Prefs.hitsound_volume / 100.0)

	score += to_add
	ui.update_score_txt()

func opponent_note_hit(note:Note) -> void:
	var luad = LuaHandler.call_func('opponent_note_hit', [notes.find(note), note.dir, note.type, note.is_sustain])
	if luad == LuaHandler.RETURN_TYPE.STOP: return
	if note.type.length() > 0 and !note.is_sustain: print(note.type, ' dad')

	if section_data:
		if section_data.get('altAnim', false):
			note.alt = '-alt'

		if section_data.get('gfSection', false) and !section_data.mustHitSection:
			note.gf = true

	if Conductor.vocals:
		Conductor.audio_volume(2 if Conductor.mult_vocals else 1, 1.0)

	stage.opponent_note_hit(note)
	var group = ui.get_group('opponent')
	#if note.gf: group = ui.get_group('gf')
	group.singer = gf if note.gf else dad
	group.note_hit(note)
	if !note.is_sustain:
		kill_note(note)

var grace:bool = true
func note_miss(note:Note) -> void:
	if note.dropped: return
	var le_call = [] if !note else [notes.find(note), note.dir, note.type, note.is_sustain]
	var luad = LuaHandler.call_func('note_miss', le_call)
	if luad == LuaHandler.RETURN_TYPE.STOP: return
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)
	stage.note_miss(note)

	misses += 1
	ui.hit_count['miss'] = misses
	if note:
		if !note.no_anim:
			ui.get_group('player').note_miss(note)
		var away:float = floor(note.length * 2) if note.is_sustain else 30 + (15 * floor(misses / 3.0))
		score -= 10 if Prefs.legacy_score else int(away)
		#print(int(30 + (15 * floor(misses / 3))))
		ui.total_hit += 1

		var hp_diff:float = ((note.visual_len / 30.0) if note.is_sustain else 5.0)
		if note.is_sustain and grace and ui.hp - hp_diff <= 0: # big ass sustains wont kill you instantly
			grace = false
			hp_diff = ui.hp - 0.1

		ui.hp -= hp_diff

		ui.player_strums[note.dir].play_anim('press', true)
		ui.player_strums[note.dir].reset_timer = 0.15
		if note.is_sustain:
			note.dropped = true
			note.strum_time = Conductor.song_pos
		else:
			kill_note(note)

	var be_sad:bool = combo >= 10
	pop_up_combo('miss', ('000' if be_sad else ''))
	if be_sad and gf.has_anim('sad'):
		gf.play_anim('sad')
		gf.anim_timer = 0.5

	combo = 0
	#ui.hp += 10
	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt()

func ghost_tap(dir:int) -> void:
	var luad = LuaHandler.call_func('on_ghost_tap', [dir])
	if luad == LuaHandler.RETURN_TYPE.STOP: return
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)
	stage.ghost_tap(dir)
	if Prefs.ghost_tapping == 'insta-kill':
		return try_death()

	boyfriend.sing(dir, 'miss')
	score -= 10 if Prefs.legacy_score else 1500

	ui.hp -= 2.5

	pop_up_combo('miss', '', true)

	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt()

func pop_up_combo(_rating:String = 'sick', _combo = -1, _early:bool = true) -> void:
	if Prefs.rating_cam == 'none': return
	var layer:Callable = ui.add_behind if Prefs.rating_cam == 'hud' else add_child

	var new_group:Rating.RatingGroup = Judge.make_group(_rating, _combo, _early)
	layer.call(new_group)

	new_group.tween_rating(0.2, Conductor.crochet * 0.001)
	new_group.tween_combo(0.2, Conductor.crochet * 0.002)

func make_note(data:NoteData) -> void:
	var new_note:Note = Note.new(data)
	new_note.speed = cur_speed
	notes.append(new_note)
	stage.note_added(new_note)
	if new_note.must_press and new_note.should_hit: note_count += 1

	var to_add:String = 'player' if new_note.must_press else 'opponent'

	if data.length > Note.min_len: # if it has a sustain thats long enough
		var new_sustain:Note = Note.new(new_note, true)
		new_sustain.speed = new_note.speed

		notes.append(new_sustain)
		stage.note_added(new_sustain)

		ui.add_to_strum_group(new_sustain, to_add)

	ui.add_to_strum_group(new_note, to_add)

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
