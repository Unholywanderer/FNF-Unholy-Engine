extends Node2D

var cur_section:int = 0

var strums = []

const GRID_SIZE:int = 40
const OFF:int = 100
var prev_grid:NoteGrid
var grid:NoteGrid
var next_grid:NoteGrid
var total_grids = []

var note_snap:int = 16
var cur_quant:int = 3:
	set(new_quant):
		cur_quant = wrap(new_quant, 0, quant_list.size())
		note_snap = quant_list[cur_quant]
		$ChartLine/Line/Square.modulate = quant_colors[cur_quant]
		update_text()

var quant_list:Array[int] = [
	4, 8, 12, 16, 
	20, 24, 32, 48,
	64, 96, 128
]

var quant_colors = [
	Color(1.00, 0.00, 0.00),# 4
	Color(0.00, 0.00, 1.00),# 8
	Color(0.40, 0.17, 0.56),# 12
	Color(1.00, 1.00, 0.00),# 16
	Color(1.00, 1.00, 1.00),# 20
	Color(1.00, 0.00, 1.00),# 24
	Color(0.96, 0.58, 0.11),# 32
	Color(0.00, 1.00, 1.00),# 48
	Color(0.00, 0.77, 0.00),# 64
	Color(1.00, 0.60, 0.60),# 96
	Color(0.60, 0.60, 1.00) # 128
]

var selected:ColorRect
var this_note:Array = []

var prev_notes:Array = []
var cur_notes:Array = []
var next_notes:Array = []

var prev_note_data:Array = []
var cur_note_data:Array = []
var next_note_data:Array = []

var prev_events:Array = []
var cur_events:Array = []
var next_events:Array = []
var prev_e_grid:NoteGrid
var event_grid:NoteGrid
var next_e_grid:NoteGrid

var funky_boys:Array[Character] = []

var events:Array[EventData] = []
# TODO
# add events

