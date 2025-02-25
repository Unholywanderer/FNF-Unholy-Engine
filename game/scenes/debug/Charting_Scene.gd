extends Node2D

var cur_section:int = 0
var clicked_section:int = 0

var strums = []

# Grid stuff
const GRID_SIZE:int = 40
const OFF:int = 100 # offset from screen

var grid_0:NoteGrid
var grid_1:NoteGrid
var grid_2:NoteGrid

var event_grid_0:NoteGrid
var event_grid_1:NoteGrid
var event_grid_2:NoteGrid

# Quant/Snap stuff
var note_snap:int = 16
var cur_quant:int = 3:
	set(new_quant):
		cur_quant = wrap(new_quant, 0, quant_list.size())
		note_snap = quant_list[cur_quant]
		$ChartLine/Line/Square.modulate = quant_colors[cur_quant]
		update_text()

var quant_list:Array[int] = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 128]

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

var copied_notes:Array = []

var note_chunks:Dictionary = {
	'-1': [], '0': [], '1': []
}

var note_list:Array = []
var notes_loaded:Array = []

var prev_events:Array = []
var cur_events:Array = []
var next_events:Array = []

var funky_boys:Array[Character] = []

var events:Array[EventData] = []

var section_based:bool = true
var char_list:Array = []
var invalid_chars:Array = [] # should only ever be a max of 3, since how song chars works
var stage_list:Array = []
var SONG
func _ready():
	Game.set_mouse_visibility(true)
	Audio.stop_music() # just in case
	Conductor.reset()
	if JsonHandler.chart_notes.is_empty(): 
		JsonHandler.parse_song('bopeebo', 'hard')
	SONG = JsonHandler._SONG
	events = JsonHandler.song_events
	
	if JsonHandler.parse_type == 'v_slice':
		section_based = false
		note_list = SONG.notes[JsonHandler.get_diff]
		
	Discord.change_presence('Charting '+ SONG.song.capitalize(), 'One must imagine a charter happy')
	#get_signal_list()
	Conductor.load_song(SONG.song)
	Conductor.connect_signals()
	Conductor.bpm = SONG.bpm
	Conductor.paused = true
	Game.focus_change.connect(focus_changed)
	
	var lil_box = ColorRect.new()
	lil_box.color = Color.DARK_SLATE_GRAY
	lil_box.position = Vector2(180, 591)
	lil_box.custom_minimum_size = Vector2(100, 55)
	$ChartUI.add_child(lil_box)
	
	for i in ['bf', 'bf-pixel-opponent', 'gf']:
		var new_boy = Character.new(Vector2.ZERO, i)
		new_boy.scale *= 0.3
		$ChartUI.add_child(new_boy)
		funky_boys.append(new_boy)
	$ChartUI.move_child(funky_boys[2], lil_box.get_index() + 1)
	
	funky_boys[0].flip_char()
	funky_boys[0].position = Vector2(250, 550)
	funky_boys[1].position = Vector2(200, 520)
	funky_boys[2].position = Vector2(180, 500)
	
	var voices = [Conductor.vocals, Conductor.mult_vocals, 'Voices', 'VoicesOpp']
	for i in 2:
		if !voices[i]:
			tab('Chart', voices[i + 2]).button_pressed = false
			tab('Chart', voices[i + 2]).disabled = true
			tab('Chart', voices[i + 2]).modulate = Color.DIM_GRAY
			tab('Chart', voices[i + 2] +'/Vol').editable = false
		
	tab('Song', 'BPM').value = SONG.bpm
	tab('Song', 'Song').text = SONG.song
	tab('Song', 'Speed').value = SONG.speed
	
	strums = $ChartLine/Left.get_strums()
	strums.append_array($ChartLine/Right.get_strums())
	
	var list = FileAccess.get_file_as_string('res://assets/data/order.txt').split(',')
	list.append_array(DirAccess.get_files_at('res://assets/data/characters'))
	for i in list:
		var char = i.replace('.json', '').strip_edges()
		if !char_list.has(char):
			char_list.append(char)
			tab('Song', 'Player1').get_popup().add_item(char)
			tab('Song', 'Player2').get_popup().add_item(char)
			tab('Song', 'GF').get_popup().add_item(char)
		
	for i in [Game.persist.stage_list, DirAccess.get_files_at('res://game/scenes/stages')]:
		for stage in i:
			if stage_list.has(stage.replace('.tscn', '')) or stage.ends_with('.gd'): continue
			stage = stage.replace('.tscn', '')
			stage_list.append(stage)
			tab('Song', 'Stage').get_popup().add_item(stage)

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
			
	var update:Callable = func(id:int, char:String = 'Player1'):
		SONG[char] = char_list[id]
		on_char_change(char)
	
	for i:String in ['player1', 'player2', 'gfVersion']:
		var caps = i.capitalize().replace(' ', '') if i != 'gfVersion' else 'GF'
		tab('Song', caps).text = SONG[i]
		tab('Song', caps).get_popup().connect("id_pressed", update.bind(i))
	
	tab('Song', 'Stage').text = SONG.stage if SONG.has('stage') else '---'
	tab('Song', 'Stage').get_popup().connect("id_pressed", func(id):
		tab('Song', 'Stage').text = stage_list[id]
	)
	
	tab('Song', 'Clear').pressed.connect(func():
		var _notes = tab('Song', 'Clear/NotesBox')
		var _event = tab('Song', 'Clear/EventBox')
		if _notes.button_pressed:
			if section_based:
				for sec in SONG.notes:
					if !sec.has('sectionNotes'): continue
					sec.sectionNotes.clear()
			else:
				note_list.clear()
				SONG.notes[JsonHandler.get_diff].clear()
					
		if _event.button_pressed:
			if SONG.has('events'): SONG.events.clear()
		
		regen_notes()
		_notes.button_pressed = false
		_event.button_pressed = false
	)
	
	#tab('Section', 'MustHit').toggled.connect(func(togg:bool):
	#	SONG.notes[cur_section].mustHitSection = togg
	#	regen_notes()
	#)
	
	tab('Section', 'CopySec').pressed.connect(func():
		pass
		#copied_notes = note_chunks['0'].duplicate()
	)
	tab('Section', 'PasteSec').pressed.connect(func():
		if copied_notes.size() > 0:
			for i in copied_notes: 
				i[0] += get_section_time()
			SONG.notes[cur_section].sectionNotes = copied_notes.duplicate()
			regen_notes()
	)
	
	tab('Section', 'ClearSec').pressed.connect(func():
		SONG.notes[cur_section].sectionNotes.clear()
		regen_notes()
	)

	var chars = [JsonHandler.get_character(SONG.player2), JsonHandler.get_character(SONG.player1)]
	$ChartLine/IconL.change_icon(chars[0].icon if chars[0] else 'face')
	$ChartLine/IconR.change_icon(chars[1].icon if chars[1] else 'face', true)
	
	$ChartUI/SongProgress/Length.text = Game.to_time(Conductor.song_length)
	
	var vec_size = Vector2(GRID_SIZE, GRID_SIZE)
	
	grid_0 = NoteGrid.new(vec_size, Vector2(GRID_SIZE * 8, GRID_SIZE * 16))
	grid_0.position.x = OFF
	grid_0.position.y -= grid_0.height
	#grid_0.modulate = Color.DIM_GRAY
	grid_0.name = 'PrevGrid'
	add_child(grid_0)
	move_child(grid_0, get_node('Notes').get_index())
	
	grid_1 = NoteGrid.new(vec_size, Vector2(GRID_SIZE * 8, GRID_SIZE * 16))
	grid_1.position.x = OFF
	grid_1.name = 'Grid'
	add_child(grid_1)
	move_child(grid_1, get_node('Notes').get_index())
	
	grid_2 = NoteGrid.new(vec_size, Vector2(GRID_SIZE * 8, GRID_SIZE * 16))
	grid_2.position.x = OFF
	grid_2.position.y += grid_2.height
	#grid_2.modulate = Color.DIM_GRAY
	grid_2.name = 'NextGrid'
	add_child(grid_2)
	move_child(grid_2, get_node('Notes').get_index())
	#region | event grids
	event_grid_0 = NoteGrid.new(vec_size, Vector2(GRID_SIZE, GRID_SIZE * 16), [], true)
	event_grid_0.position.x += OFF / 2.0
	event_grid_0.position.y = grid_0.position.y
	#event_grid_0.modulate = Color.DIM_GRAY
	add_child(event_grid_0)
	move_child(event_grid_0, get_node('Notes').get_index())
	
	event_grid_1 = NoteGrid.new(vec_size, Vector2(GRID_SIZE, GRID_SIZE * 16), [], true)
	event_grid_1.position.x += OFF / 2.0
	add_child(event_grid_1)
	move_child(event_grid_1, get_node('Notes').get_index())
	
	event_grid_2 = NoteGrid.new(vec_size, Vector2(GRID_SIZE, GRID_SIZE * 16), [], true)
	event_grid_2.position.x += OFF / 2.0
	event_grid_2.position.y = grid_2.position.y
	#event_grid_2.modulate = Color.DIM_GRAY
	add_child(event_grid_2)
	move_child(event_grid_2, get_node('Notes').get_index())
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
	#regen_notes()

