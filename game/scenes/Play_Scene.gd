class_name PlayScene extends Node2D

@onready var cam:Camera2D = $Camera
@onready var ui:CanvasLayer = $UI
@onready var other:CanvasLayer = $OtherUI # like psych cam other, above ui, and unaffected by ui zoom

@onready var Judge:Rating = Rating.new()

var DIE
var death_screen

var story_mode:bool = false
var SONG:Dictionary

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

var song_idx:int = 0
var playlist:Array[String] = []

var boyfriend:Character
var dad:Character
var gf:Character
var characters:Array = []
var speaker

var cached_chars:Dictionary = {'bf' = [], 'gf' = [], 'dad' = []}

var key_names:PackedStringArray = ['note_left', 'note_down', 'note_up', 'note_right']

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

	auto_play = Prefs.auto_play # there is a reason
	if Game.persist.song_list.size() > 0:
		story_mode = true
		playlist = Game.persist.song_list

	if !LuaHandler.active_lua.is_empty():
		LuaHandler.remove_all()

	if JsonHandler._SONG.is_empty(): #i love fallbacks !! !
		JsonHandler.parse_song("test", "hard")

	SONG = JsonHandler._SONG

	#if Prefs.femboy: SONG.player1 = 'bf-femboy'
	if Prefs.daniel and !SONG.player1.contains('bf-girl'):
		var try = SONG.player1.replace('bf', 'bf-girl')
		var it_exists = ResourceLoader.exists('res://assets/data/characters/'+ try +'.json')
		SONG.player1 = try if it_exists else 'bf-girl'

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

	var gf_ver = SONG.get('gfVersion', SONG.get('player3', 'gf'))
	if gf_ver == null: gf_ver = 'gf'

	var has_group:bool = stage.has_node('CharGroup')
	var add:Callable = stage.get_node('CharGroup').add_child if has_group else add_child

	gf = Character.new(stage.gf_pos, gf_ver)
	add.call(gf)

	if !gf.speaker_data.keys().is_empty():
		var _data = gf.speaker_data
		match _data.sprite:
			'ABot': speaker = load('res://game/objects/a_bot.tscn').instantiate()
			'ABot-pixel': speaker = load('res://game/objects/a_bot_pixel.tscn').instantiate()
			_: speaker = Speaker.new()
		speaker.offset = Vector2(_data.offsets[0], _data.offsets[1])
		gf.add_child(speaker)
		speaker.show_behind_parent = true
		speaker.use_parent_material = true

		if _data.has('addons'):
			for i in _data.addons: # [sprite_name, [offset_x, offset_y], scale, flip_x, add_behind_speaker]
				var new := AnimatedSprite2D.new()
				new.sprite_frames = load('res://assets/images/characters/speakers/addons/'+ i[0] +'.res')
				new.centered = false
				new.name = i[0]

				new.offset = Vector2(i[1][0], i[1][1])
				new.scale = Vector2(i[2], i[2])
				new.flip_h = i[3]
				new.use_parent_material = true

				gf.add_child(new)
				new.show_behind_parent = true
				if i.size() >= 5 and i[4]: # add behind speaker
					new.reparent(speaker)
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
		#Game.persist.note_splash = load('res://assets/images/ui/notesplashes/BASE-pixel.res')
		#Prefs.splash_sprite = 'base-pixel'

	Judge.skin = ui.SKIN
	if Prefs.rating_cam == 'game':
		Judge.rating_pos = boyfriend.position + Vector2(0, -40)
		Judge.combo_pos = boyfriend.position + Vector2(-150, 70)
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
		if JsonHandler.parse_type == 'codename':
			i.values[0] = abs(i.values[0] - 1)
		var peep = char_from_string(str(i.values[0]))
		peep.cache_char(i.values[1])

	print(SONG.song +' '+ JsonHandler.get_diff.to_upper())
	print('TOTAL EVENTS: '+ str(events.size()))

	for i in [self, stage]:
		ui.countdown_start.connect(Callable(i, 'countdown_start'))
		ui.countdown_tick.connect(Callable(i, 'countdown_tick'))
		ui.song_start.connect(Callable(i, 'song_start'))

	Conductor.connect_signals(stage)

	for i in DirAccess.get_files_at('res://assets/data/scripts'): #ResourceLoader.list_directory('res://assets/data/scripts'):
		if i.ends_with('.lua'): LuaHandler.add_script('data/scripts/'+ i)

	for i in DirAccess.get_files_at('res://assets/songs/'+ JsonHandler.song_root): #ResourceLoader.list_directory('res://assets/songs/'+ JsonHandler.song_root):
		if i.ends_with('.lua'): LuaHandler.add_script('songs/'+ JsonHandler.song_root +'/'+ i)

	if DIE == null:
		var char_suff = '-pico' if boyfriend.cur_char.contains('pico') else ''
		DIE = load('res://game/scenes/game_over'+ char_suff +'.tscn')

	stage.post_ready()
	LuaHandler.call_func('post_ready')

	ui.start_countdown(true)

	if JsonHandler.parse_type == 'v_slice': move_cam('dad')
	section_hit(0) #just for 1st section stuff

