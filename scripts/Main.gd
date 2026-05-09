extends Node2D
## Main — root game scene controller
## Connects speech recognition to plane mechanics.

@onready var plane: CharacterBody2D = $Plane
@onready var pipes: Node2D = $Pipes
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var restart_button: TextureButton = $UI/RestartButton
@onready var pipe_spawn_timer: Timer = $PipeSpawnTimer
@onready var game_over_timer: Timer = $GameOverTimer
@onready var start_label: Label = $UI/StartLabel

var score := 0
var game_over := false
var game_started := false

const PIPE_GAP := 180.0
const PIPE_MIN_Y := 100.0
const PIPE_MAX_Y := 700.0


func _ready() -> void:
	# Connect speech signals
	var speech = SpeechManager
	speech.connect("R_sound_detected", _on_R_sound_detected)
	speech.connect("speech_error", _on_speech_error)
	
	# Connect plane collision
	plane.connect("collided", _on_plane_collided)
	
	# Connect pipe timer
	pipe_spawn_timer.connect("timeout", _on_pipe_spawn)
	
	# Connect restart button
	restart_button.connect("pressed", _on_restart_pressed)
	
	# Start fresh
	_reset_game()
	print("Roar-plane ready! Say an R word to start.")
	start_label.text = "Say an R word to start!\n(red, run, car, rain...)"


func _process(_delta: float) -> void:
	if not game_started:
		return
	
	# Check if plane fell off screen
	if plane.position.y > get_viewport_rect().size.y + 100:
		_trigger_game_over()


func _on_R_sound_detected(words: Array) -> void:
	if game_over:
		_restart_game()
		return
	
	if not game_started:
		_start_game()
	
	plane.flap()
	print("R-word detected: ", words)


func _on_speech_error(message: String) -> void:
	print("Speech error: ", message)
	# Show error on start label if game hasn't started
	if not game_started:
		start_label.text = "Microphone error!\n" + message


func _on_pipe_spawn() -> void:
	if game_over:
		return
	
	var screen_size = get_viewport_rect().size
	var center_y = randf_range(
		max(PIPE_MIN_Y + PIPE_GAP / 2, PIPE_GAP / 2 * 1.5),
		min(PIPE_MAX_Y - PIPE_GAP / 2, screen_size.y - PIPE_GAP / 2 * 1.5)
	)
	
	# Create pipe pair using static factory
	var pipe = Pipe.create_pair(center_y, PIPE_GAP)
	pipes.add_child(pipe)
	
	# Add collision detection for the plane
	for child in pipe.get_children():
		if child is Area2D and child.name != "ScoreZone":
			child.connect("body_entered", _on_plane_pipe_collision.bind(pipe))
		elif child.name == "ScoreZone":
			child.body_entered.connect(_on_score_zone_entered.bind(pipe))


func _on_plane_collided() -> void:
	_trigger_game_over()


func _on_plane_pipe_collision(_body: Node, _pipe: Node2D) -> void:
	if game_over:
		return
	_trigger_game_over()


func _on_score_zone_entered(_body: Node, _pipe: Node2D) -> void:
	if game_over or _pipe.passed:
		return
	_pipe.passed = true
	score += 1
	_update_score_display()


func _on_restart_pressed() -> void:
	_restart_game()


func _start_game() -> void:
	game_started = true
	start_label.visible = false
	SpeechManager.start_listening()
	pipe_spawn_timer.start()


func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	
	plane.die()
	pipe_spawn_timer.stop()
	
	# Stop pipe movement
	for pipe_child in pipes.get_children():
		pipe_child.set_process(false)
	for pipe_child in pipes.get_children():
		for c in pipe_child.get_children():
			if c is Area2D:
				c.set_deferred("monitoring", false)
	
	# Show game over UI after brief delay
	game_over_timer.start()


func _on_game_over_timer_timeout() -> void:
	game_over_label.visible = true
	restart_button.visible = true
	SpeechManager.stop_listening()


func _restart_game() -> void:
	# Clear pipes
	for pipe_child in pipes.get_children():
		pipe_child.queue_free()
	
	# Reset UI
	game_over_label.visible = false
	restart_button.visible = false
	start_label.visible = false
	
	# Reset plane
	plane.reset()
	
	# Reset state
	game_over = false
	game_started = false
	score = 0
	_update_score_display()
	
	# Show start prompt again
	start_label.text = "Say an R word to start!\n(red, run, car, rain...)"
	start_label.visible = true


func _reset_game() -> void:
	score = 0
	_update_score_display()
	game_over_label.visible = false
	restart_button.visible = false
	game_over = false
	game_started = false
	plane.reset()
	start_label.visible = true
	
	# Clear pipes
	for pipe_child in pipes.get_children():
		pipe_child.queue_free()


func _update_score_display() -> void:
	if score_label:
		score_label.text = "Score: " + str(score)