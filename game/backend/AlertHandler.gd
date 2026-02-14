extends Node

const ALERT = preload('res://game/objects/ui/alert_window.tscn')
enum {ERROR, WARN, CHECK}

var all_alerts:Dictionary[String, AlertWindow] = {}

var alert_count:int:
	get: return all_alerts.size()

func make_alert(id:String = '', type:int = CHECK) -> AlertWindow:
	if all_alerts.has(id):
		var old_alert = all_alerts[id]
		if !old_alert or !is_instance_valid(old_alert):
			all_alerts.erase(id)
		else:
			old_alert.refresh()
			return old_alert

	var new_alert:AlertWindow = ALERT.instantiate()
	var type_str:String = 'ERROR'
	match type:
		WARN: type_str = 'WARN'
		CHECK: type_str = 'CHECK'

	new_alert.ALERT_TYPE = type_str
	new_alert.id = alert_count
	DebugInfo.add_child(new_alert)
	new_alert.text = 'N/A' if id.is_empty() else id
	new_alert.name = id

	print('added alert '+ id)

	all_alerts[id] = new_alert
	print(all_alerts)
	return new_alert

func remove(id:String) -> void:
	for i in all_alerts.keys():
		if i != id and is_instance_valid(i): continue
		all_alerts.erase(i)