var time_pressed:float = 0.0
var just_pressed:bool = false

var mouse_pos:Vector2 = Vector2.ZERO:
	set(new_pos):
		mouse_pos = new_pos
		var cam_off = $Cam.get_screen_center_position() - (get_viewport_rect().size / 2.0) + Vector2(OFF, 0)
		mouse_pos += cam_off # account for cam movements
		
var holding_shift:bool = false
var over_grid:bool = false

var time_lerped:float = 0.0
var bg_colors:Array[Color] = [Color.MIDNIGHT_BLUE, Color.REBECCA_PURPLE]

var z = 1 #DEBUG, remove later
func _process(delta):
	time_lerped += delta / 2.0
	if time_lerped >= 2.0:
		time_lerped = 0
		bg_colors.reverse()
		bg_colors[1] = Color(randf(), randf(), randf())
	$BG.modulate = bg_colors[0].lerp(bg_colors[1], time_lerped / 2.0)
	
	$ChartLine/TimeTxt.text = str(floor(int(Conductor.song_pos)))
	#var strum_y = round(get_y_from_time(fmod(Conductor.song_pos - get_section_time(), Conductor.step_crochet * 16.0)))
	$ChartLine.position.x = (grid_1.position.x / 7.0) - 0.5
	$ChartLine.position.y = round(get_y_from_time(fmod(Conductor.song_pos - get_section_time(), Conductor.step_crochet * 16.0)))
	
	$ChartUI/SongProgress/Time.text = Game.to_time(Conductor.song_pos)
	$ChartUI/SongProgress.value = abs(Conductor.song_pos / Conductor.song_length) * 100.0
	
	if Input.is_key_pressed(KEY_F): z -= 0.1 * delta
	if Input.is_key_pressed(KEY_H): z += 0.1 * delta
	
	$Cam.zoom = Vector2(z, z)
	
	$Cam.position = $ChartLine.position + Vector2($ChartLine/Line.size.x / 2.0, 50) # grid_1.position + Vector2(grid_1.width, grid_1.height / 2)
	$BG.position = $Cam.position
	
	var audios = ['Inst', 'Voices', 'VoicesOpp']
	for i in audios.size():
		var aud = audios[i]
		var can_set = tab('Chart', aud).button_pressed
		if !tab('Chart', aud).disabled:
			Conductor.audio_volume(i, tab('Chart', aud +'/Vol').value if can_set else 0)
			
	holding_shift = Input.is_key_pressed(KEY_SHIFT)

	var over_events = mouse_pos.x > event_grid_0.position.x + OFF and mouse_pos.x < event_grid_0.position.x + event_grid_0.width + OFF \
		and mouse_pos.y > event_grid_0.position.y and mouse_pos.y < event_grid_2.position.y + (GRID_SIZE * 16)
		
	over_grid = mouse_pos.x > grid_0.position.x + OFF and mouse_pos.x < grid_0.position.x + grid_0.width + OFF \
		and mouse_pos.y > grid_0.position.y and mouse_pos.y < grid_2.position.y + (GRID_SIZE * 16)
	
	selected.visible = over_grid or over_events
	#if over_grid:
	selected.position.x = event_grid_0.position.x if over_events else floor(mouse_pos.x / GRID_SIZE) * GRID_SIZE - OFF
	var y_pos = 0
	if holding_shift:
		y_pos = mouse_pos.y
	else:
		var snap:float = GRID_SIZE / (note_snap / 16.0)
		y_pos = floor(mouse_pos.y / snap) * snap
		
	mouse_pos = get_viewport().get_mouse_position() # update this every frame
	selected.position.y = y_pos
	
	if !Conductor.paused:
		for note in notes_loaded:
			if note is EventNote:
				if note.was_hit and note.modulate != Color.GRAY:
					event_hit(note)
					note.modulate = Color.GRAY
					play_strum(note)
					continue
					
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
		
	if Input.is_action_just_pressed("back"):
		Conductor.reset_beats()
		Game.reset_scene()

