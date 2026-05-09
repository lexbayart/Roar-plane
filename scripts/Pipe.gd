extends Area2D
class_name Pipe
## Pipe — single pipe pair (top and bottom)
## Moves left across the screen. Emits scored when plane passes through.

signal scored

const SCROLL_SPEED := -100.0

@onready var top_pipe := $TopPipe
@onready var bottom_pipe := $BottomPipe
@onready var score_zone := $ScoreZone

var passed := false


func _ready() -> void:
	# Random gap position (adjustable spawn Y)
	position.y = randf_range(-100, 100)
	
	# Wait a frame then enable collisions
	await get_tree().process_frame


func _process(delta: float) -> void:
	position.x += SCROLL_SPEED * delta
	
	# Score zone check
	if not passed and score_zone and score_zone.global_position.x < 0:
		passed = true
		scored.emit()
	
	# Remove when off-screen
	if position.x < -200:
		queue_free()


static func create_pair(gap_y: float, gap_size: float) -> Node2D:
	var pair = Node2D.new()
	
	# Top pipe
	var top = Area2D.new()
	top.name = "TopPipe"
	var top_sprite = Sprite2D.new()
	top_sprite.texture = preload("res://assets/pipe.png")
	top_sprite.scale = Vector2(1, -1)  # Flip vertically
	var top_shape = CollisionShape2D.new()
	top_shape.shape = RectangleShape2D.new()
	top_shape.shape.size = Vector2(52, 320)
	top.add_child(top_sprite)
	top.add_child(top_shape)
	
	# Bottom pipe
	var bottom = Area2D.new()
	bottom.name = "BottomPipe"
	var bottom_sprite = Sprite2D.new()
	bottom_sprite.texture = preload("res://assets/pipe.png")
	var bottom_shape = CollisionShape2D.new()
	bottom_shape.shape = RectangleShape2D.new()
	bottom_shape.shape.size = Vector2(52, 320)
	bottom.add_child(bottom_sprite)
	bottom.add_child(bottom_shape)
	
	# Score zone (invisible area between pipes)
	var zone = Area2D.new()
	zone.name = "ScoreZone"
	var zone_shape = CollisionShape2D.new()
	zone_shape.shape = RectangleShape2D.new()
	zone_shape.shape.size = Vector2(2, gap_size)
	zone.add_child(zone_shape)
	
	pair.add_child(top)
	pair.add_child(bottom)
	pair.add_child(zone)
	
	# Position: gap is centered at gap_y
	top.position.y = gap_y - gap_size / 2 - 160
	bottom.position.y = gap_y + gap_size / 2 + 160
	
	return pair