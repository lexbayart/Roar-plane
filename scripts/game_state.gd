extends Node

signal score_changed(new_score: int)

@export var score: int = 0
@export var high_score: int = 0
var lang: String = "ru"

var current_player_name: String = ""
var leaderboard: Array = []

const LEADERBOARD_PATH = "user://leaderboard.json"

func _ready() -> void:
	load_leaderboard()

func add_point(amount: int = 1) -> void:
	score += amount
	if score > high_score:
		high_score = score
	score_changed.emit(score)

func reset() -> void:
	score = 0
	score_changed.emit(score)

func load_leaderboard() -> void:
	leaderboard.clear()
	if not FileAccess.file_exists(LEADERBOARD_PATH):
		return
	
	var file = FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var json = JSON.new()
		var err = json.parse(json_str)
		if err == OK and typeof(json.data) == TYPE_ARRAY:
			leaderboard = json.data
	
	# Load absolute high score as the #1 spot
	if not leaderboard.is_empty():
		high_score = int(leaderboard[0].get("score", 0))

func save_score_to_leaderboard() -> void:
	var name_to_save = current_player_name.strip_edges()
	if name_to_save.is_empty():
		name_to_save = "Ребёнок" if lang == "ru" else "Child"
	
	var time_dict = Time.get_datetime_dict_from_system()
	var date_str = "%02d.%02d.%04d" % [time_dict.day, time_dict.month, time_dict.year]
	
	var entry = {
		"name": name_to_save,
		"score": score,
		"date": date_str
	}
	
	leaderboard.append(entry)
	
	# Sort descending by score
	leaderboard.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	
	# Keep Top 5
	if leaderboard.size() > 5:
		leaderboard = leaderboard.slice(0, 5)
		
	# Save to persistent file
	var file = FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard))
		
	if not leaderboard.is_empty():
		high_score = int(leaderboard[0].get("score", 0))