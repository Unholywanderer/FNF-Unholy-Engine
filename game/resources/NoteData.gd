class_name NoteData; extends Resource;

var strum_time:float = 0.0
var must_press:bool = false
var dir:int = 0

var speed:float = 1.0
var type:String = ""

var length:float = 0.0

func _init(data:Array = []):
	if data.is_empty(): data = [0, 0, null, 0.0, true, ""]
	strum_time = floor(data[0])
	dir = int(data[1]) % 4
	if data[3] is not float: data[3] = 0.0
	length = data[3]
	must_press = data[4]
	type = data[5]