var char_list:Array = []
var invalid_chars:Array = [] # should only ever be a max of 3, since how song chars works
var SONG
func _ready():
	Game.set_mouse_visibility(true)
	Conductor.reset()
	if JsonHandler.chart_notes.is_empty(): 
		JsonHandler.parse_song('bopeebo', 'hard')
	SONG = JsonHandler._SONG
	events = JsonHandler.song_events
	
	Discord.change_presence('Charting '+ SONG.song.capitalize(), 'One must imagine a charter happy')
	#get_signal_list()
	#JsonHandler.old_notes = JsonHandler.chart_notes.duplicate()
	Conductor.load_song(SONG.song)
	Conductor.connect_signals()
	Conductor.bpm = SONG.bpm
	Conductor.paused = true
	
	for i in ['bf', 'bf-pixel-opponent']:
		var new_boy = Character.new(Vector2.ZERO, i)
		new_boy.scale *= 0.3
		$ChartUI.add_child(new_boy)
		funky_boys.append(new_boy)
		
	funky_boys[0].flip_char()
	funky_boys[0].position = Vector2(700, 530)
	funky_boys[1].position = Vector2(300, 500)
	
	var voices = [Conductor.vocals, Conductor.vocals_opp, 'Voices', 'VoicesOpp']
	for i in 2:
		if voices[i].stream == null:
			tab('Chart', voices[i + 2]).button_pressed = false
			tab('Chart', voices[i + 2]).disabled = true
			tab('Chart', voices[i + 2]).modulate = Color.DIM_GRAY
			tab('Chart', voices[i + 2] +'/Vol').editable = false
			tab('Chart', voices[i + 2] +'/Vol').modulate = Color.DIM_GRAY
		
	tab('Song', 'BPM').value = SONG.bpm
	tab('Song', 'Song').text = SONG.song
	tab('Song', 'Speed').value = SONG.speed
	
	strums = $ChartLine/Left.get_strums()
	strums.append_array($ChartLine/Right.get_strums())
	
	#$ChartLine/IconL.position.x = 166 #idk if this is centered but fuck you
	#$ChartLine/IconR.position.x = 325
	
	var list = FileAccess.get_file_as_string('res://assets/data/order.txt').split(',')
	list.append_array(DirAccess.get_files_at('res://assets/data/characters'))
	for i in list:
		var char = i.replace('.json', '').strip_edges()
		if !char_list.has(char):
			char_list.append(char)
			tab('Song', 'Player1').get_popup().add_item(char)
			tab('Song', 'Player2').get_popup().add_item(char)
			tab('Song', 'GF').get_popup().add_item(char)
	
	var realgf = 'gf'
	#print('love you maru..')
	if SONG.has('gfVersion') or SONG.has('player3'):
		realgf = SONG.gfVersion if SONG.has('gfVersion') else SONG.player3
		if realgf == null: realgf = 'gf'
	SONG.gfVersion = realgf # will make sure that gfVersion exists on the dictionary
		
	for i in [SONG.player1, SONG.player2, SONG.gfVersion]:
		if !char_list.has(i):
			char_list.append(i)
			invalid_chars.append(i)
	
	#TODO maybe make this connect to 1 func
	tab('Song', 'Player1').text = SONG.player1
	tab('Song', 'Player1').get_popup().connect("id_pressed", on_p1_change)

	tab('Song', 'Player2').text = SONG.player2
	tab('Song', 'Player2').get_popup().connect("id_pressed", on_p2_change)
	
	tab('Song', 'GF').text = SONG.gfVersion
	tab('Song', 'GF').get_popup().connect("id_pressed", on_gf_change)

	var chars = [JsonHandler.get_character(SONG.player2), JsonHandler.get_character(SONG.player1)]
	$ChartLine/IconL.change_icon(chars[0].icon if chars[0] != null else 'face')
	$ChartLine/IconR.change_icon(chars[1].icon if chars[1] != null else 'face', true)
	
	$ChartUI/SongProgress/Length.text = Game.to_time(Conductor.song_length)
	
	var vec_size = Vector2(GRID_SIZE, GRID_SIZE)
	grid = NoteGrid.new(vec_size, Vector2(GRID_SIZE * 8, GRID_SIZE * 16))
	grid.position.x = OFF
	grid.name = 'Grid'
	add_child(grid)
	move_child(grid, get_node('Notes').get_index())
	
	prev_grid = NoteGrid.new(vec_size, Vector2(GRID_SIZE * 8, GRID_SIZE * 16))
	prev_grid.position.x = OFF
	prev_grid.position.y = grid.position.y - grid.height
	prev_grid.modulate = Color.DIM_GRAY
	prev_grid.name = 'PrevGrid'
	add_child(prev_grid)
	move_child(prev_grid, get_node('Notes').get_index())
	
	next_grid = NoteGrid.new(vec_size, Vector2(GRID_SIZE * 8, GRID_SIZE * 16))
	next_grid.position.x = OFF
	next_grid.position.y = grid.position.y + grid.height
	next_grid.modulate = Color.DIM_GRAY
	next_grid.name = 'NextGrid'
	add_child(next_grid)
	move_child(next_grid, get_node('Notes').get_index())
	#region | event grids
	prev_e_grid = NoteGrid.new(vec_size, Vector2(GRID_SIZE, GRID_SIZE * 16), [], true)
	prev_e_grid.position.x += OFF / 2.0
	prev_e_grid.position.y = grid.position.y - grid.height
	prev_e_grid.modulate = Color.DIM_GRAY
	add_child(prev_e_grid)
	move_child(prev_e_grid, get_node('Notes').get_index())
	
	event_grid = NoteGrid.new(vec_size, Vector2(GRID_SIZE, GRID_SIZE * 16), [], true)
	event_grid.position.x += OFF / 2.0
	add_child(event_grid)
	move_child(event_grid, get_node('Notes').get_index())
	
	next_e_grid = NoteGrid.new(vec_size, Vector2(GRID_SIZE, GRID_SIZE * 16), [], true)
	next_e_grid.position.x += OFF / 2.0
	next_e_grid.position.y = grid.position.y + grid.height
	next_e_grid.modulate = Color.DIM_GRAY
	add_child(next_e_grid)
	move_child(next_e_grid, get_node('Notes').get_index())
	#endregion
	selected = ColorRect.new()
	selected.custom_minimum_size = vec_size
	$Notes.add_child(selected)
	$Notes.move_child(selected, 0)
	
	$ChartLine/Line/Square.modulate = quant_colors[cur_quant]
	update_text()
	tab('Chart', 'ToggleGrid').button_pressed = Prefs.chart_grid
	tab('Chart', 'ToggleGrid').toggled.connect(_toggle_grid)
	_toggle_grid(tab('Chart', 'ToggleGrid').button_pressed) # update the visibility before we get goin
	#update_grids()

