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

var game_over := false
var game_started := false

const GROUND_SCROLL_SPEED := 120.0  # Скорость прокрутки земли (иллюзия движения)
@onready var _ground_sprite: Sprite2D = $Ground/Sprite2D
var _ground_sprite2: Sprite2D

@export var pipe_scene: PackedScene = preload("res://scenes/Pipe.tscn")

const PIPE_GAP := 400.0
const PIPE_MIN_Y := 100.0
const PIPE_MAX_Y := 700.0

var texts = {
	"ru": {
		"start": "Скажи Р-Р-Р чтобы взлететь!",
		"score": "Очки: ",
		"high_score": "Рекорд: ",
		"game_over": "Упс! Упали!",
		"mic_error": "Ошибка микрофона!"
	},
	"en": {
		"start": "Say R-R-R to fly!",
		"score": "Score: ",
		"high_score": "Best: ",
		"game_over": "Oops! Crashed!",
		"mic_error": "Mic Error!"
	}
}

var lang_btn: Button
var mic_indicator: Label
var mic_debug_label: RichTextLabel
var syllable_cards: Dictionary = {}
var debug_hud: PanelContainer
var volume_bar: ProgressBar
var hud_toggle_btn: Button


func _ready() -> void:
	_ground_sprite2 = _ground_sprite.duplicate()
	_ground_sprite2.position.x = 1728.0
	$Ground.add_child(_ground_sprite2)
	
	# Connect speech signals
	var speech = SpeechManager
	speech.connect("R_sound_detected", _on_R_sound_detected)
	speech.connect("speech_error", _on_speech_error)
	speech.connect("speech_result", _on_speech_result)
	
	# Connect plane collision
	plane.connect("collided", _on_plane_collided)
	
	# Connect timers
	pipe_spawn_timer.connect("timeout", _on_pipe_spawn)
	pipe_spawn_timer.wait_time = 4.0
	game_over_timer.connect("timeout", _on_game_over_timer_timeout)
	
	# Connect restart button
	restart_button.connect("pressed", _on_restart_pressed)
	
	# Растягиваем фон на весь viewport
	var bg_sprite: Sprite2D = $Background/Sprite2D
	var vp_size = get_viewport_rect().size
	var tex_size = bg_sprite.texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		bg_sprite.scale = Vector2(vp_size.x / tex_size.x, vp_size.y / tex_size.y)
	
	# Setup UI elements dynamically
	lang_btn = Button.new()
	lang_btn.text = "RU / EN"
	lang_btn.position = Vector2(20, 20)
	lang_btn.pressed.connect(_toggle_lang)
	$UI.add_child(lang_btn)
	
	mic_indicator = Label.new()
	mic_indicator.text = "🎤"
	mic_indicator.add_theme_font_size_override("font_size", 32)
	mic_indicator.position = Vector2(get_viewport_rect().size.x - 60, 20)
	$UI.add_child(mic_indicator)
	
	# 1. Create debug panel container (glassmorphism look)
	debug_hud = PanelContainer.new()
	debug_hud.size = Vector2(800, 140)
	debug_hud.position = Vector2((get_viewport_rect().size.x - 800) / 2, 70)
	
	var hud_style = StyleBoxFlat.new()
	hud_style.bg_color = Color(0.05, 0.05, 0.08, 0.6) # Dark glassmorphic background
	hud_style.corner_radius_top_left = 20
	hud_style.corner_radius_top_right = 20
	hud_style.corner_radius_bottom_left = 20
	hud_style.corner_radius_bottom_right = 20
	hud_style.border_width_left = 2
	hud_style.border_width_right = 2
	hud_style.border_width_top = 2
	hud_style.border_width_bottom = 2
	hud_style.border_color = Color(0.3, 0.3, 0.4, 0.2)
	debug_hud.add_theme_stylebox_override("panel", hud_style)
	$UI.add_child(debug_hud)
	
	var debug_vbox = VBoxContainer.new()
	debug_vbox.add_theme_constant_override("separation", 10)
	debug_hud.add_child(debug_vbox)
	
	# Add mic debug label into vbox
	mic_debug_label = RichTextLabel.new()
	mic_debug_label.bbcode_enabled = true
	mic_debug_label.text = "[center][color=#aaaaaa]Голос: [Ожидание][/color][/center]"
	mic_debug_label.add_theme_font_size_override("normal_font_size", 34)
	mic_debug_label.custom_minimum_size = Vector2(760, 50)
	debug_vbox.add_child(mic_debug_label)
	
	# Add real-time VU Meter (loudness bar)
	var bar_container = MarginContainer.new()
	bar_container.add_theme_constant_override("margin_left", 40)
	bar_container.add_theme_constant_override("margin_right", 40)
	bar_container.add_theme_constant_override("margin_bottom", 10)
	debug_vbox.add_child(bar_container)
	
	volume_bar = ProgressBar.new()
	volume_bar.show_percentage = false
	volume_bar.custom_minimum_size = Vector2(0, 16)
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	bar_bg.corner_radius_top_left = 8
	bar_bg.corner_radius_top_right = 8
	bar_bg.corner_radius_bottom_left = 8
	bar_bg.corner_radius_bottom_right = 8
	volume_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.9, 0.3, 0.9) # Glowing neon green
	bar_fill.corner_radius_top_left = 8
	bar_fill.corner_radius_top_right = 8
	bar_fill.corner_radius_bottom_left = 8
	bar_fill.corner_radius_bottom_right = 8
	volume_bar.add_theme_stylebox_override("fill", bar_fill)
	
	bar_container.add_child(volume_bar)
	
	# Connect volume signal
	SpeechManager.connect("mic_volume_updated", _on_mic_volume_updated)
	
	# 2. Add dynamic toggle button for HUD
	hud_toggle_btn = Button.new()
	hud_toggle_btn.text = "HUD: ВКЛ"
	hud_toggle_btn.position = Vector2(get_viewport_rect().size.x - 220, 20)
	hud_toggle_btn.custom_minimum_size = Vector2(140, 40)
	hud_toggle_btn.pressed.connect(_on_hud_toggle_pressed)
	
	# Style toggle button
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.2, 0.25, 0.6)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	hud_toggle_btn.add_theme_stylebox_override("normal", btn_style)
	
	$UI.add_child(hud_toggle_btn)
	
	# Create beautiful container for syllables
	var syllables_container = HBoxContainer.new()
	syllables_container.alignment = BoxContainer.ALIGNMENT_CENTER
	syllables_container.position = Vector2((get_viewport_rect().size.x - 600) / 2, 170)
	syllables_container.size = Vector2(600, 100)
	syllables_container.add_theme_constant_override("separation", 30)
	$UI.add_child(syllables_container)
	
	var syllables = ["ро", "ри", "ру"]
	for s in syllables:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(120, 80)
		
		# Add a beautiful stylebox with rounded corners (glassmorphism/sleek look)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.7) # Dark semi-transparent
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.4, 0.4, 0.5, 0.3)
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		panel.add_theme_stylebox_override("panel", style)
		
		var label = Label.new()
		label.text = s.to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 38)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.4)) # Default faded white
		panel.add_child(label)
		
		syllables_container.add_child(panel)
		syllable_cards[s] = {
			"panel": panel,
			"label": label,
			"style": style
		}
	
	# Start fresh
	GameState.score_changed.connect(_update_score_display)
	_reset_game()
	print("Roar-plane ready!")
	_update_texts()


