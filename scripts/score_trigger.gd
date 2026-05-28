extends Area2D
class_name ScoreTrigger
## ScoreTrigger — invisible Area2D positioned between pipe pairs.
## Detects when the plane (CharacterBody2D) passes through and
## increments the global score via GameState singleton.

@export var pipe_ref: Node2D  # Reference to parent pipe pair

var _scored := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _scored:
		return
	if not (body is CharacterBody2D):
		return
	_scored = true
	if GameState:
		GameState.add_point()