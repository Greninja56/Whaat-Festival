extends Node2D

@export var enemy_scene: PackedScene
@export var heavy_scene: PackedScene
@export var cloaked_scene: PackedScene
@onready var settings_panel: PanelContainer = %SettingsPanel
@export_range(0.0, 1.0) var heavy_chance := 0.3
@export_range(0.0, 1.0) var cloaked_chance := 0.2
@export var static_delay := 0.1   # seconds after the final blast before the static cuts in
@onready var static_rect: ColorRect = %StaticRect
var results_ready := false
@export var base_hp := 3
@export var heavy_speed_mult := 0.25
@export var heavy_hp_mult := 5
@export var cloaked_speed_mult := 0.5
@export var cloaked_hp_mult := 1
@export var death_blasts := 24
@export var death_blast_gap := 0.08   # seconds between blasts
@export var token_time := 0.6
@export var token_size := 6.0
@export var token_color := Color(1.0, 0.85, 0.2)
@export var reload_bar_size := Vector2(120, 10)
@export var reload_bar_back := Color(0.1, 0.1, 0.1)
@onready var settings_button: Button = %SettingsButton
@onready var menu_button: Button = %MainMenuButton
@onready var reload_bars: Array[ProgressBar] = [%ReloadNormal, %ReloadHeavy]
@onready var launch_voice: AudioStreamPlayer = %LaunchVoices
@export var shake_max_offset := 14.0   # pixels at full trauma
@export var shake_decay := 2.5         # trauma lost per second
@onready var hangar_left: Marker2D = %HangarLeft
@onready var hangar_right: Marker2D = %HangarRight
@export var center_gap := 120.0
var next_side_left := true
@onready var camera: Camera2D = %ScreenShake

var shake_trauma := 0.0

@export var max_lives := 10
@export var enemy_damage := 2
@export var spawn_start := 10.0
@export var spawn_min := 1.0
@export var spawn_ramp := 0.01

# Currency / mini ships
@export var coin_normal := 0.5
@export var coin_heavy := 1
@export var coin_cloaked := 0.75
@export var ship_cost := 1
@export var mini_ship_scene: PackedScene
@export var station_y := 0.8   # fraction of screen height (0 = top, 1 = bottom)
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
@onready var die_sound: AudioStreamPlayer2D = %EnemyDies
@onready var oxygen_sound: AudioStreamPlayer2D = %OxygenAlarm
@onready var overheat_sound: AudioStreamPlayer2D = %OverheatAlarm
@onready var power_sound: AudioStreamPlayer2D = %PowerDown
@onready var shield_sound: AudioStreamPlayer2D = %ShieldDown
@onready var hangar_sound: AudioStreamPlayer2D = %HangarDown
@onready var game_over_sound: AudioStreamPlayer2D = %GameOverSound
@onready var heal_sound: AudioStreamPlayer2D = %Heal
@onready var hurt_sound: AudioStreamPlayer2D = %Hurt
@onready var fix_sound: AudioStreamPlayer2D = %Fixed
@onready var currency_label: Label = %CurrencyLabel
@onready var music: AudioStreamPlayer2D = %Music
@onready var hud: CanvasLayer = %HUD   # EFFECT: power failure
@onready var sonar_bar: ProgressBar = %SonarBar
@onready var lives := max_lives

@export var heal_ship_scene: PackedScene
@export var heal_spawn_min := 10.0   # seconds between heal ships
@export var heal_spawn_max := 20.0
var heal_timer := 0.0

@onready var bg: TextureRect = %Background


var elapsed := 0.0
var game_over := false
var currency := 5.0

# EFFECT state
var oxygen_active := false
var oxygen_tick_timer := 0.0
var shield_active := false
var power_active := false

var hangar_disabled := false

@export var ship_margin := 40.0   # keep ships away from the screen edges

@export var score_normal := 10
@export var score_heavy := 30
@export var score_cloaked := 50
@export var score_fix := 70

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10

@onready var score_label: Label = %ScoreLabel
@onready var leaderboard_label: Label = %Leaderboard
@onready var name_entry: LineEdit = %EnterName

var score := 0
var high_score := 0
var leaderboard: Array = []
var entering_name := false

@export var shield_start_time := 180.0     # seconds before shields appear
@export var shield_ramp_time := 300.0      # seconds to reach max chance
@export_range(0.0, 1.0) var shield_chance_start := 0.15
@export_range(0.0, 1.0) var shield_chance_max := 0.6
@export var shield_hp := 3.0

@export var tint_cycle_time := 1.2     # seconds per color when several problems are active
@export var tint_max_alpha := 0.3
@export var tint_edge_min := 0.015   # thinnest point of the pulse
@export var tint_edge_max := 0.025    # widest point of the pulse
@export var tint_pulse := true