func _process(delta: float) -> void:
	if SpeechManager._is_listening:
		mic_indicator.modulate = Color(1, 0, 0, 1) if Engine.get_frames_drawn() % 30 < 15 else Color(1, 0.5, 0.5, 1)
	else:
		mic_indicator.modulate = Color(0.5, 0.5, 0.5, 1)

	# ТЕСТ: Пробел как замена голосу (для отладки)
	if Input.is_action_just_pressed("ui_accept"):
		_on_R_sound_detected([1.0])

	# Земля всегда прокручивается (взлётная полоса)
	_ground_sprite.position.x -= GROUND_SCROLL_SPEED * delta
	_ground_sprite2.position.x -= GROUND_SCROLL_SPEED * delta
	
	if _ground_sprite.position.x <= -1728.0:
		_ground_sprite.position.x += 3456.0
	if _ground_sprite2.position.x <= -1728.0:
		_ground_sprite2.position.x += 3456.0
	
	if not game_started:
		return
	
	# Check if plane fell off screen
	if plane.position.y > get_viewport_rect().size.y + 100:
		_trigger_game_over()


func _on_R_sound_detected(data: Array) -> void:
	if game_over:
		_restart_game()
		return
	
	if not game_started:
		_start_game()
	
	var intensity: float = data[0] if data.size() > 0 else 1.0
	plane.flap(intensity)
	print("R-sound detected! Intensity: ", intensity)