var time_pressed:float = 0.0
var just_pressed:bool = false

var mouse_pos:Vector2 = Vector2.ZERO
var holding_shift:bool = false
var over_grid:bool = false

var time_lerped:float = 0.0
var bg_colors:Array[Color] = [Color.MIDNIGHT_BLUE, Color.REBECCA_PURPLE]
func _process(delta):
	time_lerped += delta / 2.0
	if time_lerped >= 2.0:
		time_lerped = 0
		bg_colors.reverse()
		bg_colors[1] = Color(randf(), randf(), randf())
	$BG.modulate = bg_colors[0].lerp(bg_colors[1], time_lerped / 2.0)
	
	$ChartLine/TimeTxt.text = str(floor(Conductor.song_pos))
	#var strum_y = round(get_y_from_time(fmod(Conductor.song_pos - get_section_time(), Conductor.step_crochet * 16.0)))
	$ChartLine.position.y = round(get_y_from_time(fmod(Conductor.song_pos - get_section_time(), Conductor.step_crochet * 16.0)))
	
	$ChartUI/SongProgress/Time.text = Game.to_time(Conductor.song_pos)
	$ChartUI/SongProgress.value = abs(Conductor.song_pos / Conductor.song_length) * 100.0
	
	var z = 1 #DEBUG, remove later
	$Cam.zoom = Vector2(z, z)
	$Cam.position = $ChartLine.position + Vector2(380, 50) # grid.position + Vector2(grid.width, grid.height / 2)
	$BG.position = $Cam.position
	
	var audios = {'Inst' = Conductor.inst, 'Voices' = Conductor.vocals, 'VoicesOpp' = Conductor.vocals_opp}
	for aud in audios.keys():
		if !tab('Chart', aud).disabled and tab('Chart', aud).button_pressed:
			audios[aud].volume_db = linear_to_db(tab('Chart', aud +'/Vol').value)
		else:
			audios[aud].volume_db = linear_to_db(0)
			
	holding_shift = Input.is_key_pressed(KEY_SHIFT)
	mouse_pos = get_viewport().get_mouse_position() # mouse pos isnt affected by cam movement like flixel
	var cam_off = $Cam.get_screen_center_position() - (get_viewport_rect().size / 2.0) + Vector2(OFF, 0)
	mouse_pos += cam_off
	
	var over_events = mouse_pos.x > event_grid.position.x + OFF and mouse_pos.x < event_grid.position.x + event_grid.width + OFF \
		and mouse_pos.y > event_grid.position.y and mouse_pos.y < event_grid.position.y + (GRID_SIZE * 16)
		
	over_grid = mouse_pos.x > grid.position.x + OFF and mouse_pos.x < grid.position.x + grid.width + OFF \
		and mouse_pos.y > grid.position.y and mouse_pos.y < grid.position.y + (GRID_SIZE * 16)
	
	selected.visible = over_grid
	#if over_grid:
	selected.position.x = floor(mouse_pos.x / GRID_SIZE) * GRID_SIZE - OFF
	var y_pos = 0
	if holding_shift:
		y_pos = mouse_pos.y
	else:
		var snap:float = GRID_SIZE / (note_snap / 16.0)
		y_pos = floor(mouse_pos.y / snap) * snap
		
	selected.position.y = y_pos
	if !Conductor.paused:
		
		#for event in cur_events:
		#	if event.strum_time <= Conductor.song_pos and event.modulate != Color.GRAY:
		#		event.modulate = Color.GRAY
		#		play_strum(event)
				
		for note in prev_notes:
			if note.hitting: play_strum(note) # sustains that go over
				
		for note:BasicNote in cur_notes:
			if note.was_hit:
				if note.hitting: play_strum(note)
				if !note.is_sustain and note.modulate != Color.GRAY:
					note.modulate = Color.GRAY
					if (tab('Chart', 'HitsoundsL').button_pressed and !note.must_press):
						Audio.play_sound('hitsnap', tab('Chart', 'HitsoundsL/Vol').value)
					
					if (tab('Chart', 'HitsoundsR').button_pressed and note.must_press):
						Audio.play_sound('hitsound', tab('Chart', 'HitsoundsR/Vol').value)
		
					play_strum(note)
				
	if this_note != null:
		pass
		#this_note.modulate.a = 0.5
		
	if Input.is_action_just_pressed("back"):
		Conductor.reset_beats()
		Game.reset_scene()
	
