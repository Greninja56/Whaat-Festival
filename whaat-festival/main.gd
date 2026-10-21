extends Node2D

const EnemyScene := preload("res://enemy.tscn")   # adjust path

@onready var turret: Turret = %Turret
var label: Label
var lives := 5
var elapsed := 0.0
var spawn_timer := 1.0
var game_over := false
var ammo_label: Label
@export var max_lives := 5
@export var spawn_start := 5.0    # seconds between enemies at the start
@export var spawn_min := 1.0      # fastest it ever gets
@export var spawn_ramp := 0.01    # seconds saved per second played


func _ready() -> void:
	var size := get_viewport_rect().size
	turret.position = Vector2(size.x / 2.0, size.y - 40.0)

	lives = max_lives

	# HUD: a CanvasLayer keeps the label fixed on screen
	var hud := CanvasLayer.new()
	add_child(hud)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label.offset_right = -16   # padding from the right edge
	label.offset_top = 12      # padding from the top

	_update_label()


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return

	elapsed += delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = max(spawn_min, spawn_start - elapsed * spawn_ramp)


func _spawn_enemy() -> void:
	var size := get_viewport_rect().size
	var e := EnemyScene.instantiate() as Enemy
	e.position = Vector2(randf_range(30.0, size.x - 30.0), -20.0)
	e.speed = 60.0 + elapsed * 0.8
	e.bottom_y = turret.position.y
	e.reached_bottom.connect(_on_enemy_reached_bottom)
	add_child(e)


func _on_enemy_reached_bottom() -> void:
	if game_over:
		return
	lives -= 1
	if lives <= 0:
		lives = 0
		_end_game()
	_update_label()


func _end_game() -> void:
	game_over = true
	turret.set_process(false)
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()


func _update_label() -> void:
	if game_over:
		label.text = "GAME OVER  (Enter to restart)"
	else:
		label.text = "Lives: %d" % lives