func _on_speech_error(message: String) -> void:
	print("Speech error: ", message)
	if not game_started:
		start_label.text = texts[GameState.lang]["mic_error"] + "\n" + message
	if mic_debug_label:
		mic_debug_label.text = "[center][color=#ff3333]Ошибка: " + message + "[/color][/center]"


func _on_speech_result(text: String) -> void:
	print("Speech recognized: ", text)
	if mic_debug_label:
		if text == "" or text == "тишина":
			mic_debug_label.text = "[center][color=#aaaaaa]Голос: -[/color][/center]"
			return
		
		var s = text.to_lower()
		var all_syllables = ["ро", "ри", "ру", "ра", "ре", "ры"]
		var is_valid = s in all_syllables
		
		var base_color = "#4dff4d" if is_valid else "#ff9999"
		var bbcode = "[center][color=" + base_color + "]Голос: [/color]"
		
		if is_valid:
			bbcode += "[color=#ff3333][b]" + s.to_upper() + "[/b][/color]"
			spawn_floating_text(s)
			
			# Map broader syllables to core РО, РИ, РУ cards on-screen
			var target_card = ""
			if s in ["ро", "ра", "ры"]:
				target_card = "ро"
			elif s in ["ри", "ре"]:
				target_card = "ри"
			elif s in ["ру"]:
				target_card = "ру"
				
			if target_card != "":
				_highlight_syllable(target_card)
		else:
			bbcode += "[color=#ffffff]" + text + "[/color]"
			
		bbcode += "[/center]"
		mic_debug_label.text = bbcode


func _highlight_syllable(s: String) -> void:
	if not syllable_cards.has(s):
		return
		
	var card = syllable_cards[s]
	var label: Label = card["label"]
	var style: StyleBoxFlat = card["style"]
	
	# Light up! Set bright red text and thick glowing red border
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0)) # Bright Red
	style.border_color = Color(1.0, 0.2, 0.2, 0.8)
	style.bg_color = Color(0.25, 0.05, 0.05, 0.85) # Reddish-dark background
	
	# Micro-animation: slight scale bump!
	var panel: PanelContainer = card["panel"]
	panel.pivot_offset = panel.size / 2.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Fade back after 0.8 seconds
	var revert_tween = create_tween()
	revert_tween.tween_interval(0.8)
	revert_tween.tween_callback(func():
		var revert_fade = create_tween().set_parallel(true)
		revert_fade.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2)
		revert_fade.tween_callback(func():
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.4))
			style.border_color = Color(0.4, 0.4, 0.5, 0.3)
			style.bg_color = Color(0.1, 0.1, 0.15, 0.7)
		)
	)


