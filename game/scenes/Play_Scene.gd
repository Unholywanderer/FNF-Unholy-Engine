extends Node2D

@onready var cam:Camera2D = $Camera
@onready var ui:CanvasLayer = $UI
@onready var other:CanvasLayer = $OtherUI # like psych cam other, above ui, and unaffected by ui zoom

@onready var Judge:Rating = Rating.new()

var DIE

var story_mode:bool = false
var SONG
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

var chart_notes
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

var key_names = ['note_left', 'note_down', 'note_up', 'note_right']

var should_save:bool = !Prefs.auto_play
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
	if LuaHandler.call_func('onReady') == LuaHandler.RET_TYPES.STOP: return # can't reach this wit lua lol
	var spl_path = 'res://assets/images/ui/notesplashes/'+ Prefs.splash_sprite.to_upper() +'.res'
	Game.persist.note_splash = load(spl_path)
	
	auto_play = Prefs.auto_play # there is a reason
	if Game.persist.song_list.size() > 0:
		story_mode = true
		playlist = Game.persist.song_list
	
	if !LuaHandler.active_lua.is_empty():
		LuaHandler.remove_all()
	
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
	
	if SONG.has('stage'):
		cur_stage = SONG.stage.to_lower().replace(' ', '-')
	else:
		var song = SONG.song.to_lower().replace(' ', '-')
		match song: # daily reminder to kiss daniel
			'spookeez', 'south', 'monster': cur_stage = 'spooky'
			'pico', 'philly-nice', 'blammed': cur_stage = 'philly'
			'satin-panties', 'high', 'milf': cur_stage = 'limo'
			'cocoa', 'eggnog': cur_stage = 'mall'
			'winter-horrorland': cur_stage = 'mall-evil'
			'senpai', 'roses': cur_stage = 'school'
			'thorns': cur_stage = 'school-evil'
			'ugh', 'guns', 'stress': cur_stage = 'tank'

	var to_load = 'stage'
	if ResourceLoader.exists('res://game/scenes/stages/'+ cur_stage +'.tscn'):
		to_load = cur_stage
		
	stage = load('res://game/scenes/stages/%s.tscn' % [to_load]).instantiate() # im sick of grey bg FUCK
	add_child(stage)
	default_zoom = stage.default_zoom
	
	if SONG.has('players'): 
		SONG.player1 = SONG.players[0]
		SONG.player2 = SONG.players[1]
		SONG.gfVersion = SONG.players[2]
		
	var gf_ver
	if SONG.has('gfVersion'):
		gf_ver = SONG.gfVersion
	elif SONG.has('player3'):
		gf_ver = SONG.player3
	else: # base game type shit baybeee
		match Game.format_str(SONG.song):
			'satin-panties', 'high', 'milf': gf_ver = 'gf-car'
			'cocoa', 'eggnog', 'winter-horrorland': gf_ver = 'gf-christmas'
			'senpai', 'roses', 'thorns': gf_ver = 'gf-pixel'
			'ugh', 'guns': gf_ver = 'gf-tankmen'
			'stress': gf_ver = 'pico-speaker'
			
	if gf_ver == null or gf_ver.is_empty(): gf_ver = 'gf'

	var has_group = stage.has_node('CharGroup')
	var add:Callable = stage.get_node('CharGroup').add_child if has_group else add_child
	
	gf = Character.new(stage.gf_pos, gf_ver)
	add.call(gf)
	
	if gf.speaker_data.keys().size() > 0:
		var _data = gf.speaker_data
		match _data.sprite:
			'ABot': 
				speaker = load('res://game/objects/a_bot.tscn').instantiate()
			_: speaker = Speaker.new()
		speaker.offset = Vector2(_data.offsets[0], _data.offsets[1])
		gf.add_child(speaker)
		speaker.show_behind_parent = true
		
		if _data.has('addons'):
			for i in _data.addons: # [sprite_name, [offset_x, offset_y], scale, flip_x, add_behind_speaker]
				var new := AnimatedSprite2D.new()
				new.sprite_frames = load('res://assets/images/characters/speakers/addons/'+ i[0] +'.res')
				new.centered = false
				new.name = i[0]
				
				new.offset = Vector2(i[1][0], i[1][1])
				new.scale = Vector2(i[2], i[2])
				new.flip_h = i[3]
				
				gf.add_child(new)
				new.show_behind_parent = true
				if i.size() >= 5 and i[4]: # add behind speaker
					new.reparent(speaker)
				speaker.addons.append(new)
	
	if gf.cur_char.to_lower() == 'pico-speaker' and cur_stage.contains('tank'):
		stage.init_tankmen()
	
	dad = Character.new(stage.dad_pos, SONG.player2)
	add.call(dad)
	if dad.cur_char == gf.cur_char and dad.cur_char.contains('gf'): #and SONG.song == 'Tutorial':
		dad.position = gf.position
		dad.focus_offsets.x -= dad.width / 4
		gf.visible = false
		speaker.reparent(dad)
	
	boyfriend = Character.new(stage.bf_pos, SONG.player1, true)
	add.call(boyfriend)
	
	ui.icon_p1.change_icon(boyfriend.icon, true)
	ui.icon_p2.change_icon(dad.icon)
	
	characters = [boyfriend, dad, gf]
	
	ui.get_group('player').singer = boyfriend
	ui.get_group('opponent').singer = dad
	
	if cur_stage.begins_with('school'):
		cur_skin = 'pixel'
	if cur_stage == 'limo': # lil dumb...
		gf.reparent(stage.get_node('FGLimo'))
		gf.show_behind_parent = true
	
	if Prefs.rating_cam == 'game':
		Judge.rating_pos = boyfriend.position + Vector2(0, -40)
		Judge.combo_pos = boyfriend.position + Vector2(-150, 70)
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

	for i in [self, stage]:
		ui.countdown_start.connect(Callable(i, 'countdown_start'))
		ui.countdown_tick.connect(Callable(i, 'countdown_tick'))
		ui.song_start.connect(Callable(i, 'song_start'))
	
	Conductor.connect_signals(stage)
	
	for i in DirAccess.get_files_at('res://assets/data/scripts'):
		if i.ends_with('.lua'): LuaHandler.add_script('data/scripts/'+ i)
		
	for i in DirAccess.get_files_at('res://assets/songs/'+ JsonHandler.song_root):
		if i.ends_with('.lua'): LuaHandler.add_script('songs/'+ JsonHandler.song_root +'/'+ i)
		
	if DIE == null:
		var char_suff = '-pico' if boyfriend.cur_char == 'pico' else ''
		DIE = load('res://game/scenes/game_over'+ char_suff +'.tscn')
		
	ui.start_countdown(true)
		
	if JsonHandler.parse_type == 'v_slice': move_cam('dad')
	section_hit(0) #just for 1st section stuff
	