func play_strum(note):
	if note is BasicNote:
		#print('NOTE: '+ str(note.position.y) +' | CAM: '+  str($Cam.position.y) +' '+ str(note.position.y + $Cam.position.y))
		var dir = wrap(note.visual_dir, 0, 8)
		strums[dir].play_anim('confirm', true)
		strums[dir].reset_timer = 0.15
	
		funky_boys[0 if dir > 3 else 1].sing(note.dir, '', !note.is_sustain)
	elif note is EventNote:
		$ChartLine/EventStrum.play_anim('confirm', true)
		$ChartLine/EventStrum.reset_timer = 0.15

func on_p1_change(id):
	SONG.player1 = char_list[id]
	on_char_change('Player1')
	
func on_p2_change(id):
	SONG.player2 = char_list[id]
	on_char_change('Player2')

func on_gf_change(id):
	SONG.gfVersion = char_list[id]
	on_char_change('GF')
	
func on_char_change(c:String):
	var new_char
	var _icon
	match c:
		'Player2':
			new_char = SONG.player2
			_icon = $ChartLine/IconL
		'GF': 
			new_char = SONG.gfVersion
		_: 
			new_char = SONG.player1
			_icon = $ChartLine/IconR
			
	tab('Song', c).text = new_char
	var new_json = JsonHandler.get_character(new_char)
	if _icon != null:
		_icon.change_icon(new_json.icon if new_json != null else 'face', c.to_lower() == 'Player1')
	
var bg_tween:Tween
func beat_hit(beat:int) -> void:
	$ChartLine/IconL.bump(0.6)
	$ChartLine/IconR.bump(0.6)
	
	if beat % 2 == 0:
		for i in funky_boys:
			if !i.animation.begins_with('sing'):
				i.dance()
				
	if tab('Chart', 'Metronome').button_pressed: 
		Audio.play_sound('tick', 0.8)
		$BG.scale = Vector2(1.02, 1.02)
		if bg_tween: bg_tween.kill()
		bg_tween = create_tween()
		bg_tween.tween_property($BG, 'scale', Vector2.ONE, Conductor.crochet / 3500.0)

	var be = int(SONG.notes[cur_section].sectionBeats if SONG.notes[cur_section].has('sectionBeats') else 4)
	if beat % be == 0:
		load_section(cur_section + 1)
		#print(str(Conductor.song_pos) +' | '+ str(get_section_time(cur_section)))

func step_hit(step:int) -> void:
	update_text()

func song_end():
	Conductor.reset_beats()
	Conductor.start(0)
	Conductor.paused = true
	load_section(0, true)

func toggle_play() -> void:
	Conductor.paused = !Conductor.paused

func set_dropdown(dropdown:OptionButton, to_val:String = '') -> void: # set a optionbutton's value automatically
	if dropdown != null:
		var items:Array = []
		for i in dropdown.item_count:
			items.append(dropdown.get_item_text(i))
			
		if items.has(to_val):
			dropdown.select(items.find(to_val))
		else:
			dropdown.modulate = Color.RED
			dropdown.add_item(to_val)
			dropdown.select(items.size())

func tab(tab:String, node:String) -> Node:
	return get_node('ChartUI/Tabs/'+ tab +'/'+ node)
		
