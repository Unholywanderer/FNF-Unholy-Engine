class_name EventData; extends Resource;

var strum_time:float = 0.0
var event:String = ''
var values:Array[Variant] = []

# new event should be [strum_time, [eventname, value1, value2,...] and so on
# but since its psych theres only likely gonna be 2
func _init(new_event, type:String = 'psych'):
	if new_event != null:
		match type:
			'psych', 'legacy', 'normal':
				strum_time = new_event[0]
				event = new_event[1][0]
				for val in new_event[1]:
					if val == event: continue # das the event name dont need that....
					values.append(val)
			'v_slice':
				strum_time = new_event.t
				event = new_event.e
				if new_event.v is Dictionary:
					var temp_vals:Dictionary = {}
					for i in new_event.v.keys():
						temp_vals[i] = new_event.v[i]
					values.append(temp_vals)
				else:
					values.append(new_event.v)
			'codename':
				strum_time = new_event.time
				event = new_event.name
				values.append_array(new_event.params)
				#print([event, strum_time, values])
