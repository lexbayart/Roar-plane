extends CharacterBody2D
## Plane — the player-controlled flying character
## Gravity pulls down; flap() counteracts it when R sound is detected.

signal collided()

const GRAVITY := 980.0
const FLAP_VELOCITY := -400.0

var is_dead := false
var is_active := false  # Физика не работает до старта игры

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
	
	# Создаем визуальный выхлоп мотора
	var exhaust = CPUParticles2D.new()
	exhaust.name = "EngineExhaust"
	exhaust.emitting = false
	exhaust.one_shot = true
	exhaust.amount = 10
	exhaust.lifetime = 0.5
	exhaust.explosiveness = 0.8
	exhaust.direction = Vector2(-1, 0)
	exhaust.spread = 30.0
	exhaust.gravity = Vector2(0, -50)
	exhaust.initial_velocity_min = 50.0
	exhaust.initial_velocity_max = 100.0
	exhaust.scale_amount_min = 2.0
	exhaust.scale_amount_max = 8.0
	exhaust.color = Color(0.8, 0.8, 0.8, 0.6)
	exhaust.position = Vector2(-20, 5)
	add_child(exhaust)


func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return
	
	# Apply gravity with smooth Apex Hovering & slower fall for children
	var current_gravity = GRAVITY
	if velocity.y > 0:
		current_gravity = GRAVITY * 0.55  # 45% slower fall for gentle, highly responsive descent
	if abs(velocity.y) < 120.0:
		current_gravity = GRAVITY * 0.25  # Apex Hovering: only 25% gravity near the peak!
		
	velocity.y += current_gravity * delta
	
	# Clamp fall speed
	velocity.y = minf(velocity.y, 600.0)
	
	# Apply movement
	var collision = move_and_collide(velocity * delta)
	
	# Clamp to ground perfectly to avoid jitter
	var ground_y = get_viewport_rect().size.y - 58
	var on_ground = false
	if position.y >= ground_y:
		position.y = ground_y
		velocity.y = 0.0
		on_ground = true

	if collision and not on_ground:
		if collision.get_normal().y < -0.5:
			pass # Handle any other flat surfaces similarly
		else:
			collided.emit()
	
	# Rotate plane based on velocity (stay flat if on ground)
	if on_ground:
		rotation = lerpf(rotation, 0.0, 0.2)
	else:
		rotation = lerpf(rotation, deg_to_rad(clampf(velocity.y * 0.1, -30, 90)), 0.15)
	
	# Flap animation
	_anim_timer += delta
	if _anim_timer >= ANIM_SPEED:
		_anim_timer = 0.0
		_frame_idx = (_frame_idx + 1) % _sprites.size()
		$Sprite2D.texture = _sprites[_frame_idx]


func flap(intensity: float = 1.0) -> void:
	if is_dead:
		return
	velocity.y = FLAP_VELOCITY * (0.6 + 0.4 * intensity)
	rotation = deg_to_rad(-25.0)
	_frame_idx = 0
	$Sprite2D.texture = _sprites[0]
	
	if has_node("EngineExhaust"):
		var exhaust = get_node("EngineExhaust")
		exhaust.restart()
		exhaust.emitting = true


func die() -> void:
	is_dead = true
	velocity.y = -200.0  # Small bounce on death


func reset() -> void:
	is_dead = false
	is_active = false
	# Ставим птичку на землю (земля на y=900, поверхность на 890, птичка 24px высотой)
	position = Vector2(150, get_viewport_rect().size.y - 58)
	velocity = Vector2.ZERO
	rotation = 0.0
	$Sprite2D.texture = _sprites[0]
	_frame_idx = 0