var last_bpm:float
func event_hit(event:EventNote):
	var le_values = event.raw_data.values
	match event.ev_name:
		'FocusCamera':
			var char_int = le_values[0]
			if char_int is Dictionary:
				char_int = char_int.char
			$ChartLine/Highlight.position = ($ChartLine/IconR.position if char_int == 0 else $ChartLine/IconL.position) - Vector2(37.5, 37.5)
		'ChangeBPM':
			Conductor.bpm = le_values[0]
		
func make_note(info, must_hit:bool = true):
	var new_note:BasicNote
	var sus_len:float
	if info is Dictionary:
		if info.keys().size() == 0: return
		sus_len = maxf(0.0, info.l) if info.has('l') else 0.0

		var type:String = (str(info.k) if info.has('k') else '')
		new_note = BasicNote.new([info.t, info.d, null, sus_len, info.d <= 3, type], false)
		new_note.true_dir = info.d
	else:
		if info.is_empty() or info[1] == -1: return
		if info[2] is not float: info[2] = 0
	
		var must_press:bool = (must_hit and info[1] <= 3) or (!must_hit and info[1] > 3)
		if JsonHandler.parse_type == 'psych_v1': must_press = info[1] <= 3
		var type:String = (str(info[3]) if info.size() > 3 else '')
		sus_len = info[2]
		new_note = BasicNote.new([info[0], info[1], null, info[2], must_press, type], false)
		new_note.true_dir = info[1]

	$Notes.add_child(new_note)
	var lane_to_use:int = int(new_note.dir) % 4
	if new_note.must_press:
		lane_to_use += 4
		
	update_note_pos(new_note, lane_to_use)
	
	new_note.position.y = floori(get_y_from_time(fmod(floor(new_note.strum_time) - get_section_time(cur_section), Conductor.step_crochet * 48)))
	
	if floor(new_note.strum_time) < floor(Conductor.song_pos) - 10: # slight offset so the first note of a section can always get hit
		new_note.modulate = Color.GRAY
	notes_loaded.append(new_note)
	
	if sus_len > 0:
		var sustain:BasicNote = BasicNote.new(new_note, true)
		$Notes.add_child(sustain)
		$Notes.move_child(sustain, 1)
		update_note_pos(sustain, new_note.lane)
		
		sustain.hold_group.size.x = 50 # close enough for now
		sustain.hold_group.size.y = floori(remap(sus_len, 0, Conductor.step_crochet * 16.0, 0, grid_1.height * 3.87))
		
		sustain.position = new_note.position + Vector2(-7, 40)
		sustain.alpha = 0.6
		
		notes_loaded.append(sustain)