var note_count:int = 0
var section_data:Dictionary = {}
var chunk:int = 0

func _process(delta):
	if LuaHandler.call_func('process', [delta]) == LuaHandler.RET_TYPES.STOP: return

	if Input.is_key_pressed(KEY_R): ui.hp = 0
	if ui.hp <= 0: try_death()

	if Input.is_action_just_pressed("debug_1"):
		await RenderingServer.frame_post_draw
		Game.switch_scene('debug/Charting_Scene')

	if Input.is_action_just_pressed("back"):
		auto_play = !auto_play

	if Input.is_action_just_pressed("accept") and can_pause:
		get_tree().paused = true
		other.add_child(load('res://game/scenes/pause_screen.tscn').instantiate())

	if ui.finished_countdown:
		Discord.change_presence('Playing '+ SONG.song +' - '+ JsonHandler.get_diff.to_upper(),\
		 Util.to_time(Conductor.song_pos) +' / '+ Util.to_time(Conductor.song_length) +' | '+ \
		  str(round(abs(Conductor.song_pos / Conductor.song_length) * 100.0)) +'% Complete')

	var scale_ratio:float = 5.0 / Conductor.step_crochet * 100.0
	ui.zoom = lerpf(1.0, ui.zoom, exp(-delta * scale_ratio))
	if lerp_zoom:
		cam.zoom.x = lerpf(default_zoom, cam.zoom.x, exp(-delta * scale_ratio))
		cam.zoom.y = cam.zoom.x

	var fixed_time:float = (spawn_time / cur_speed)
	while chart_notes.size() > 0 and chunk != chart_notes.size() and chart_notes[chunk][0] - Conductor.song_pos < fixed_time:
		if chart_notes[chunk][0] - Conductor.song_pos > fixed_time: break # no notes to find, fuck off for now

		var new_note:Note = Note.new(NoteData.new(chart_notes[chunk]))
		new_note.speed = cur_speed
		notes.append(new_note)
		if new_note.must_press and new_note.should_hit: note_count += 1

		var to_add:String = 'player' if new_note.must_press else 'opponent'
		#if new_note.gf: to_add = 'gf'

		if chart_notes[chunk][2]: # if it has a sustain
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

	if !events.is_empty():
		for event in events:
			if event.strum_time <= Conductor.song_pos:
				event_hit(event)
				events.pop_front()

	LuaHandler.call_func('post_process', [delta])

func beat_dance(b:int) -> void:
	for i in characters:
		if !i.animation.begins_with('sing') and b % i.dance_beat == 0:
			i.dance()
	if speaker: speaker.bump()
	ui.icon_p1.bump()
	ui.icon_p2.bump()

func countdown_start() -> void: pass

func countdown_tick(tick) -> void:
	beat_dance(tick)

func song_start() -> void:
	Game.persist.seen_cutscene = true

func beat_hit(beat:int) -> void:
	if LuaHandler.call_func('beat_hit', [beat]) == LuaHandler.RET_TYPES.STOP: return
	beat_dance(beat)

	if zoom_beat == 0: return
	if beat % zoom_beat == 0:
		ui.zoom += zoom_add.ui
		if !_cam_tween:
			cam.zoom += Vector2(zoom_add.game, zoom_add.game)
		ui.mark.scale += Vector2(0.1, 0.1)

func step_hit(step) -> void:
	if LuaHandler.call_func('step_hit', [step]) == LuaHandler.RET_TYPES.STOP: return