func load_section(section:int = 0, force_time:bool = false) -> void:
	if SONG.notes.size() <= section:
		return
		#var new = {
	#		'sectionNotes': [],
	#		'mustHitSection': false,
	#		'bpm': SONG.bpm,
	#		'changeBPM': false,
	#		'altAnim': false
	#	}
	#	SONG.notes.append(new)
	
	cur_section = max(section, 0)
	var remake_notes = abs(last_updated_sec - cur_section) > 1

	var sec = SONG.notes[cur_section]
	tab('Section', 'MustHit').button_pressed = sec.mustHitSection
	if sec.has('altAnim'):
		tab('Section', 'AltAnim').button_pressed = sec.altAnim or false
	if sec.has('changeBPM') and sec.has('bpm'):
		tab('Section', 'ChangeBPM').button_pressed = sec.changeBPM if sec.changeBPM != null else false
		tab('Section', 'NewBPM').value = sec.bpm
	else:
		tab('Section', 'ChangeBPM').button_pressed = false
		tab('Section', 'NewBPM').value = 0
			
	if force_time:
		var temp_time:float = 0
		var temp = {'beat': 0, 'beat_t': 0, 'step': 0, 'step_t': 0}
		var temp_croch = (60.0 / SONG.bpm) * 1000.0
		var last_bpm:float = SONG.bpm
		for i in cur_section:
			var bpm = last_bpm
			var da_sec = SONG.notes[i]
			if da_sec.has('changeBPM') and da_sec.changeBPM:
				bpm = max(da_sec.bpm, 1)
				last_bpm = bpm
				temp_croch = (60.0 / bpm) * 1000.0
			
			# set beats and steps back to what they would be
			#NOTE sometimes the beats dont reset to the value, seems to mainly affect songs with bpm changes
			for j in 16:
				temp.step_t += (temp_croch / 4.0)
				temp.step += 1
				if j % 4 == 0:
					temp.beat_t += (60.0 / bpm) * 1000.0
					temp.beat += 1
				
			temp_time += (60.0 / bpm) * 4000.0

		Conductor.cur_beat = temp.beat
		Conductor.beat_time = temp.beat_t
	
		Conductor.cur_step = temp.step
		Conductor.step_time = temp.step_t
		
		Conductor.song_pos = get_section_time(section)
		#Conductor.resync_audio()
		update_text()
		
	update_grids(remake_notes)
	
func _input(event): # this is better
	if event is InputEventMouseButton:
		#if event.is_pressed(): return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and !event.is_released():
			print('clicked at '+ str(mouse_pos - Vector2(100, 0)))
			check_note()
			
			#print(str(mouse_pos - Vector2(100, 0)) +' | '+ str(cur_notes[0].position) +' | '+ str(cur_notes[0].width))
			var click_point = ColorRect.new()
			click_point.custom_minimum_size = Vector2(5, 5)
			click_point.modulate = Color.BLUE_VIOLET
			click_point.position = mouse_pos - Vector2(100, 0)
			add_child(click_point)
			await get_tree().create_timer(1).timeout
			remove_child(click_point)
			click_point.queue_free()
		
		
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_ENTER):
			Conductor.reset_beats()
			Conductor.paused = true
			var c = [null, null, null]
			var ord = ['Player1', 'Player2', 'GF']
			for i in 3:
				c[i] = tab('Song', ord[i]).text
			
			if SONG.has('players'):
				SONG.players = c
			else:
				SONG.player1 = c[0]
				SONG.player2 = c[1]
				SONG.gfVersion = c[2]
				
			
			SONG.bpm = tab('Song', 'BPM').value
			SONG.speed = tab('Song', 'Speed').value
			#JsonHandler._SONG = SONG
			#JsonHandler.generate_chart(SONG)
			Conductor.for_all_audio('volume_db', linear_to_db(1), true)
			Game.switch_scene('Play_Scene')
			
		
		if Input.is_key_pressed(KEY_SPACE):
			toggle_play()
		if Input.is_key_pressed(KEY_Q):
			save_song()
		
		if !this_note.is_empty():
			if Input.is_key_pressed(KEY_Q):
				this_note[2] -= Conductor.step_crochet
				this_note[2] = max(this_note[2], 0)
				update_grids()
			if Input.is_key_pressed(KEY_E):
				this_note[2] += Conductor.step_crochet
				update_grids()
	
		if Input.is_key_pressed(KEY_R):
			if holding_shift:
				cur_section = 0
				Conductor.reset_beats()
			load_section(cur_section, true)
			Conductor.paused = true
		
		if Input.is_key_pressed(KEY_A):
			load_section(cur_section - 1, true)
			Conductor.paused = true
		if Input.is_key_pressed(KEY_D):
			load_section(cur_section + 1, true)
			Conductor.paused = true
		if Input.is_key_pressed(KEY_W):
			pass
		if Input.is_key_pressed(KEY_S):
			pass
		if Input.is_key_pressed(KEY_LEFT):
			cur_quant -= 1
		if Input.is_key_pressed(KEY_RIGHT):
			cur_quant += 1
	