func play_strum(note):
	if note is EventNote:
		$ChartLine/EventStrum.play_anim('confirm', true)
		$ChartLine/EventStrum.reset_timer = 0.15
	else:
		var dir = wrap(note.lane, 0, 8)
		strums[dir].play_anim('confirm', true)
		strums[dir].reset_timer = 0.15
	
		funky_boys[0 if dir > 3 else 1].sing(note.dir, '', !note.is_sustain)

func on_char_change(c:String):
	var new_char:String
	var _icon:Icon
	match c.to_lower():
		'player2':
			c = 'Player2'
			new_char = SONG.player2
			_icon = $ChartLine/IconL
		'gfversion': 
			c = 'GF'
			new_char = SONG.gfVersion
		_: 
			c = 'Player1'
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
	
	for i in funky_boys:
		if !i.animation.begins_with('sing') and beat % i.dance_beat == 0:
			i.dance()
		
	if tab('Chart', 'Metronome').button_pressed: 
		Audio.play_sound('tick', 0.8)
		$BG.scale = Vector2(1.02, 1.02)
		if bg_tween: bg_tween.kill()
		bg_tween = create_tween()
		bg_tween.tween_property($BG, 'scale', Vector2.ONE, Conductor.crochet / 3500.0)

	#var be = int(SONG.notes[cur_section].sectionBeats if SONG.notes[cur_section].has('sectionBeats') else 4)
	#if beat % be == 0:
	#	load_section(cur_section + 1)
		#print(str(Conductor.song_pos) +' | '+ str(get_section_time(cur_section)))