func section_hit(section) -> void:
	if LuaHandler.call_func('section_hit', [section]) == LuaHandler.RET_TYPES.STOP: return

	if !['v_slice', 'codename', 'osu'].has(JsonHandler.parse_type) and SONG.notes.size() > section:
		section_data = SONG.notes[section]

		if !section_data.has('mustHitSection'): section_data.mustHitSection = true

		var point_at:String = 'boyfriend' if section_data.mustHitSection else 'dad'
		if section_data.get('gfSection', false):
			point_at = 'gf'

		move_cam(point_at)
		if section_data.get('changeBPM') and Conductor.bpm != section_data.get('bpm', Conductor.bpm):
			Conductor.bpm = section_data.bpm
			print('Changed BPM: ' + str(section_data.bpm))

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
	cam.position = new_pos + cam_off + focus_offset
	focus_offset = Vector2.ZERO

func _unhandled_key_input(event:InputEvent) -> void:
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
		var strum = ui.player_strums[key]
		strum.play_anim('press')
		strum.reset_timer = 0
		return

	var note:Note = hittable_notes[0]

	# side note you should throw this in note parsing instead :3 -rudy
	if hittable_notes.size() > 1: # mmm idk anymore
		for funny in hittable_notes: # temp dupe note thing killer bwargh i hate it
			if note == funny: continue
			if absf(funny.strum_time - note.strum_time) < 0.1:
				kill_note(funny)
	good_note_hit(note)

func key_release(key:int = 0) -> void:
	ui.player_strums[key].play_anim('static')

func try_death() -> void:
	if LuaHandler.call_func('on_death_start') == LuaHandler.RET_TYPES.STOP: return
	Game.persist['deaths'] += 1
	kill_all_notes()
	boyfriend.process_mode = Node.PROCESS_MODE_ALWAYS
	boyfriend.top_level = true
	gf.play_anim('sad')
	get_tree().paused = true
	var death = DIE.instantiate()
	stage.game_over_start()
	add_child(death)

func _exit_tree() -> void:
	Game.persist.set('seen_cutscene', false)
	Audio.stop_all_sounds()

func song_end() -> void:
	stage.song_end()
	if !can_end: return

	if Game.persist.get('scoring') == null:
		Game.persist.scoring = ScoreData.new()
	Game.persist.scoring.is_highscore = false
	Game.persist.scoring.is_valid = should_save


	#TODO: clean this up later and change it, rather sloppy fix
	if should_save:
		var save_data = [roundi(score), ui.accuracy, misses, ui.grade, combo]
		var song_name:String = JsonHandler.song_root + JsonHandler.song_variant
		var saved_score = HighScore.get_score(song_name, JsonHandler.get_diff)

		if save_data[0] > saved_score:
			if playlist.is_empty() or song_idx + 1 >= playlist.size():
				Game.persist.scoring.is_highscore = true
			HighScore.set_score(song_name, JsonHandler.get_diff, save_data)

	Conductor.reset()

	Game.persist.scoring.add_hits(ui.hit_count)
	Game.persist.scoring.total_notes += note_count
	Game.persist.scoring.song_name = SONG.song
	Game.persist.scoring.score += roundi(score)
	#Game.persist.scoring.save_format = [roundi(score), ui.accuracy, misses, ui.grade, combo]

	if misses == 0:
		Game.persist.scoring.max_combo += note_count
	else:
		Game.persist.scoring.max_combo = max_combo

	if song_idx + 1 >= playlist.size():
		Game.persist.song_list = []
		Game.persist.scoring.difficulty = JsonHandler.get_diff
		Game.switch_scene('results_screen' if !story_mode else 'story_mode')
		#var back_to = 'story_mode' if story_mode else 'freeplay'
		#Game.switch_scene("menus/"+ back_to)
	else:
		song_idx += 1
		JsonHandler.parse_song(playlist[song_idx], JsonHandler.get_diff, JsonHandler.song_variant)
		SONG = JsonHandler._SONG
		cur_speed = SONG.speed
		Conductor.load_song(SONG.song)
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

func char_from_string(peep:String) -> Character:
	match peep.to_lower().strip_edges():
		'2', 'girlfriend', 'gf', 'spectator': return gf
		'1', 'dad', 'opponent': return dad
		_: return boyfriend

