extends Node2D

@export var enemy_scene: PackedScene
@export var heavy_scene: PackedScene
@export var cloaked_scene: PackedScene
@export_range(0.0, 1.0) var heavy_chance := 0.3
@export_range(0.0, 1.0) var cloaked_chance := 0.1
@export var base_hp := 3  # must match max_hp on your normal enemy scene
@export var heavy_speed_mult := 0.25
@export var heavy_hp_mult := 5
@export var cloaked_speed_mult := 0.5
@export var cloaked_hp_mult := 1

@export var max_lives := 50
@export var spawn_start := 10.0
@export var spawn_min := 1.0
@export var spawn_ramp := 0.01

@onready var turret: Turret = %Turret
@onready var lives_bar: ProgressBar = %LivesBar
@onready var label: Label = %GameOver 
@onready var spawn_timer: Timer = %SpawnTimer
@onready var lives := max_lives

@export var oxygen_tick := 1.0
@export var oxygen_damage := 2
var oxygen_active := false
var oxygen_tick_timer := 0.0

@onready var cloaked_sound: AudioStreamPlayer2D = %CloakedSpawn

var elapsed := 0.0
var game_over := false


func _ready() -> void:
	lives_bar.max_value = max_lives
	lives_bar.value = lives
	label.visible = false


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	elapsed += delta
	
	if Input.is_action_just_pressed("oxygen_leak"):
		_start_oxygen_leak()
	if Input.is_action_just_pressed("fix_oxygen"):
		_stop_oxygen_leak()
	_process_oxygen_leak(delta)
	if Input.is_action_just_pressed("overheat"):
		turret.set_overheated(true)
	if Input.is_action_just_pressed("fix_overheat"):
		turret.set_overheated(false)


func _on_spawn_timer_timeout() -> void:
	_spawn_enemy()
	spawn_timer.start(maxf(spawn_min, spawn_start - elapsed * spawn_ramp))

func _pick_scene() -> PackedScene:
	var roll := randf()
	if roll < cloaked_chance:
		return cloaked_scene
	if roll < cloaked_chance + heavy_chance:
		return heavy_scene
	return enemy_scene

func _spawn_enemy() -> void:
	var width := get_viewport_rect().size.x
	var scene := _pick_scene()
	var e := scene.instantiate() as Enemy

	var speed_mult := 1.0
	var hp_mult := 1
	if scene == heavy_scene:
		speed_mult = heavy_speed_mult
		hp_mult = heavy_hp_mult
	elif scene == cloaked_scene:
		speed_mult = cloaked_speed_mult
		hp_mult = cloaked_hp_mult

	e.max_hp = base_hp * hp_mult
	e.position = Vector2(randf_range(30.0, width - 30.0), -20.0)
	e.speed = (60.0 + elapsed * 0.8) * speed_mult
	e.bottom_y = turret.position.y
	e.reached_bottom.connect(_on_enemy_reached_bottom)
	add_child(e)

	if scene == cloaked_scene:
		cloaked_sound.play()


func _on_enemy_reached_bottom() -> void:
	_lose_lives(1)

func _lose_lives(amount: int) -> void:
	if game_over:
		return
	lives = maxi(lives - amount, 0)
	if lives == 0:
		_end_game()
	_update_label()


func _end_game() -> void:
	game_over = true
	spawn_timer.stop()
	oxygen_active = false
	turret.process_mode = Node.PROCESS_MODE_DISABLED
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()


func _update_label() -> void:
	lives_bar.value = lives
	if game_over:
		label.text = "GAME OVER  (Enter to restart)"
		label.visible = true
		
func _start_oxygen_leak() -> void:
	if oxygen_active:
		return 
	oxygen_active = true
	oxygen_tick_timer = oxygen_tick

func _stop_oxygen_leak() -> void:
	oxygen_active = false
	
func _process_oxygen_leak(delta: float) -> void:
	if not oxygen_active:
		return
	oxygen_tick_timer -= delta
	if oxygen_tick_timer <= 0.0:
		oxygen_tick_timer += oxygen_tick
		_lose_lives(oxygen_damage)
