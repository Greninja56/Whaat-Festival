extends Node2D

@export var enemy_scene: PackedScene
@export var max_lives := 5
@export var spawn_start := 5.0
@export var spawn_min := 1.0
@export var spawn_ramp := 0.01

@onready var turret: Turret = %Turret
@onready var label: Label = %LivesLabel
@onready var spawn_timer: Timer = %SpawnTimer
@onready var lives := max_lives

var elapsed := 0.0
var game_over := false


func _ready() -> void:
	_update_label()


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	elapsed += delta


func _on_spawn_timer_timeout() -> void:
	_spawn_enemy()
	spawn_timer.start(maxf(spawn_min, spawn_start - elapsed * spawn_ramp))


func _spawn_enemy() -> void:
	var width := get_viewport_rect().size.x
	var e := enemy_scene.instantiate() as Enemy
	e.position = Vector2(randf_range(30.0, width - 30.0), -20.0)
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
	spawn_timer.stop()
	turret.process_mode = Node.PROCESS_MODE_DISABLED
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()


func _update_label() -> void:
	if game_over:
		label.text = "GAME OVER  (Enter to restart)"
	else:
		label.text = "Lives: %d" % lives