var _cam_tween
func event_hit(event:EventData) -> void:
	var luad = LuaHandler.call_func('event_hit', [event.event, event.values])
	if luad == LuaHandler.RET_TYPES.STOP: return
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

			var zoom_ui:float = float(ev_zoom[0]) / 2.0 if ev_zoom[0].is_valid_float() else 0.03
			var zoom_game:float = float(ev_zoom[1]) / 2.0 if ev_zoom[1].is_valid_float() else 0.015

			ui.zoom += zoom_ui
			cam.zoom += Vector2(zoom_game, zoom_game)
		'Change Character':
			var peep := char_from_string(str(event.values[0]))
			if peep == boyfriend:
				if Prefs.daniel: event.values[1] = event.values[1].replace('bf', 'bf-girl')
				#if Prefs.femboy: event.values[1] = 'bf-femboy'

			var new_char = Character.get_closest(event.values[1])

			var last_anim:String = peep.animation
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
				if peep == boyfriend: ui.icon_p1.change_icon(peep.icon, true)
				if peep == dad: ui.icon_p2.change_icon(peep.icon)

		'Set GF Speed':
			var new_speed = int(event.values[0])
			gf.dance_beat = new_speed if new_speed != null else 1
		#endregion
		'FocusCamera', 'Camera Movement':
			var char_int = event.values[0] # a little fix
			if event.values[0] is Dictionary:
				char_int = char_int.char
				#if event.values[0].has('x'): focus_offset.x = -event.values[0].x
				if event.values[0].has('y'): focus_offset.y = float(event.values[0].y)
			if event.event == 'Camera Movement': char_int = abs(char_int - 1)
			move_cam(int(char_int))
		'PlayAnimation':
			var data = event.values[0]
			var peep := char_from_string(data.target)
			if peep.has_anim(data.anim):
				peep.play_anim(data.anim, data.force)
				peep.special_anim = true
				#peep.can_sing = !data.force
		'SetCameraBop':
			zoom_beat = event.values[0].rate
			zoom_add.game = event.values[0].intensity / 25.0
		'ZoomCamera':
			var data = event.values[0]
			var zoom_mode = 'direct'
			if data.has('mode'): zoom_mode = data.mode
			var new_zoom:float = data.zoom if zoom_mode == 'direct' else stage.default_zoom * data.zoom
			var dur:float = 0.0
			if data.has('duration'):
				dur = Conductor.step_crochet * data.duration / 1000.0

			default_zoom = new_zoom
			if dur > 0:
				_cam_tween = create_tween()
				_cam_tween.tween_property($Camera, 'zoom', Vector2(new_zoom, new_zoom), dur)
				_cam_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
				_cam_tween.finished.connect(func(): _cam_tween = null)
			else:
				$Camera.zoom = Vector2(new_zoom, new_zoom)
		'SetHealthIcon':
			if int(event.values[0].char) == 1: ui.icon_p2.change_icon(event.values[0].id)
			if int(event.values[0].char) == 0: ui.icon_p1.change_icon(event.values[0].id)

		'ChangeBPM', 'BPM Change':
			Conductor.bpm = event.values[0]
			print('Changed BPM: '+ str(Conductor.bpm))

func good_note_hit(note:Note) -> void:
	if note.type.length() > 0: print(note.type, ' bf')
	var luad = LuaHandler.call_func('good_note_hit', [notes.find(note), note.dir, note.type]) # making it take the note itself would crash
	if luad == LuaHandler.RET_TYPES.STOP: return
	if !note.should_hit:
		return note_miss(note)

	if Conductor.vocals:
		Conductor.audio_volume(1, 1.0)

	#boyfriend.material.set_shader_parameter('color_to_be', Color(randf(), randf(), randf()))

	var time:float = Conductor.song_pos - note.strum_time if !auto_play else 0.0
	note.rating = Rating.get_rating(time)

	if section_data:
		if section_data.get('gfSection', false) and section_data.mustHitSection:
			note.gf = true

	var judge_info = Rating.get_score(note.rating)

	stage.good_note_hit(note)
	var group = ui.get_group('player')
	#if note.gf: group = ui.get_group('gf')
	group.singer = gf if note.gf else boyfriend
	group.note_hit(note)

	combo += 1
	max_combo = max(combo, max_combo)
	grace = combo > 10
	pop_up_combo([note.rating, combo, time])
	var to_add = int(300 * (((1.0 + exp(-0.08 * (abs(time) - 40))) + 66.3)) / (55.0 / judge_info[2])) # good enough im happy
	# 500 is the perfect hit score amount

	score += judge_info[0] if Prefs.legacy_score else to_add
	#print(int(300 * (((1.0 + exp(-0.08 * (abs(time) - 40))) + 66.3)) / (55 / judge_info[2])))
	ui.note_percent += judge_info[1]
	ui.total_hit += 1
	ui.hit_count[note.rating] += 1
	ui.hp += 1.0

	ui.update_score_txt()
	kill_note(note)

	if Prefs.hitsound_volume > 0:
		Audio.play_sound('hitsounds/'+ Prefs.hitsound, Prefs.hitsound_volume / 100.0)