var section_data
var chunk:int = 0
func _process(delta):
	if LuaHandler.call_func('update') == LuaHandler.RET_TYPES.STOP: return

	if Input.is_key_pressed(KEY_R): ui.hp = 0
	if ui.hp <= 0: try_death()
		
	if Input.is_action_just_pressed("debug_1"):
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
		 Game.to_time(Conductor.song_pos) +' / '+ Game.to_time(Conductor.song_length) +' | '+ \
		  str(round(abs(Conductor.song_pos / Conductor.song_length) * 100.0)) +'% Complete')
	
	var scale_ratio = 5.0 / Conductor.step_crochet * 100.0
	ui.zoom = lerpf(1.0, ui.zoom, exp(-delta * scale_ratio))
	cam.zoom.x = lerpf(default_zoom, cam.zoom.x, exp(-delta * scale_ratio))
	cam.zoom.y = cam.zoom.x
	
	if chart_notes != null:
		while chart_notes.size() > 0 and chunk != chart_notes.size() and chart_notes[chunk][0] - Conductor.song_pos < spawn_time / cur_speed:
			if chart_notes[chunk][0] - Conductor.song_pos > spawn_time / cur_speed:
				break
			
			var new_note:Note = Note.new(NoteData.new(chart_notes[chunk]))
			new_note.speed = cur_speed
			notes.append(new_note)
			
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
	for i in characters:
		if tick % i.dance_beat == 0 and !i.animation.begins_with('sing'):
			i.dance()
	if speaker != null: speaker.bump()
	ui.icon_p1.bump()
	ui.icon_p2.bump()
	
func song_start() -> void:
	Game.persist.seen_cutscene = true

func beat_hit(beat) -> void:
	if LuaHandler.call_func('beatHit', [beat]) == LuaHandler.RET_TYPES.STOP: return

	for i in characters:
		if !i.animation.begins_with('sing') and beat % i.dance_beat == 0:
			i.dance()
			
	if speaker != null: speaker.bump()
	ui.icon_p1.bump()
	ui.icon_p2.bump()
	
	if beat % zoom_beat == 0:
		ui.zoom += zoom_add.ui
		if !_cam_tween:
			cam.zoom += Vector2(zoom_add.game, zoom_add.game)
		ui.mark.scale = ui.def_mark_scale + (ui.def_mark_scale / 5)