func section_hit(sec:int):
	if Conductor.cur_section == 0: Conductor.cur_section = 1 # cheap fix
	load_section(Conductor.cur_section)

func step_hit(step:int) -> void:
	update_text()

func song_end():
	Conductor.reset_beats()
	Conductor.start(0)
	#Conductor.paused = true
	load_section(0, true)

## Set an optionbutton's value automatically
func set_dropdown(dropdown:OptionButton, to_val:String = '') -> void:
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
	if section_based:
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

	if section_based:
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
		Conductor.paused = true
		var temp_time:float = 0
		var temp = {'beat': 0, 'beat_t': 0, 'step': 0, 'step_t': 0}
		var temp_croch = (60.0 / SONG.bpm) * 1000.0
		var last_bpm:float = SONG.bpm
		for i in cur_section:
			var bpm = last_bpm
			var da_sec = SONG.notes[i] if section_based else {}
			if da_sec.has('changeBPM') and da_sec.changeBPM:
				bpm = max(da_sec.bpm, 1)
				last_bpm = bpm
				temp_croch = (60.0 / bpm) * 1000.0
			
			# set beats and steps back to what they would be
			var le_beats:int = int(da_sec.sectionBeats) if da_sec.has('sectionBeats') else 4
			for j in le_beats * 4:
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
		
		Conductor.cur_section = section
		Conductor.song_pos = get_section_time(section)
		#Conductor.resync_audio()
		update_text()
		
	regen_notes(remake_notes)
	
func _input(event): # this is better
	mouse_pos = get_viewport().get_mouse_position() # 
	if event is InputEventMouseButton:
		#if event.is_pressed(): return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and !event.is_released():
			get_viewport().gui_release_focus()
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
		
	if event is InputEventKey and get_viewport().gui_get_focus_owner() == null:
		match event.keycode:
			KEY_ENTER:
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
				SONG.stage = tab('Song', 'Stage').text
				JsonHandler.generate_chart(SONG)
				JsonHandler._SONG = SONG
				Conductor.audio.volume_db = linear_to_db(1)
				Game.switch_scene('Play_Scene')
			
			
			#KEY_SPACE:
		#if Input.is_key_pressed(KEY_ENTER):
		#	Conductor.reset_beats()
		#	Conductor.paused = true
		#	var c = [null, null, null]
		#	var ord = ['Player1', 'Player2', 'GF']
		#	for i in 3:
		#		c[i] = tab('Song', ord[i]).text
			
		#	if SONG.has('players'):
		#		SONG.players = c
		#	else:
		#		SONG.player1 = c[0]
		#		SONG.player2 = c[1]
		#		SONG.gfVersion = c[2]
				
			
		#	SONG.bpm = tab('Song', 'BPM').value
		#	SONG.speed = tab('Song', 'Speed').value
		#	SONG.stage = tab('Song', 'Stage').text
			#JsonHandler._SONG = SONG
			#JsonHandler.generate_chart(SONG)
		#	Conductor.for_all_audio('volume_db', linear_to_db(1), true)
		#	Game.switch_scene('Play_Scene')
		
		if Input.is_key_pressed(KEY_G):
			var save_son
			
		
		if Input.is_key_pressed(KEY_SPACE):
			Conductor.paused = !Conductor.paused
		
		if !this_note.is_empty():
			if Input.is_key_pressed(KEY_Q):
				this_note[2] -= Conductor.step_crochet
				this_note[2] = max(this_note[2], 0)
				regen_notes()
			if Input.is_key_pressed(KEY_E):
				this_note[2] += Conductor.step_crochet
				regen_notes()
	
		if Input.is_key_pressed(KEY_R):
			if holding_shift:
				cur_section = 0
				Conductor.reset_beats()
			load_section(cur_section, true)
		
		if Input.is_key_pressed(KEY_A): load_section(cur_section - 1, true)
		if Input.is_key_pressed(KEY_D): load_section(cur_section + 1, true)
		
		if Input.is_key_pressed(KEY_W): pass
		if Input.is_key_pressed(KEY_S): pass
		if Input.is_key_pressed(KEY_LEFT): cur_quant -= 1
		if Input.is_key_pressed(KEY_RIGHT): cur_quant += 1
	