var time_dropped:float = 0
func good_sustain_press(sustain:Note) -> void: # may or may not fuse the note_hit and sustain_press funcs
	var luad = LuaHandler.call_func('good_note_hit', [notes.find(sustain), sustain.dir, sustain.type, true])
	if luad == LuaHandler.RET_TYPES.STOP: return
	if !auto_play and Input.is_action_just_released(key_names[sustain.dir]) and !sustain.was_good_hit:
		#sustain.dropped = true
		sustain.strum_time = Conductor.song_pos
		sustain.holding = false
		print('let go too soon ', sustain.length)
		sustain.drop_time += get_process_delta_time() #testing something
		if sustain.drop_time >= 0.15:
			note_miss(sustain)
		return

	if sustain.holding:
		if !sustain.should_hit:
			note_miss(null)
		else:
			if Conductor.vocals:
				Conductor.audio_volume(1, 1.0)

			stage.good_note_hit(sustain)
			if section_data:
				if section_data.get('gfSection', false) and section_data.mustHitSection:
					sustain.gf = true

			var group = ui.get_group('player')
			#if sustain.gf: group = ui.get_group('gf')
			group.singer = gf if sustain.gf else boyfriend
			group.note_hit(sustain)

			grace = true
			if !Prefs.legacy_score:
				score += (550 * get_process_delta_time()) * Conductor.playback_rate
			ui.hp += (4 * get_process_delta_time())
			ui.update_score_txt()

func opponent_note_hit(note:Note) -> void:
	var luad = LuaHandler.call_func('opponent_note_hit', [notes.find(note), note.dir, note.type, false])
	if luad == LuaHandler.RET_TYPES.STOP: return
	if note.type.length() > 0: print(note.type, ' dad')

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
	kill_note(note)

func opponent_sustain_press(sustain:Note) -> void:
	var luad = LuaHandler.call_func('opponent_note_hit', [notes.find(sustain), sustain.dir, sustain.type, true])
	if luad == LuaHandler.RET_TYPES.STOP: return
	if Conductor.vocals:
		Conductor.audio_volume(2 if Conductor.mult_vocals else 1, 1.0)

	stage.opponent_note_hit(sustain)

	if section_data != null:
		if section_data.get('altAnim', false):
			sustain.alt = '-alt'
		if section_data.get('gfSection', false) and !section_data.mustHitSection:
			sustain.gf = true

	var group = ui.get_group('opponent')
	#if sustain.gf: group = ui.get_group('gf')
	group.singer = gf if sustain.gf else dad
	group.note_hit(sustain)

var grace:bool = true
func note_miss(note:Note) -> void:
	var le_call = [] if note == null else [notes.find(note), note.dir, note.type]
	var luad = LuaHandler.call_func('note_miss', le_call)
	if luad == LuaHandler.RET_TYPES.STOP: return
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)
	stage.note_miss(note)

	misses += 1
	ui.hit_count['miss'] = misses
	if note != null:
		if !note.no_anim:
			ui.get_group('player').note_miss(note)
		var away = floor(note.length * 2) if note.is_sustain else int(30 + (15 * floor(misses / 3.0)))
		score -= 10 if Prefs.legacy_score else away
		#print(int(30 + (15 * floor(misses / 3))))
		ui.total_hit += 1

		var hp_diff:float = ((note.length / 30.0) if note.is_sustain else 5.0)
		if note.is_sustain and grace and ui.hp - hp_diff <= 0: # big ass sustains wont kill you instantly
			grace = false
			hp_diff = ui.hp - 0.1

		ui.hp -= hp_diff
		#if !note.is_sustain:
		kill_note(note)

	var be_sad:bool = combo >= 10
	pop_up_combo(['miss', ('000' if be_sad else '')], true)
	if be_sad and gf.has_anim('sad'):
		gf.play_anim('sad')
		gf.anim_timer = 0.5

	combo = 0

	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt()

func ghost_tap(dir:int) -> void:
	var luad = LuaHandler.call_func('on_ghost_tap', [dir])
	if luad == LuaHandler.RET_TYPES.STOP: return
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)
	stage.ghost_tap(dir)
	if Prefs.ghost_tapping == 'insta-kill':
		ui.hp = 0
		return try_death()

	#misses += 1
	#ui.hit_count['miss'] = misses
	boyfriend.sing(dir, 'miss')
	var away = int(30 + (15 * 100
	))
	score -= 10 if Prefs.legacy_score else away

	#ui.total_hit += 1

	ui.hp -= 2.5

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