func _on_pipe_spawn() -> void:
	if game_over:
		return
	
	var screen_size = get_viewport_rect().size
	var center_y = randf_range(
		max(PIPE_MIN_Y + PIPE_GAP / 2, PIPE_GAP / 2 * 1.5),
		min(PIPE_MAX_Y - PIPE_GAP / 2, screen_size.y - PIPE_GAP / 2 * 1.5)
	)
	
	# Instantiate original pipe scene
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + 100
	
	# The original pipe scene expects its root position.y to be the gap center
	# But in original pipe.tscn, the gap is at y=0, so setting position.y works perfectly.
	pipe.position.y = center_y
	
	if pipe.has_method("set_gap"):
		pipe.set_gap(PIPE_GAP)
		
	pipe.hit.connect(_on_plane_collided)
	pipe.scored.connect(_on_score_zone_entered.bind(pipe))
	
	pipes.add_child(pipe)


func _on_plane_collided() -> void:
	_trigger_game_over()


func _on_plane_pipe_collision(_body: Node, _pipe: Node2D) -> void:
	if game_over:
		return
	_trigger_game_over()


func _on_score_zone_entered(pipe_node: Node2D) -> void:
	if game_over:
		return
	pipe_node.passed = true
	GameState.add_point()


func _on_restart_pressed() -> void:
	_restart_game()


func _start_game() -> void:
	game_started = true
	plane.is_active = true
	start_label.visible = false
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
	game_over_label.text = texts[GameState.lang]["game_over"] + "\n" + texts[GameState.lang]["high_score"] + str(GameState.high_score)
	game_over_label.visible = true
	restart_button.visible = true
	# Оставляем микрофон включённым: звук «Р» перезапустит игру


func _restart_game() -> void:
	# Clear pipes
	for pipe_child in pipes.get_children():
		pipe_child.queue_free()
	
	# Reset UI
	game_over_label.visible = false
	restart_button.visible = false
	start_label.visible = false
	
	# Reset plane
	plane.is_active = false
	plane.reset()
	
	# Reset state
	game_over = false
	game_started = false
	GameState.reset()
	_update_texts()
	start_label.visible = true
	SpeechManager.start_listening()


func _reset_game() -> void:
	GameState.reset()
	_update_score_display()
	game_over_label.visible = false
	restart_button.visible = false
	game_over = false
	game_started = false
	plane.reset()
	SpeechManager.start_listening()
	start_label.visible = true
	
	# Clear pipes
	for pipe_child in pipes.get_children():
		pipe_child.queue_free()
	
	# Начинаем слушать сразу, чтобы первый звук «Р» запустил игру
	SpeechManager.start_listening()


func _update_score_display(_new_score: int = 0) -> void:
	if score_label:
		score_label.text = texts[GameState.lang]["score"] + str(GameState.score)

func _toggle_lang() -> void:
	GameState.lang = "en" if GameState.lang == "ru" else "ru"
	_update_texts()

func _update_texts() -> void:
	_update_score_display()
	if not game_started:
		start_label.text = texts[GameState.lang]["start"]
	if game_over:
		game_over_label.text = texts[GameState.lang]["game_over"] + "\n" + texts[GameState.lang]["high_score"] + str(GameState.high_score)


func _on_mic_volume_updated(vol: float) -> void:
	if volume_bar and volume_bar.visible:
		# Map typical microphone audio RMS levels (0-2500) to 0-100%
		var percent = clampf(vol / 2500.0 * 100.0, 0.0, 100.0)
		volume_bar.value = percent


func _on_hud_toggle_pressed() -> void:
	if debug_hud:
		debug_hud.visible = not debug_hud.visible
		hud_toggle_btn.text = "HUD: ВКЛ" if debug_hud.visible else "HUD: ВЫКЛ"


func spawn_floating_text(syl_text: String) -> void:
	if not plane:
		return
	var label = Label.new()
	label.text = syl_text.to_upper() + "!"
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	label.position = plane.global_position + Vector2(-40, -80)
	
	# Bold black outline so text stands out on any background
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	
	add_child(label)
	
	# Floating animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 120.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	
	var sequence = create_tween()
	sequence.tween_interval(0.7)
	sequence.tween_callback(label.queue_free)