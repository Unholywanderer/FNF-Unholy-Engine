extends Node

const ALERT = preload('res://game/objects/ui/alert_window.tscn')
enum {ERROR, WARN, CHECK}

var all_alerts:Dictionary = {}

var alert_count:int:
	get: return all_alerts.size()

func make_alert(id:String = '', type:int = CHECK) -> AlertWindow:
	print(alert_count)
	if all_alerts.has(id):
		var old_alert = all_alerts[id]
		old_alert.life_time = 4.0
		return old_alert

	var new_alert = ALERT.instantiate()
	var type_str:String = 'ERROR'
	match type:
		WARN: type_str = 'WARN'
		CHECK: type_str = 'CHECK'
	new_alert.ALERT_TYPE = type_str
	new_alert.id = alert_count + 1
	add_child(new_alert)
	new_alert.text = 'N/A' if id.is_empty() else id
	new_alert.name = new_alert.text

	all_alerts[id] = new_alert
	return new_alert
