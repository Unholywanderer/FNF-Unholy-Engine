extends Node2D

const EDITORS = [
	'Charting Scene', 'Character Offsetter', 'Week Maker', 'Note Skin Editor', 'XML Converter', 'TXT Converter'
]
const PATHS = [
	'debug/charting_scene', 'debug/character_offsetter', null, null, 'tools/XML Converter', 'tools/TXT Converter'
]
var items:Array[Alphabet] = []
var cur_item:int = 0

func _ready() -> void:
	for i in EDITORS.size():
		var new_item = Alphabet.new(EDITORS[i])
		new_item.is_menu = true
		new_item.target_y = i
		add_child(new_item)
		items.append(new_item)
	update_scroll()

func _input(event:InputEvent) -> void:
	update_scroll(Input.get_axis("menu_up", "menu_down"))
	
	if Input.is_action_just_pressed('back'):
		queue_free()
		Game.scene.in_time = 0
		get_tree().paused = false
	if Input.is_action_just_pressed("accept"):
		var le_scene = PATHS[cur_item]
		if le_scene == null: return Alert.make_alert('Whoops no scene', Alert.ERROR)
		if le_scene.begins_with('tools'): le_scene = '../'+ le_scene
		Game.switch_scene(le_scene)

func update_scroll(amount:int = 0) -> void:
	if amount != 0: Audio.play_sound('scrollMenu')
	cur_item = wrap(cur_item + amount, 0, items.size())
	
	for i in items.size():
		var it = items[i]
		it.modulate.a = 0.6 if i != cur_item else 1.0
		it.target_y = i - cur_item