func step_hit(step) -> void:
	if LuaHandler.call_func('stepHit', [step]) == LuaHandler.RET_TYPES.STOP: return

func section_hit(section) -> void:
	if LuaHandler.call_func('sectionHit', [section]) == LuaHandler.RET_TYPES.STOP: return

	if !['v_slice', 'codename', 'osu'].has(JsonHandler.parse_type) and SONG.notes.size() > section:
		section_data = SONG.notes[section]
		if !section_data.has('mustHitSection'): section_data.mustHitSection = true
		
		var point_at:String = 'boyfriend' if section_data.mustHitSection else 'dad'
		if section_data.has('gfSection') and section_data.gfSection:
			point_at = 'gf'
			
		move_cam(point_at)
		if section_data.has('changeBPM') and section_data.has('bpm'):
			if section_data.changeBPM and Conductor.bpm != section_data.bpm:
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
		
	var new_pos:Vector2 = peep.get_cam_pos()
	cam.position = new_pos + cam_off + focus_offset
	focus_offset = Vector2.ZERO

func _unhandled_key_input(_event) -> void:
	if auto_play: return
	for i in 4:
		if Input.is_action_just_pressed(key_names[i]): key_press(i)
		if Input.is_action_just_released(key_names[i]): key_release(i)

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

var imdyin:bool = false
func try_death() -> void:
	if LuaHandler.call_func('onDeathBegin') == LuaHandler.RET_TYPES.STOP: return
	Game.persist['deaths'] += 1
	kill_all_notes()
	#boyfriend.process_mode = Node.PROCESS_MODE_ALWAYS
	gf.play_anim('sad')
	get_tree().paused = true
	var death = DIE.instantiate()
	stage.game_over_start(death)
	add_child(death)

func song_end() -> void:
	if should_save and JsonHandler.song_variant == '':
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
		SONG = JsonHandler._SONG
		cur_speed = SONG.speed
		Conductor.load_song(SONG.song)
		refresh(true)
	
func refresh(restart:bool = true) -> void: # start song from beginning with no restarts
	Conductor.reset_beats()
	Conductor.bpm = SONG.bpm # reset bpm to init whoops
	
	if !notes.is_empty(): kill_all_notes()
	events.clear()
	
	for strum in ui.player_strums:
		strum.play_anim('static')
		
	boyfriend.play_anim('idle', true)
	dad.play_anim('idle', true)
	
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

func char_from_string(peep:String) -> Character:
	match peep.to_lower().strip_edges():
		'2', 'girlfriend', 'gf', 'spectator': return gf
		'1', 'dad', 'opponent': return dad
		_: return boyfriend
			
var _cam_tween
func event_hit(event:EventData) -> void:
	var luad = LuaHandler.call_func('eventHit', [event.event, event.values])
	if luad == LuaHandler.RET_TYPES.STOP: return
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
			if peep.has_anim(event.values[0]):
				peep.play_anim(event.values[0], true)
				peep.special_anim = true
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
			var zoom_game = 0.06 if is_nan(ev_zoom[1]) else ev_zoom[1] / 2.2
			
			ui.zoom += zoom_ui
			cam.zoom += Vector2(zoom_game, zoom_game)
		'Change Character': 
			var peep := char_from_string(event.values[0])
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
				
			if JsonHandler.get_character(new_char) != null and new_char != peep.cur_char:
				peep.position = last_pos
				peep.load_char(event.values[1])
				if peep.speaker_data.is_empty():
					pass
					
				peep.play_anim(last_anim, true)
				peep.frame = last_frame
				if peep == boyfriend: ui.icon_p1.change_icon(peep.icon, true)
				if peep == dad: ui.icon_p2.change_icon(peep.icon)
		
		'Set GF Speed':
			var new_speed = int(event.values[0])
			gf.dance_beat = new_speed if new_speed != null else 1
		#endregion
		'FocusCamera':
			var char_int = event.values[0] # a little fix
			if event.values[0] is Dictionary:
				char_int = char_int.char
				#if event.values[0].has('x'): focus_offset.x = -event.values[0].x
				if event.values[0].has('y'): focus_offset.y = float(event.values[0].y)
				
			move_cam(int(char_int))
		'PlayAnimation':
			var data = event.values[0]
			var peep := char_from_string(data.target)
			if peep.has_anim(data.anim):
				peep.play_anim(data.anim, data.force)
				peep.special_anim = true
		'SetCameraBop':
			zoom_beat = event.values[0].rate
			zoom_add.game = event.values[0].intensity / 15.0
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
		'ChangeBPM':
			Conductor.bpm = event.values[0]

