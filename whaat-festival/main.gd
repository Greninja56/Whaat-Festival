extends Node2D

@export var enemy_scene: PackedScene
@export var heavy_scene: PackedScene
@export var cloaked_scene: PackedScene
@export_range(0.0, 1.0) var heavy_chance := 0.3
@export_range(0.0, 1.0) var cloaked_chance := 0.1
@export var base_hp := 3
@export var heavy_speed_mult := 0.25
@export var heavy_hp_mult := 5
@export var cloaked_speed_mult := 0.5
@export var cloaked_hp_mult := 1

@export var max_lives := 50
@export var enemy_damage := 2
@export var spawn_start := 10.0
@export var spawn_min := 1.0
@export var spawn_ramp := 0.01

# Currency / mini ships
@export var coin_normal := 1
@export var coin_heavy := 3
@export var coin_cloaked := 5
@export var ship_cost := 1
@export var mini_ship_scene: PackedScene

# EFFECT: oxygen
@export var oxygen_tick := 1.0
@export var oxygen_damage := 2
# EFFECT: shield
@export var shield_damage_mult := 1.5

@onready var turret: Turret = %Turret
@onready var lives_bar: ProgressBar = %LivesBar
@onready var label: Label = %GameOver
@onready var spawn_timer: Timer = %SpawnTimer
@onready var cloaked_sound: AudioStreamPlayer2D = %CloakedSpawn
@onready var currency_label: Label = %CurrencyLabel
@onready var hud: CanvasLayer = %HUD   # EFFECT: power failure
@onready var lives := max_lives

@export var heal_ship_scene: PackedScene
@export var heal_spawn_min := 5.0   # seconds between heal ships
@export var heal_spawn_max := 10.0
var heal_timer := 0.0

var elapsed := 0.0
var game_over := false
var currency := 0

# EFFECT state
var oxygen_active := false
var oxygen_tick_timer := 0.0
var shield_active := false
var power_active := false

var hangar_disabled := false

@export var ship_margin := 40.0   # keep ships away from the screen edges

func _ready() -> void:
	lives_bar.max_value = max_lives
	lives_bar.value = lives
	label.visible = false
	heal_timer = randf_range(heal_spawn_min, heal_spawn_max)
	_add_currency(0)


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	elapsed += delta
	heal_timer -= delta
	if heal_timer <= 0.0:
		heal_timer = randf_range(heal_spawn_min, heal_spawn_max)
		_spawn_heal_ship()

	if Input.is_action_just_pressed("launch_ship"):
		_launch_mini_ship()

	# EFFECT inputs
	if Input.is_action_just_pressed("oxygen_leak"):
		_start_oxygen_leak()
	if Input.is_action_just_pressed("fix_oxygen"):
		oxygen_active = false
	if Input.is_action_just_pressed("overheat"):
		turret.set_overheated(true)
	if Input.is_action_just_pressed("fix_overheat"):
		turret.set_overheated(false)
	if Input.is_action_just_pressed("power_failure"):
		_set_power_failure(true)
	if Input.is_action_just_pressed("fix_power"):
		_set_power_failure(false)
	if Input.is_action_just_pressed("shield_failure"):
		shield_active = true
	if Input.is_action_just_pressed("fix_shield"):
		shield_active = false
	if Input.is_action_just_pressed("hangar_failure"):
		_set_hangar_failure(true)
	if Input.is_action_just_pressed("fix_hangar"):
		_set_hangar_failure(false)
	_process_oxygen_leak(delta)


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
	var coins := coin_normal
	if scene == heavy_scene:
		speed_mult = heavy_speed_mult
		hp_mult = heavy_hp_mult
		coins = coin_heavy
	elif scene == cloaked_scene:
		speed_mult = cloaked_speed_mult
		hp_mult = cloaked_hp_mult
		coins = coin_cloaked

	e.max_hp = base_hp * hp_mult
	e.currency_value = coins
	e.position = Vector2(randf_range(30.0, width - 30.0), -20.0)
	e.speed = (60.0 + elapsed * 0.8) * speed_mult
	e.bottom_y = turret.position.y
	e.reached_bottom.connect(_on_enemy_reached_bottom)
	e.died.connect(_on_enemy_died)
	add_child(e)

	if scene == cloaked_scene:
		cloaked_sound.play()


func _on_enemy_reached_bottom() -> void:
	var mult := shield_damage_mult if shield_active else 1.0
	_lose_lives(roundi(enemy_damage * mult))


func _on_enemy_died(value: int) -> void:
	_add_currency(value)


func _add_currency(amount: int) -> void:
	currency += amount
	currency_label.text = "Credits: %d" % currency

func _launch_mini_ship() -> void:
	if hangar_disabled or currency < ship_cost:
		return
	if currency < ship_cost:
		return
	_add_currency(-ship_cost)

	var size := get_viewport_rect().size
	var s := mini_ship_scene.instantiate()
	add_child(s)
	s.global_position = Vector2(
		randf_range(ship_margin, size.x - ship_margin),
		size.y - ship_margin
	)


func _lose_lives(amount: int) -> void:
	if game_over:
		return
	lives = maxi(lives - amount, 0)
	if lives == 0:
		_end_game()
	_update_label()


func _end_game() -> void:
	game_over = true
	oxygen_active = false
	shield_active = false
	hangar_disabled = false
	spawn_timer.stop()
	turret.process_mode = Node.PROCESS_MODE_DISABLED
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	for h in get_tree().get_nodes_in_group("heal_ships"):
		h.queue_free()


func _update_label() -> void:
	lives_bar.value = lives
	if game_over:
		label.text = "GAME OVER  (Enter to restart)"
		label.visible = true


# EFFECT functions
func _start_oxygen_leak() -> void:
	if oxygen_active:
		return
	oxygen_active = true
	oxygen_tick_timer = oxygen_tick


func _process_oxygen_leak(delta: float) -> void:
	if not oxygen_active:
		return
	oxygen_tick_timer -= delta
	if oxygen_tick_timer <= 0.0:
		oxygen_tick_timer += oxygen_tick
		_lose_lives(oxygen_damage)


func _set_power_failure(on: bool) -> void:
	power_active = on
	hud.visible = not on

func _set_hangar_failure(on: bool) -> void:
	hangar_disabled = on
	currency_label.modulate = Color(1.0, 0.9, 0.2) if on else Color.WHITE

func _spawn_heal_ship() -> void:
	var size := get_viewport_rect().size
	var s := heal_ship_scene.instantiate() as HealShip
	s.position = Vector2(-40.0, randf_range(size.y * 0.1, size.y * 0.5))
	s.right_x = size.x + 40.0
	s.collected.connect(_on_heal_collected)
	add_child(s)


func _on_heal_collected(amount: int) -> void:
	if game_over:
		return
	lives = mini(lives + amount, max_lives)
	_update_label()