@onready var edge_tint: ColorRect = %EdgeTint

var tint_mat: ShaderMaterial
var tint_index := 0
var tint_timer := 0.0
var tint_strength := 0.0
var tint_color := Color.WHITE

func _ready() -> void:
	lives_bar.max_value = max_lives
	lives_bar.value = lives
	label.visible = false
	heal_timer = randf_range(heal_spawn_min, heal_spawn_max)
	_add_currency(0)
	_load_leaderboard()
	name_entry.visible = false
	name_entry.max_length = 3
	name_entry.text_submitted.connect(_on_name_submitted)
	leaderboard_label.visible = false
	_add_score(0)
	tint_mat = edge_tint.material as ShaderMaterial
	tint_mat.set_shader_parameter("strength", 0.0)
	sonar_bar.max_value = turret.sonar_full_recharge_time
	sonar_bar.show_percentage = false
	bg.pivot_offset = bg.size * 0.5
	var t := create_tween().set_loops()
	t.tween_property(bg, "scale", Vector2(1.06, 1.06), 20.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(bg, "scale", Vector2.ONE, 20.0).set_trans(Tween.TRANS_SINE)
	settings_panel.visibility_changed.connect(func() -> void:
		turret.ui_open = settings_panel.visible)
	static_rect.visible = false
	settings_button.pressed.connect(func() -> void:
		settings_panel.toggle()
		turret.ui_open = settings_panel.visible)
	settings_button.mouse_entered.connect(func() -> void: turret.ui_open = true)
	settings_button.mouse_exited.connect(func() -> void: turret.ui_open = settings_panel.visible)
	settings_panel.visibility_changed.connect(func() -> void:
		settings_button.visible = not settings_panel.visible and not game_over)
	menu_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://main_menu.tscn"))
	_style_end_screen()


func _process(delta: float) -> void:
	_update_shake(delta)
	if game_over:
		if not results_ready:
			return
		if not entering_name and Input.is_action_just_pressed("ui_accept"):
			Esp.send("START")
			get_tree().reload_current_scene()
		elif not entering_name and Input.is_action_just_pressed("ui_cancel"):
			Esp.send("STOP")
			get_tree().change_scene_to_file("res://main_menu.tscn")
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
	if Input.is_action_just_pressed("fix_oxygen") and oxygen_active:
		oxygen_active = false
		oxygen_sound.stop()
		fix_sound.play()
		_add_score(score_fix)
	if Input.is_action_just_pressed("overheat"):
		turret.set_overheated(true)
		overheat_sound.play()
	if Input.is_action_just_pressed("fix_overheat") and turret.overheated:
		turret.set_overheated(false)
		overheat_sound.stop()
		fix_sound.play()
		_add_score(score_fix)
	if Input.is_action_just_pressed("power_failure"):
		_set_power_failure(true)
		power_sound.play()
	if Input.is_action_just_pressed("fix_power") and power_active:
		_set_power_failure(false)
		_add_score(score_fix)
		fix_sound.play()
	if Input.is_action_just_pressed("shield_failure"):
		shield_active = true
		shield_sound.play()
	if Input.is_action_just_pressed("fix_shield") and shield_active:
		shield_active = false
		_add_score(score_fix)
		fix_sound.play()
	if Input.is_action_just_pressed("hangar_failure"):
		_set_hangar_failure(true)
		hangar_sound.play()
	if Input.is_action_just_pressed("fix_hangar") and hangar_disabled:
		_set_hangar_failure(false)
		_add_score(score_fix)
		fix_sound.play()
	_process_oxygen_leak(delta)
	_update_edge_tint(delta)
	_update_sonar_bar()
	_update_reload_bars()

func _active_problem_colors() -> Array[Color]:
	var c: Array[Color] = []
	if turret.overheated:
		c.append(Color(1.0, 0.2, 0.2))    # gun overheating: red
	if power_active:
		c.append(Color(0.45, 0.7, 1.0))  # power failure: blue
	if oxygen_active:
		c.append(Color(0.2, 1.0, 0.35))   # oxygen leak: green
	if hangar_disabled:
		c.append(Color(1.0, 0.9, 0.2))    # hangar offline: yellow
	if shield_active:
		c.append(Color.WHITE)             # shield failure: white
	return c


func _update_edge_tint(delta: float) -> void:
	var colors := _active_problem_colors()
	var target := 0.0

	if colors.size() > 0:
		target = tint_max_alpha
		tint_index = tint_index % colors.size()

		# Several problems: step to the next color on a timer
		if colors.size() > 1:
			tint_timer -= delta
			if tint_timer <= 0.0:
				tint_timer = tint_cycle_time
				tint_index = (tint_index + 1) % colors.size()

		if tint_strength < 0.01:
			tint_color = colors[tint_index]   # fading in from nothing: no color slide
		else:
			tint_color = tint_color.lerp(colors[tint_index], 1.0 - exp(-8.0 * delta))
	else:
		tint_index = 0
		tint_timer = 0.0

	tint_strength = move_toward(tint_strength, target, delta * 2.0)

	var edge := tint_edge_max
	if tint_pulse:
		var wave := 0.5 + 0.5 * sin(elapsed * 6.0)   # 0..1
		edge = lerpf(tint_edge_min, tint_edge_max, wave)

	tint_mat.set_shader_parameter("tint", tint_color)
	tint_mat.set_shader_parameter("strength", tint_strength)
	tint_mat.set_shader_parameter("edge_size", edge)
	
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
	var points := score_normal
	if scene == heavy_scene:
		speed_mult = heavy_speed_mult
		hp_mult = heavy_hp_mult
		coins = coin_heavy
		points = score_heavy
	elif scene == cloaked_scene:
		speed_mult = cloaked_speed_mult
		hp_mult = cloaked_hp_mult
		coins = coin_cloaked
		points = score_cloaked

	e.max_hp = base_hp * hp_mult
	e.currency_value = coins
	e.position = Vector2(randf_range(30.0, width - 30.0), -20.0)
	e.speed = (60.0 + elapsed * 0.8) * speed_mult
	e.bottom_y = turret.position.y
	e.reached_bottom.connect(_on_enemy_reached_bottom)
	e.died.connect(_on_enemy_died.bind(points))
	if scene != cloaked_scene and elapsed >= shield_start_time:
		var t := clampf((elapsed - shield_start_time) / shield_ramp_time, 0.0, 1.0)
		if randf() < lerpf(shield_chance_start, shield_chance_max, t):
			e.set_shield(shield_hp)
	add_child(e)

	if scene == cloaked_scene:
		cloaked_sound.play()


func _on_enemy_reached_bottom() -> void:
	var mult := shield_damage_mult if shield_active else 1.0
	_lose_lives(roundi(enemy_damage * mult))


func _on_enemy_died(value: float, pos: Vector2, points: int) -> void:
	_spawn_token(pos, value)
	_add_score(points)
	die_sound.play()


func _add_currency(amount: float) -> void:
	currency = snappedf(currency + amount, 0.01)   # avoids 0.30000000004 drift
	currency_label.text = ": %s" % String.num(currency, 2)

func _launch_mini_ship() -> void:
	if hangar_disabled or currency < ship_cost:
		return
	_add_currency(-ship_cost)

	var left := next_side_left
	next_side_left = not next_side_left   # alternate sides each launch

	var size := get_viewport_rect().size
	var door := hangar_left if left else hangar_right

	var x_min := ship_margin if left else size.x * 0.5 + center_gap
	var x_max := size.x * 0.5 - center_gap if left else size.x - ship_margin
	var station := Vector2(randf_range(x_min, x_max), size.y * station_y)

	var s := mini_ship_scene.instantiate() as MiniShip
	add_child(s)
	s.setup(door.global_position, station)
	var rand_stream := launch_voice.stream as AudioStreamRandomizer
	if rand_stream and rand_stream.streams_count > 0:
		launch_voice.play()

func _lose_lives(amount: int) -> void:
	if game_over:
		return
	lives = maxi(lives - amount, 0)
	_shake(0.3 + 0.15 * amount)
	hurt_sound.play()
	if lives == 0:
		_end_game()
	_update_label()


func _end_game() -> void:
	game_over = true
	oxygen_sound.stop()
	overheat_sound.stop()
	oxygen_active = false
	shield_active = false
	hangar_disabled = false
	music.stop()
	game_over_sound.play()
	_death_explosions()
	spawn_timer.stop()
	edge_tint.visible = false
	settings_panel.close()
	turret.ui_open = false
	settings_button.visible = false
	Esp.send("STOP")
	turret.process_mode = Node.PROCESS_MODE_DISABLED
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	for h in get_tree().get_nodes_in_group("heal_ships"):
		h.queue_free()
	_show_static_screen()


func _update_label() -> void:
	lives_bar.value = lives


# EFFECT functions
func _start_oxygen_leak() -> void:
	if oxygen_active:
		return
	oxygen_active = true
	oxygen_tick_timer = oxygen_tick
	oxygen_sound.play()


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
	heal_sound.play()
	_update_label()
	
func _add_score(amount: int) -> void:
	score += amount
	score_label.text = "Score: %d" % [score]

func _qualifies() -> bool:
	if score <= 0:
		return false
	return leaderboard.size() < MAX_ENTRIES or score > int(leaderboard.back()["score"])


func _on_name_submitted(text: String) -> void:
	var player_name := text.strip_edges().to_upper()
	if player_name.length() < 3:
		return
	leaderboard.append({"name": player_name, "score": score})
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	leaderboard.resize(mini(leaderboard.size(), MAX_ENTRIES))
	_save_leaderboard()
	name_entry.visible = false
	name_entry.release_focus()
	_show_results()
	# The Enter key that submitted the name would also restart the game,
	# so wait briefly before allowing restart.
	await get_tree().create_timer(0.4).timeout
	entering_name = false


func _show_results() -> void:
	label.text = "GAME OVER\nScore: %d\n" % score
	leaderboard_label.text = _leaderboard_text()
	leaderboard_label.visible = true
	menu_button.visible = true


func _leaderboard_text() -> String:
	var lines: Array[String] = ["HIGH SCORES"]
	for i in leaderboard.size():
		var e: Dictionary = leaderboard[i]
		lines.append("%d. %s   %d" % [i + 1, e["name"], int(e["score"])])
	return "\n".join(lines)


func _load_leaderboard() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data is Array:
		leaderboard = data
		if not leaderboard.is_empty():
			high_score = int(leaderboard[0]["score"])


func _save_leaderboard() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(leaderboard))
	