func good_note_hit(note:Note) -> void:
	if note.type.length() > 0: print(note.type, ' bf')
	var luad = LuaHandler.call_func('goodNoteHit', [notes.find(note), note.dir, note.type]) # making it take the note itself would crash
	if luad == LuaHandler.RET_TYPES.STOP: return
	if !note.should_hit:
		note_miss(note)
		return
	
	if Conductor.vocals: 
		Conductor.audio_volume(1, 1.0)
	
	#boyfriend.material.set_shader_parameter('color_to_be', Color(randf(), randf(), randf()))
		
	var time:float = Conductor.song_pos - note.strum_time if !auto_play else 0.0
	note.rating = Judge.get_rating(time)
	
	if section_data != null:
		if section_data.has('gfSection') and section_data.gfSection and section_data.mustHitSection: note.gf = true

	var judge_info = Judge.get_score(note.rating)
	
	stage.good_note_hit(note)
	var group = ui.get_group('player')
	#if note.gf: group = ui.get_group('gf')
	group.singer = gf if note.gf else boyfriend 
	group.note_hit(note)

	combo += 1
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
		Audio.play_sound('hitsound', Prefs.hitsound_volume / 100.0)

var time_dropped:float = 0
func good_sustain_press(sustain:Note) -> void:
	var luad = LuaHandler.call_func('goodSustainPress', [notes.find(sustain), sustain.dir, sustain.type])
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
			
			LuaHandler.call_func('goodSustainPress', [sustain.dir])

			if section_data != null:
				if section_data.has('gfSection') and section_data.gfSection and section_data.mustHitSection: sustain.gf = true
			
			var group = ui.get_group('player')
			#if sustain.gf: group = ui.get_group('gf')
			group.singer = gf if sustain.gf else boyfriend
			group.note_hit(sustain)
			
			grace = true
			if !Prefs.legacy_score: # change this | if fps too high it dont worky
				score += floor((550 * get_process_delta_time()) * Conductor.playback_rate)
			ui.hp += (4 * get_process_delta_time())
			ui.update_score_txt()

func opponent_note_hit(note:Note) -> void:
	var luad = LuaHandler.call_func('opponentNoteHit', [notes.find(note), note.dir, note.type])
	if luad == LuaHandler.RET_TYPES.STOP: return
	if note.type.length() > 0: print(note.type, ' dad')
	
	LuaHandler.call_func('opponentNoteHit', [note.dir])
	if section_data != null:
		if section_data.has('altAnim') and section_data.altAnim:
			note.alt = '-alt'

		if section_data.has('gfSection') and section_data.gfSection and !section_data.mustHitSection: 
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
	var luad = LuaHandler.call_func('opponentSustainPress', [notes.find(sustain), sustain.dir, sustain.type])
	if luad == LuaHandler.RET_TYPES.STOP: return
	if Conductor.vocals:
		Conductor.audio_volume(2 if Conductor.mult_vocals else 1, 1.0)
	
	LuaHandler.call_func('opponentSustainPress', [sustain.dir])

	if section_data != null:
		if section_data.has('altAnim') and section_data.altAnim:
			sustain.alt = '-alt'
		if section_data.has('gfSection') and section_data.gfSection and !section_data.mustHitSection: 
			sustain.gf = true
	
	var group = ui.get_group('opponent')
	#if sustain.gf: group = ui.get_group('gf')
	group.singer = gf if sustain.gf else dad
	group.note_hit(sustain)

var grace:bool = true
func note_miss(note:Note) -> void:
	var luad = LuaHandler.call_func('noteMiss', [notes.find(note), note.dir, note.type])
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

		kill_note(note)
	
	var be_sad:bool = combo >= 10
	pop_up_combo(['miss', ('000' if be_sad else '')], true)
	if be_sad: 
		gf.play_anim('sad')
		gf.anim_timer = 0.5
		
	combo = 0
	
	if Conductor.vocals:
		Conductor.audio_volume(1, 0)
	ui.update_score_txt() 
	
func ghost_tap(dir:int) -> void:
	var luad = LuaHandler.call_func('onGhostTap', [dir])
	if luad == LuaHandler.RET_TYPES.STOP: return
	Audio.play_sound('missnote'+ str(randi_range(1, 3)), 0.3)
	stage.ghost_tap(dir)
	if Prefs.ghost_tapping == 'insta-kill':
		ui.hp = 0
		return try_death()
		
	misses += 1
	ui.hit_count['miss'] = misses
	boyfriend.sing(dir, 'miss')
	var away = int(30 + (15 * floor(misses / 3.0)))
	score -= 10 if Prefs.legacy_score else away
	
	ui.total_hit += 1
	
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
