extends Node2D

const EDITORS = [ # thing name, path to scene
	['Charting Scene', 'debug/charting_scene'],
	['Character Offsetter', 'debug/character_offsetter'],
	['XML Converter', 'tools/Sparrow Converter'],
	['Week Maker', ''],
	['Note Skin Editor', ''],
	#['TXT Converter', 'tools/TXT Converter'], # actually i dont know if this is useful currently
]

var items:Array[Alphabet] = []
var cur_item:int = 0

func _ready() -> void:
	for i in EDITORS.size():
		var new_item = Alphabet.new(EDITORS[i][0])
		new_item.is_menu = true
		new_item.target_y = i
		add_child(new_item)
		items.append(new_item)
	update_scroll()

var changing:bool = false
func _input(event:InputEvent) -> void:
	if changing: return
	update_scroll(int(Input.get_axis("menu_up", "menu_down")))

	if event.is_action_pressed('back'):
		queue_free()
		Game.scene.in_time = 0
		get_tree().paused = false
	if event.is_action_pressed("accept"):
		var le_scene:String = EDITORS[cur_item][1]
		if le_scene.is_empty(): return Alert.make_alert('Whoops no scene', Alert.ERROR)
		if le_scene.begins_with('tools'): le_scene = '../'+ le_scene
		changing = true
		Game.switch_scene(le_scene)

func update_scroll(amount:int = 0) -> void:
	if amount != 0: Audio.play_sound('scrollMenu')
	cur_item = wrap(cur_item + amount, 0, items.size())

	for i in items.size():
		var it = items[i]
		it.modulate.a = 0.6 if i != cur_item else 1.0
		it.target_y = i - cur_item