var last_updated_sec:int = -1
var last_got_bpm:float
func regen_notes(skip_remake:bool = false, only_current:bool = false) -> void:
	Game.remove_all([notes_loaded], $Notes)
	
	if section_based:
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
	
	grid_0.visible = cur_section > 0
	event_grid_0.visible = grid_0.visible

	for i in note_chunks.keys():
		note_chunks[i].clear()
	
	var min_time = get_section_time(cur_section - 1)
	var max_time = get_section_time(cur_section + 2)
	if section_based and SONG.notes is Array:
		grid_2.visible = cur_section < SONG.notes.size() - 1
		event_grid_2.visible = grid_2.visible
	
		if cur_section > 0: note_chunks['-1'].append(SONG.notes[cur_section - 1].sectionNotes.duplicate())
		note_chunks['0'].append(SONG.notes[cur_section].sectionNotes.duplicate())
		if cur_section < SONG.notes.size() - 1: note_chunks['1'].append(SONG.notes[cur_section + 1].sectionNotes.duplicate())
	
		for chunk in note_chunks.keys():
			if note_chunks[chunk].size() == 0: continue
			for arr in note_chunks[chunk]:
				for note in arr:
					make_note(note, SONG.notes[cur_section + int(chunk)].mustHitSection)
	else:
		for note in note_list:
			if note.t >= min_time and note.t < max_time:
				make_note(note, true)
			
	if events.size() > 0:
		for evn in events:
			if evn.strum_time >= min_time and evn.strum_time < max_time:
				var new_event = EventNote.new(evn)
				$Notes.add_child(new_event)
				new_event.strum_time = evn.strum_time
				notes_loaded.append(new_event)
				update_note_pos(new_event)
				if floor(new_event.strum_time) < floor(Conductor.song_pos) - 10: # slight offset so the first note of a section can always get hit
					new_event.modulate = Color.GRAY
				new_event.position.y = floori(get_y_from_time(fmod(floor(evn.strum_time) - get_section_time(), Conductor.step_crochet * 48)))
	
func update_note_pos(note, dir:int = 0) -> void:
	note.scale = Vector2(0.26, 0.26)
	if note is not EventNote:
		note.lane = dir

	if !note.is_sustain:
		var x_diff:float = -1.25 if note is EventNote else float(dir)
		note.position.x = 120 + (GRID_SIZE * (x_diff))
		if note.note.offset.y == 0:
			note.note.offset.y += GRID_SIZE * 2
	
func check_note() -> void:
	var clicked_note:bool = false
	clicked_section = cur_section 
	if mouse_pos.y < grid_1.position.y: clicked_section -= 1
	if mouse_pos.y >= grid_2.position.y: clicked_section += 1
	print(clicked_section, ' | ', cur_section)
	
	for note in notes_loaded:
		if note.is_sustain: continue
		var note_pos = note.position.x - (note.width / 2.0)
		if mouse_pos.x - OFF >= note_pos and mouse_pos.x - OFF <= note_pos + GRID_SIZE \
		  and mouse_pos.y >= note.position.y and mouse_pos.y <= note.position.y + GRID_SIZE:
			clicked_note = true
			print('we over a note babe')
			if Input.is_key_pressed(KEY_CTRL):
				select_note(note)
			else:
				remove_note(note)
			break
		
	if !clicked_note and over_grid: # so you can click notes that are somehow off the grid, but not add more
		add_note()
		
