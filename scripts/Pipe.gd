extends Area2D
class_name Pipe
## Pipe — single pipe pair (top and bottom)
## Moves left across the screen. Emits scored when plane passes through.

signal scored
signal hit

const SCROLL_SPEED := 120.0  # Установил ту же скорость, что и земля (было -100)

var passed := false

var star_sprite: Sprite2D
var star_collected := false
var _plane_node: Node2D
var _main_node: Node2D

func _ready() -> void:
	# Spawns a glowing golden star in the gap center (0, 0)
	star_sprite = Sprite2D.new()
	star_sprite.texture = load("res://assets/star.png")
	star_sprite.scale = Vector2(0.0625, 0.0625) # Scale to ~64x64
	star_sprite.position = Vector2(0, 0)
	add_child(star_sprite)
	
	# Cache node paths safely
	var root = get_parent()
	if root:
		_main_node = root.get_parent()
		if _main_node:
			_plane_node = _main_node.get_node_or_null("Plane")

func set_gap(gap: float) -> void:
	var shift = (gap - 200.0) / 2.0
	
	# Shift lower elements down
	if has_node("Lower"):
		$Lower.position.y = shift
	if has_node("CollisionShape2D"):
		$CollisionShape2D.position.y = 118.0 + shift
	if has_node("CollisionShape2D2"):
		$CollisionShape2D2.position.y = 398.0 + shift
	
	# Shift upper elements up
	if has_node("Upper"):
		$Upper.position.y = -shift
	if has_node("CollisionShape2D3"):
		$CollisionShape2D3.position.y = -118.0 - shift
	if has_node("CollisionShape2D4"):
		$CollisionShape2D4.position.y = -398.0 - shift
	
	# Resize score area collision to match new gap height
	if has_node("ScoreArea/CollisionShape2D"):
		var shape = $ScoreArea/CollisionShape2D.shape as RectangleShape2D
		if shape:
			shape.size.y = gap

func _process(delta: float) -> void:
	position.x -= SCROLL_SPEED * delta
	
	# Star collection detection (approx 65px radius)
	if not star_collected and is_instance_valid(_plane_node) and _plane_node.is_active:
		var dist = global_position.distance_to(_plane_node.global_position)
		if dist < 65.0:
			_collect_star()
	
	# Remove when off-screen
	if position.x < -200:
		queue_free()


func _collect_star() -> void:
	star_collected = true
	GameState.add_point(5) # Star awards 5 points!
	
	# Popping floating feedback "+5!"
	if is_instance_valid(_main_node) and _main_node.has_method("spawn_floating_text"):
		_main_node.spawn_floating_text("+5")
		
	# Gold popping star tween scale and fade
	var tween = create_tween().set_parallel(true)
	tween.tween_property(star_sprite, "scale", Vector2(0.12, 0.12), 0.3)
	tween.tween_property(star_sprite, "modulate:a", 0.0, 0.3)
	
	var seq = create_tween()
	seq.tween_interval(0.3)
	seq.tween_callback(star_sprite.queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Plane":
		hit.emit()

func _on_score_area_body_entered(body: Node2D) -> void:
	if body.name == "Plane" and not passed:
		passed = true
		scored.emit()