func save_song():
	#var format 
	var all_note = []
	var all_even = []
	var sec_data = []
	
	if char_list.size() - 1 >= tab('Song', 'Player1').selected:
		SONG.player1 = char_list[tab('Song', 'Player1').selected]
	if char_list.size() - 1 >= tab('Song', 'Player2').selected:
		SONG.player2 = char_list[tab('Song', 'Player2').selected]
	if char_list.size() - 1 >= tab('Song', 'GF').selected:
		SONG.gfVersion = char_list[tab('Song', 'GF').selected]
	
	var chars = [SONG.player1, SONG.player2, SONG.gfVersion]
	for i in SONG.notes:
		if i.has('events'):
			all_even.append(i.events)

		for n in i.sectionNotes:
			n[0] = round(max(n[0], 0))
			if n[1] > -1: all_note.append(n)
		var s:Dictionary = i.duplicate()
		s.erase('sectionNotes')
		if s.has('events'):
			s.erase('events')
		
		sec_data.append(s)
	all_note.sort_custom(func(a, b): return a[0] < b[0])
	
	var format = {
		'song': SONG.song,
		'chars': chars,
		'bpm': SONG.bpm,
		'speed': SONG.speed,
		'events': all_even,
		'notes': all_note,
		'sections': sec_data, 
	}
	var to_save = UnholyFormat.new()
	for i:String in format.keys():
		if to_save.get(i) == null: continue
		to_save.set(i, format[i])
		print('saved '+ i)
	#var new_file:FileAccess = FileAccess.open('res://assets/test.json', FileAccess.WRITE)
	#new_file.store_string(JSON.stringify(to_save, '\t', false))
	
	ResourceSaver.save(to_save, 'res://assets/test.tres', ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES)
	var tes = ResourceLoader.load('res://assets/test.tres')
	print(tes.notes)

var last_updated_sec:int = -1
func update_grids(skip_remake:bool = false, only_current:bool = false) -> void:
	Game.remove_all([prev_notes, cur_notes, next_notes, cur_events], $Notes)
	
	$ChartLine/Highlight.position = ($ChartLine/IconR.position if SONG.notes[cur_section].mustHitSection else $ChartLine/IconL.position) - Vector2(37.5, 37.5)
	if SONG.notes[cur_section].has('changeBPM') and SONG.notes[cur_section].changeBPM:
		Conductor.bpm = max(SONG.notes[cur_section].bpm, 1)
	else:
		#get last bpm
		var last_bpm:float = SONG.bpm
		for i in cur_section:
			if SONG.notes[i].has('changeBPM') and SONG.notes[i].changeBPM:
				last_bpm = max(SONG.notes[i].bpm, 1)
		Conductor.bpm = last_bpm

	$ChartLine/BPMTxt.text = str(Conductor.bpm) +' BPM'
	
	prev_grid.visible = cur_section > 0
	prev_e_grid.visible = prev_grid.visible
	next_grid.visible = cur_section < SONG.notes.size() - 1
	next_e_grid.visible = next_grid.visible
	
	if cur_section > 0 and prev_grid.visible:
		var last_sec = SONG.notes[cur_section - 1]
		make_notes.call(last_sec, prev_grid, -1, prev_notes)
			
	var ev_times = {'start': get_section_time(cur_section), 'end': get_section_time(cur_section + 1)}
	var tot:int = 0
	for evn in events:
		if evn.strum_time >= ev_times.start and evn.strum_time < ev_times.end:
			tot += 1
			var new_event = EventNote.new(evn)
			$Notes.add_child(new_event)
			new_event.strum_time = evn.strum_time
			cur_events.append(new_event)
			do_note_shit(new_event)
			new_event.position.y = floori(get_y_from_time(fmod(floor(evn.strum_time) - get_section_time(), Conductor.step_crochet * 16)))
	print('loaded '+ str(tot) +' events')
		
	var new_sec = SONG.notes[cur_section]
	make_notes.call(new_sec, grid, 0, cur_notes)
	
	if cur_section <= SONG.notes.size() - 1 and next_grid.visible:
		var next_sec = SONG.notes[cur_section + 1]
		make_notes.call(next_sec, next_grid, 1, next_notes)
	