func _shake(amount: float) -> void:
	shake_trauma = minf(shake_trauma + amount, 1.0)


func _update_shake(delta: float) -> void:
	shake_trauma = maxf(shake_trauma - shake_decay * delta, 0.0)
	var power := shake_trauma * shake_trauma   # squared, so small hits are subtle
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_max_offset * power

func _update_sonar_bar() -> void:
	sonar_bar.value = turret.sonar_progress
	
func _update_reload_bars() -> void:
	for i in reload_bars.size():
		var reloading := i == turret.current and turret.reload_left > 0.0
		reload_bars[i].visible = reloading
		if reloading:
			reload_bars[i].value = turret.reload_progress()
			
func _spawn_token(world_pos: Vector2, value: float) -> void:
	# World position -> screen position (accounts for the camera shake offset)
	var start := get_viewport().get_canvas_transform() * world_pos
	var end := currency_label.global_position + currency_label.size * 0.5

	var t := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		pts.append(Vector2.from_angle(TAU * i / 12.0) * token_size)
	t.polygon = pts
	t.color = token_color
	t.position = start
	hud.add_child(t)

	var tween := create_tween()
	tween.tween_property(t, "position", end, token_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(t, "scale", Vector2(0.5, 0.5), token_time)
	tween.tween_callback(func() -> void:
		_add_currency(value)
		t.queue_free()
	)
	
func _death_explosions() -> void:
	var size := get_viewport_rect().size
	var center := turret.global_position

	var tween := create_tween()
	for i in death_blasts:
		tween.tween_callback(func() -> void:
			var pos := center + Vector2(randf_range(-size.x * 0.35, size.x * 0.35), randf_range(-size.y * 0.3, 40.0))
			var col := Color(1.0, randf_range(0.2, 0.7), 0.1)
			Explosion.spawn(self, pos, randf_range(1.5, 3.5), col)
			_shake(0.25)
		)
		tween.tween_interval(death_blast_gap)

	# Final big blast on the turret
	tween.tween_callback(func() -> void:
		Explosion.spawn(self, center, 6.0, Color(1.0, 0.5, 0.15))
		_shake(1.0)
		turret.visible = false
	)
	
func _unhandled_input(event: InputEvent) -> void:
	if game_over or entering_name:
		return
	if event.is_action_pressed("ui_cancel"):
		settings_panel.toggle()
		turret.ui_open = settings_panel.visible
		
func _show_static_screen() -> void:
	# let the death explosions finish first
	await get_tree().create_timer(death_blasts * death_blast_gap + static_delay).timeout

	# cut to static (quick fade so it punches in)
	static_rect.modulate.a = 0.0
	static_rect.visible = true
	create_tween().tween_property(static_rect, "modulate:a", 1.0, 0.15)

	# power failure hides the whole HUD, so restore it, then hide everything except the end screen
	hud.visible = true
	for child in hud.get_children():
		if child is CanvasItem and child != label and child != leaderboard_label and child != name_entry and child != menu_button:
			child.visible = false

	label.visible = true
	if _qualifies():
		entering_name = true
		label.text = "GAME OVER\nScore: %d\nNew high score! Enter 3 characters:" % score
		name_entry.text = ""
		name_entry.visible = true
		name_entry.grab_focus()
	else:
		_show_results()
	results_ready = true


func _style_end_screen() -> void:
	var size := get_viewport_rect().size
	for l: Label in [label, leaderboard_label]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 28)
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position.y = size.y * 0.1
	leaderboard_label.size.x = size.x
	leaderboard_label.position = Vector2(0, size.y * 0.3)
	name_entry.custom_minimum_size = Vector2(260, 44)
	name_entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_entry.add_theme_font_size_override("font_size", 24)