func add_note() -> void:
	if !section_based: return
	var time:float = get_time_from_y(selected.position.y) + get_section_time()
	var dir_edit:int = 0 if JsonHandler.parse_type == 'psych_v1' else (-4 if SONG.notes[cur_section].mustHitSection else 0)
	var direct:int = fmod(abs(floor(mouse_pos.x / GRID_SIZE) - (5 + dir_edit)), 8) # no need to go above 7
	
	print('adding note ('+ str(direct) +' ['+ str(time) +'])')
	var note_sec = SONG.notes[cur_section].sectionNotes
	note_sec.append([time, direct, 0])
	note_sec.sort_custom(func(a, b): return a[0] < b[0])
	this_note = note_sec[(note_sec.find([time, direct, 0]))]
	regen_notes()
	
func select_note(note:BasicNote) -> void:
	if !section_based: return
	print('we trying to select a note hun')
	var id:int = 0
	for i in SONG.notes[clicked_section].sectionNotes:
		if int(i[0]) == int(note.strum_time) and i[1] == note.true_dir:
			this_note = SONG.notes[clicked_section].sectionNotes[id]
			print('Selected Note')
			return
		id += 1

func remove_note(note:BasicNote) -> void:
	if !section_based: return
	print('we trying to remove a note love')
	var le_notes:Array = SONG.notes[clicked_section].sectionNotes
	print(le_notes.size())
	for i in le_notes:
		if int(i[0]) == int(note.strum_time) and i[1] == note.true_dir:
			this_note = [] # clear() wouldnt always clear it ironically
			le_notes.remove_at(le_notes.find(i))
			print('Removed Note')
			
	regen_notes()

func update_text() -> void:
	$ChartUI/Info.text = \
		"Beat: "+ str(Conductor.cur_beat) +"\n"+ \
		"Step: "+ str(Conductor.cur_step) +"\n"+ \
		"Sect: "+ str(cur_section)      +"\n\n"+ \
		"Snap: "+ str(note_snap) +"th"

func _toggle_grid(toggled:bool) -> void:
	#Conductor.paused = true
	for i in [grid_0, grid_1, grid_2]:
		if i != null:
			for sqr in i.grid: sqr.visible = toggled
			for mrk in i.markers: mrk.visible = !toggled
	regen_notes()
	
func focus_changed(is_focused:bool) -> void:
	if is_focused and Conductor.paused:
		Conductor.paused = true

func get_y_from_time(strum_time:float) -> float:
	return remap(strum_time, 0, 16 * Conductor.step_crochet, grid_1.position.y, grid_1.position.y + grid_1.height)

func get_time_from_y(y_pos:float) -> float:
	return remap(y_pos, grid_1.position.y, grid_1.position.y + grid_1.height, 0, 16 * Conductor.step_crochet)
	
func get_section_time(this_sec:int = -1):
	if this_sec < 0: this_sec = cur_section
	var pos:float = 0
	var bpm:float = SONG.bpm
	for i in this_sec:
		var da_sec = SONG.notes[i] if section_based else {}
		if da_sec.has('changeBPM') and da_sec.changeBPM:
			bpm = max(da_sec.bpm, 1)
		var le_beat = da_sec.sectionBeats if da_sec.has('sectionBeats') else 4.0
		pos += le_beat * (1000.0 * 60.0 / bpm)
	return pos

class EventNote extends BasicNote:
	var ev_name:String = 'Nothing!'
	var ev_extra:String = ''
	var raw_data:EventData
	
	func _init(event:EventData):
		is_sustain = false # just in case
		label = Label.new()
		label.add_theme_font_override('font', ResourceLoader.load('res://assets/fonts/vcr.ttf'))
		label.add_theme_font_size_override('font_size', 15)
		label.add_theme_constant_override('outline_size', 5)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = Vector2(Game.screen[0] / 2.0, 48)
		add_child(label)
		label.scale *= 4
		
		label.position.x -= 2650 #+ (label.get_total_character_count() * 5)
		label.position.y -= 10

		note = Sprite2D.new()
		note.texture = ResourceLoader.load('res://assets/images/ui/event.png')
		add_child(note)
		if event != null:
			raw_data = event
			ev_name = event.event
			ev_extra = str(event.values)
			#ev_extra.substr(0, ev_extra.length() - 2)
		label.text = ev_name +'\n'+ ev_extra
	
	func _ready(): 
		spawned = true
		pass # just to overwrite the BasicNote's ready

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
			beat_mark.modulate = Color.RED if i > 0 else Color.AQUAMARINE
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
