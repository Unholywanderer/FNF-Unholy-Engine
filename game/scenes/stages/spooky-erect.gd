extends StageBase

var other_bf:Character
var other_spook:Character
var other_gf:Character

func _ready():
	default_zoom = 1.0
	gf_pos.y += 25

var lightning_beat:int = 0
var lighting_offset:int = 8

func post_ready():
	var light_alts = ['gf', 'spooky', 'bf']
	var le_fucks = [SONG.gfVersion, SONG.player2, SONG.player1]
	for i in light_alts.size():
		if JsonHandler.get_character(le_fucks[i].replace('-dark', '')):
			light_alts[i] = le_fucks[i].replace('-dark', '')
	
	other_gf = Character.new(gf_pos, light_alts[0])
	$CharGroup.add_child(other_gf)
	other_spook = Character.new(dad_pos, light_alts[1])
	$CharGroup.add_child(other_spook)
	other_bf = Character.new(bf_pos, light_alts[2], true)
	$CharGroup.add_child(other_bf)
	for i in [other_bf, other_gf, other_spook]: i.modulate.a = 0
	
func song_start():
	lightning_beat = 0
	
	other_gf.danced = gf.danced
	other_spook.danced = dad.danced

func beat_hit(beat):
	for i:Character in [other_bf, other_gf, other_spook]:
		if beat % i.dance_beat == 0 and !i.animation.begins_with('sing'):
			i.dance()
	if Game.rand_bool(10) and beat > lightning_beat + lighting_offset:
		strike()

func strike():
	lightning_beat = cur_beat
	lighting_offset = randi_range(8, 24)
	
	for i in [$BG, $Stairs, other_bf, other_gf, other_spook]:
		i.modulate.a = 1
	
	get_tree().create_timer(0.06).timeout.connect(func():
		for i in [$BG, $Stairs, other_bf, other_gf, other_spook]:
			i.modulate.a = 0
	)
	
	get_tree().create_timer(0.12).timeout.connect(func():
		for i in [$BG, $Stairs, other_bf, other_gf, other_spook]:
			i.modulate.a = 1
			create_tween().tween_property(i, 'modulate:a', 0, 1.5)
	)
	
	Audio.play_sound('thunder_'+ str(randi_range(1, 2)))
	for i in [boyfriend, gf, other_bf, other_gf]:
		if i.has_anim('scared'):
			i.play_anim('scared', true)
	
func good_note_hit(note): other_bf.sing(note.dir, '', !note.is_sustain)
func opponent_note_hit(note): other_spook.sing(note.dir, '', !note.is_sustain)
