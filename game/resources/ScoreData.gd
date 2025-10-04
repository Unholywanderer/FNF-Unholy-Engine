class_name ScoreData; extends Resource;

var is_valid:bool = true
var is_highscore:bool = false

var song_name:String = 'Test' # will be the week name on story mode
var difficulty:String = 'hard'
var rank:String:
	get: return get_rank()

var total_notes:int = 0
var max_combo:int = 0
var score:int = 0
var accuracy:float = 1

var hits:Dictionary = { # technically epics and sicks will be added together so they dont matter sperately
	'epic': 0, 'sick': 0, 'good': 0, 'bad': 0, 'shit': 0, 'miss': 0
}

func add_hits(dic:Dictionary) -> void:
	for i in hits.keys(): hits[i] += dic.get(i, 0)

func get_hit_percent() -> float:
	if total_notes <= 0: return 0.0
	return ((hits.epic + hits.sick + hits.good) / float(total_notes)) * 100.0

func get_rank() -> String:
	var temp:int = floori(get_hit_percent())
	#var is_gold = (hits.epic + hits.sick) == total_notes
	#if (hits.epic + hits.sick) == total_notes: return 'perfect_gold' # only hit epics and sicks
	if temp == 100: return 'perfect'
	if temp >= 90: return 'excellent'
	if temp >= 80: return 'great'
	if temp >= 60: return 'good'
	return 'loss'
