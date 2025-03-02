extends Node

const ALERT = preload('res://game/objects/ui/alert_window.tscn')
enum {ERROR, WARN, CHECK}

var all_alerts:Array = []
var alert_count:int = 0

func make_alert(text:String = '', type:int = CHECK) -> void:
	Game.remove_all([all_alerts], self)
	var new_alert = load('res://game/objects/alert_window.tscn').instantiate()
	var type_str = 'ERROR'
	match type:
		WARN: type_str = 'WARN'
		CHECK: type_str = 'CHECK'
	new_alert.ALERT_TYPE = type_str
	add_child(new_alert)
	new_alert.text = 'N/A' if text.length() == 0 else text
	all_alerts.append(new_alert)
