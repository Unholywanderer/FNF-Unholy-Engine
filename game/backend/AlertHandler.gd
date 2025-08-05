extends Node

const ALERT = preload('res://game/objects/ui/alert_window.tscn')
enum {ERROR, WARN, CHECK}

var all_alerts:Array = []
var alert_count:int:
	get: return all_alerts.size()

func make_alert(text:String = '', type:int = CHECK) -> AlertWindow:
	#Util.remove_all([all_alerts], self)
	var new_alert = ALERT.instantiate()
	var type_str:String = 'ERROR'
	match type:
		WARN: type_str = 'WARN'
		CHECK: type_str = 'CHECK'
	new_alert.ALERT_TYPE = type_str
	new_alert.id = alert_count + 1
	add_child(new_alert)
	new_alert.text = 'N/A' if text.is_empty() else text
	all_alerts.append(new_alert)
	return new_alert
