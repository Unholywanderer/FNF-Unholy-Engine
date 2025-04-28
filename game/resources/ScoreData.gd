class_name ScoreData; extends Resource;

var song_name:String = '' # hmm maybe make this the week name or something if you get to it on story mode
var difficulty:String = ''
var rank:String:
	get: return get_rank()

var total_notes:int = 0
var max_combo:int = 0
var score:int = 0

var hits:Dictionary = { # technically epics and sicks will be added together so they dont matter sperately
	'epic': 0, 'sick': 0, 'good': 0, 'bad': 0, 'shit': 0, 'miss': 0
}

func is_highscore(songs:Array, is_week:bool = false) -> bool:
	return true

func get_rank() -> String:
	var temp = roundi((hits.epic + hits.sick + hits.good) / float(total_notes) * 100.0)
	#var is_gold = (hits.epic + hits.sick) == total_notes
	#if (hits.epic + hits.sick) == total_notes: return 'perfect_gold' # only hit epics and sicks
	if temp == 100: return 'perfect'
	if temp >= 90: return 'excellent'
	if temp >= 80: return 'great'
	if temp >= 60: return 'good'
	return 'loss'