func make_notes(sec_info:Dictionary, for_grid:NoteGrid, id:int, note_array:Array):
	for info:Array in sec_info.sectionNotes:
		if info.is_empty() or info[1] == -1: continue
		if info[2] is not float: info[2] = 0
			
		var must_press:bool = (sec_info.mustHitSection and info[1] <= 3) or (!sec_info.mustHitSection and info[1] > 3)
		var type:String = (str(info[3]) if info.size() > 3 else '')
		var new_note:BasicNote = BasicNote.new([info[0], info[1], null, info[2], must_press, type], false) #reuse_note([info[0], info[1], null, info[2], must_press, type])
		$Notes.add_child(new_note)
			
		var fake_dir:int = info[1]
		if sec_info.mustHitSection:
			fake_dir += 4 if must_press else -4
		
		do_note_shit(new_note, fake_dir)
		
		new_note.position.y = floori(get_y_from_time(fmod(floor(info[0]) - get_section_time(cur_section + id), Conductor.step_crochet * 16))) + (grid.height * id)
		new_note.modulate = for_grid.modulate
		if for_grid == grid:
			if floor(new_note.strum_time) < floor(Conductor.song_pos) - 10: # slight offset so the first note of a section can always get hit
				new_note.modulate = Color.GRAY
		note_array.append(new_note)
		
		if info[2] > 0:
			var sustain:BasicNote = BasicNote.new(new_note, true)
			$Notes.add_child(sustain)
			$Notes.move_child(sustain, 1)
			do_note_shit(sustain, new_note.visual_dir)
			
			sustain.hold_group.size.x = 50 # close enough for now
			sustain.hold_group.size.y = floori(remap(info[2], 0, Conductor.step_crochet * 16.0, 0, grid.height * 3.87))
			
			sustain.position = new_note.position + Vector2(-7, 40)
			sustain.modulate = for_grid.modulate
			sustain.alpha = 0.6
				
			note_array.append(sustain)

func do_note_shit(note, dir:int = 0) -> void:
	note.scale = Vector2(0.26, 0.26)
	if note is not EventNote:
		note.visual_dir = dir

	if !note.is_sustain:
		var x_diff:float = -1.25 if note is EventNote else float(dir)
		note.position.x = 120 + (GRID_SIZE * (x_diff))
		if note.note.offset.y == 0:
			note.note.offset.y += GRID_SIZE * 2
	
func check_note() -> void:
	var clicked_note:bool = false
	for note in cur_notes:
		if note.is_sustain: continue
		var note_pos = note.position.x - note.width / 2
		if mouse_pos.x - 100 >= note_pos and mouse_pos.x - 100 <= note_pos + GRID_SIZE \
		  and mouse_pos.y >= note.position.y and mouse_pos.y <= note.position.y + GRID_SIZE:
			clicked_note = true
			if Input.is_key_pressed(KEY_CTRL): #Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				select_note(note)
			else:
				remove_note(note)
		
	if !clicked_note and over_grid: # so you can click notes that are somehow off the grid, but not add more
		add_note()
		
func add_note() -> void:
	var time = get_strum_from_y(selected.position.y) + get_section_time()
	var direct:int = floor(mouse_pos.x / GRID_SIZE) - (1 if SONG.notes[cur_section].mustHitSection else 5)
	
	SONG.notes[cur_section].sectionNotes.append([time, direct, 0])
	SONG.notes[cur_section].sectionNotes.sort_custom(func(a, b): return a[0] < b[0])
	
	this_note = SONG.notes[cur_section].sectionNotes[(SONG.notes[cur_section].sectionNotes.find([time, direct, 0]))]
	update_grids()
	
func select_note(note:BasicNote) -> void:
	var id:int = 0
	for i in SONG.notes[cur_section].sectionNotes:
		if floor(i[0]) == note.strum_time and i[1] == note.true_dir:
			this_note = SONG.notes[cur_section].sectionNotes[id]
			print('selected note')
			break
		id += 1

func remove_note(note:BasicNote) -> void:
	for i in SONG.notes[cur_section].sectionNotes:
		if floor(i[0]) == note.strum_time and i[1] == note.true_dir:
			this_note.clear()
			SONG.notes[cur_section].sectionNotes.erase(i)
			print('cleared note')
	
	update_grids()

func update_text() -> void:
	$ChartUI/Info.text = \
		"Beat: "+ str(Conductor.cur_beat) +"\n"+ \
		"Step: "+ str(Conductor.cur_step) +"\n"+ \
		"Sect: "+ str(cur_section)      +"\n\n"+ \
		"Snap: "+ str(note_snap) +"th"

