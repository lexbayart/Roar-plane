extends CharacterBody2D
## Plane — the player-controlled flying character
## Gravity pulls down; flap() counteracts it when R sound is detected.

signal collided()

const GRAVITY := 980.0
const FLAP_VELOCITY := -250.0

var is_dead := false

# Animation frames
@onready var _sprites: Array = [
	preload("res://assets/bird1.png"),
	preload("res://assets/bird2.png"),
	preload("res://assets/bird3.png"),
]
var _frame_idx := 0
var _anim_timer := 0.0
const ANIM_SPEED := 0.15


func _ready() -> void:
	$Sprite2D.texture = _sprites[0]


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply gravity
	velocity.y += GRAVITY * delta
	
	# Clamp fall speed
	velocity.y = minf(velocity.y, 600.0)
	
	# Apply movement
	var collision = move_and_collide(velocity * delta)
	if collision:
		collided.emit()
	
	# Rotate plane based on velocity
	rotation = lerpf(rotation, deg_to_rad(clampf(velocity.y * 0.1, -30, 90)), 0.15)
	
	# Flap animation
	_anim_timer += delta
	if _anim_timer >= ANIM_SPEED:
		_anim_timer = 0.0
		_frame_idx = (_frame_idx + 1) % _sprites.size()
		$Sprite2D.texture = _sprites[_frame_idx]


func flap() -> void:
	if is_dead:
		return
	velocity.y = FLAP_VELOCITY
	rotation = deg_to_rad(-25.0)
	_frame_idx = 0
	$Sprite2D.texture = _sprites[0]


func die() -> void:
	is_dead = true
	velocity.y = -200.0  # Small bounce on death


func reset() -> void:
	is_dead = false
	position = Vector2(150, get_viewport_rect().size.y / 2)
	velocity = Vector2.ZERO
	rotation = 0.0
	$Sprite2D.texture = _sprites[0]
	_frame_idx = 0