func _toggle_grid(toggled:bool) -> void:
	#Conductor.paused = true
	for i in [prev_grid, grid, next_grid]:
		if i != null:
			for sqr in i.grid: sqr.visible = toggled
			for mrk in i.markers: mrk.visible = !toggled
	update_grids()

func get_y_from_time(strum_time:float) -> float:
	return remap(strum_time, 0, 16 * Conductor.step_crochet, grid.position.y, grid.position.y + grid.height)

func get_strum_from_y(y_pos:float) -> float:
	return remap(y_pos, grid.position.y, grid.position.y + grid.height, 0, 16 * Conductor.step_crochet)

func get_section_time(this_sec:int = -1):
	if this_sec < 0: this_sec = cur_section
	var pos:float = 0
	var bpm:float = SONG.bpm
	for i in this_sec:
		var da_sec = SONG.notes[i]
		if da_sec.has('changeBPM') and da_sec.changeBPM:
			bpm = max(da_sec.bpm, 1)
		pos += 4.0 * (1000.0 * 60.0 / bpm)
	return pos

#func _ui_item_changed(ui_item, index:int = -2):
#	if ['Player1', 'Player2', 'GF'].has(ui_item.name):
#		pass

class EventNote extends Note:
	var ev_name:String = 'Nothing!'
	var ev_extra:String = '' 
	
	var label:Label
	func _init(event:EventData):
		is_sustain = false # just in case
		label = Label.new()
		label.add_theme_font_override('font', ResourceLoader.load('res://assets/fonts/vcr.ttf', 'FontFile'))
		label.add_theme_font_size_override('font_size', 15)
		label.add_theme_constant_override('outline_size', 5)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)
		label.scale *= 4
		
		label.position.x -= 550 + (label.get_total_character_count() * 5)

		chart_note = true
		note = Sprite2D.new()
		note.texture = ResourceLoader.load('res://assets/images/ui/event.png')
		add_child(note)
		if event != null:
			ev_name = event.event
			ev_extra = str(event.values)
			#ev_extra.substr(0, ev_extra.length() - 2)
		label.text = ev_name +'\n'+ ev_extra
	
	func _ready(): pass

class NoteGrid extends Control:
	var width:int
	var height:int
	var grid:Array = []
	var markers:Array[ColorRect] = []
	
	func _init(cell_size:Vector2, grid_size:Vector2, colors:Array[Color] = [], _skip:bool = false):
		if colors.is_empty(): colors = [Color(0.30, 0.30, 0.30), Color(0.20, 0.20, 0.20)]
		
		var prev_col:Color = colors[1]
		var x:int = 0
		var y:int = 0
		while y < grid_size.y:
			if y > 0:
				colors.reverse()
				prev_col = colors[1]
				
			x = 0
			while x < grid_size.x:
				if !_skip:
					var grid_square = ColorRect.new()
					grid_square.modulate = prev_col
					prev_col = colors[0] #if prev_col == colors[1] else colors[1]
					colors.reverse()
					grid_square.position = Vector2(x, y)
					grid_square.custom_minimum_size = cell_size
					add_child(grid_square)
					grid.append(grid_square)
				x += floor(cell_size.x)
				
			y += floor(cell_size.y)
	
		width = x
		height = y
		
		if cell_size.x != grid_size.x: # if the grid is 1 cell wide, no need for the center mark
			var center = ColorRect.new()
			center.custom_minimum_size = Vector2(3, height)
			center.modulate = Color.LIGHT_SLATE_GRAY
			center.position = position
			center.position.x += (width / 2.0) - 1.5
			add_child(center)
		
		for i in 4:
			var beat_mark = ColorRect.new()
			beat_mark.custom_minimum_size = Vector2(width, 2)
			beat_mark.modulate = Color.RED
			beat_mark.position = position
			beat_mark.position.y += int(height / 4.0) * i
			add_child(beat_mark)
			
		for i in 16:
			var step_mark = ColorRect.new()
			step_mark.custom_minimum_size = Vector2(width - (width / 4.0), 2)
			step_mark.modulate = Color.SKY_BLUE
			step_mark.modulate.a = 0.8
			step_mark.position = position
			step_mark.position.x += int(width / 8.0)
			step_mark.position.y += int(height / 16.0) * i
			add_child(step_mark)
			markers.append(step_mark)
