class_name Turret
extends Node2D

signal status_changed(text: String)
#hi
@export var bullet_scene: PackedScene

@export var max_angle_deg := 80.0
@export var physical_range_deg := 80.0
@export var port := 50000
@export var smooth := 20.0
@export var deadzone_deg := 0.5
@export var key_speed_deg := 120.0
@export var key_hold_ms := 300
@export var debug_print := false
@export var bullet_parent: Node
@export var hold_to_fire := true

var ammo_types: Array[Dictionary] = [
	{"name": "Standard", "damage": 1, "mag": 30, "fire_rate": 8.0,
	 "reload": 1.2, "speed": 600.0, "color": Color(1.0, 0.9, 0.3)},
	{"name": "Heavy", "damage": 3, "mag": 6, "fire_rate": 2.0,
	 "reload": 2.0, "speed": 450.0, "color": Color(1.0, 0.4, 0.2)},
]

@onready var gun: Marker2D = %Gun

var udp := PacketPeerUDP.new()
var cooldown := 0.0
var keyboard_until_ms := 0
var raw_yaw := 0.0
var center_yaw := 0.0
var centered := false
var flip := -1.0
var target_angle := 0.0
var packet_count := 0

var current := 0
var mags: Array[int] = []
var reload_left := 0.0


func _ready() -> void:
	if udp.bind(port) != OK:
		push_error("Could not bind UDP port %d" % port)
	for a in ammo_types:
		mags.append(a["mag"])
	status_changed.emit.call_deferred(status_text())


func _process(delta: float) -> void:
	_read_packets()
	_read_keyboard(delta)
	rotation = lerp_angle(rotation, target_angle, 1.0 - exp(-smooth * delta))
	_update_reload(delta)

	cooldown = maxf(cooldown - delta, 0.0)
	if hold_to_fire and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _can_shoot():
		_shoot()


func _read_packets() -> void:
	while udp.get_available_packet_count() > 0:
		var text := udp.get_packet().get_string_from_utf8()
		packet_count += 1
		if debug_print and packet_count % 30 == 1:
			print("PACKET: ", text.left(300))
		var data = JSON.parse_string(text)
		if data is Dictionary and data.has("sensordata"):
			_handle(data["sensordata"])


func _read_keyboard(delta: float) -> void:
	var key_axis := Input.get_axis("ui_left", "ui_right")
	if key_axis == 0.0:
		return
	keyboard_until_ms = Time.get_ticks_msec() + key_hold_ms
	var limit := deg_to_rad(max_angle_deg)
	target_angle = clampf(
		target_angle + key_axis * deg_to_rad(key_speed_deg) * delta,
		-limit, limit
	)


func _update_reload(delta: float) -> void:
	if reload_left <= 0.0:
		return
	reload_left -= delta
	if reload_left <= 0.0:
		reload_left = 0.0
		mags[current] = ammo_types[current]["mag"]
		status_changed.emit(status_text())


func _handle(s: Dictionary) -> void:
	if debug_print:
		print("keys: ", s.keys())
	if not s.has("quaternion"):
		return

	var q = s["quaternion"]
	raw_yaw = atan2(
		2.0 * (q["w"] * q["z"] + q["x"] * q["y"]),
		1.0 - 2.0 * (q["y"] * q["y"] + q["z"] * q["z"])
	)

	if not centered:
		center_yaw = raw_yaw
		centered = true

	if Time.get_ticks_msec() < keyboard_until_ms:
		return

	var d_deg := rad_to_deg(wrapf(raw_yaw - center_yaw, -PI, PI)) * flip
	if absf(d_deg) < deadzone_deg:
		d_deg = 0.0

	var t := clampf(d_deg / physical_range_deg, -1.0, 1.0)
	target_angle = t * deg_to_rad(max_angle_deg)


func _unhandled_input(event: InputEvent) -> void:
	if not hold_to_fire and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and _can_shoot():
		_shoot()

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				center_yaw = raw_yaw
				target_angle = 0.0
			KEY_F:
				flip = -flip
			KEY_R:
				_start_reload()
			KEY_1:
				_switch_to(0)
			KEY_2:
				_switch_to(1)
			KEY_Q:
				_switch_to((current + 1) % ammo_types.size())


func _switch_to(index: int) -> void:
	if index == current:
		return
	current = index
	reload_left = 0.0
	cooldown = 0.15
	status_changed.emit(status_text())


func _start_reload() -> void:
	var ammo := ammo_types[current]
	if reload_left > 0.0 or mags[current] >= ammo["mag"]:
		return
	reload_left = ammo["reload"]
	status_changed.emit(status_text())


func _can_shoot() -> bool:
	return reload_left <= 0.0 and cooldown <= 0.0 and mags[current] > 0


func _shoot() -> void:
	var ammo := ammo_types[current]
	mags[current] -= 1
	cooldown = 1.0 / ammo["fire_rate"]

	var b := bullet_scene.instantiate() as Bullet
	b.velocity = Vector2.UP.rotated(global_rotation) * ammo["speed"]
	b.damage = ammo["damage"]
	b.modulate = ammo["color"]

	var parent := bullet_parent if bullet_parent else get_tree().current_scene
	parent.add_child(b)
	b.global_position = gun.global_position

	status_changed.emit(status_text())


func status_text() -> String:
	var parts: Array[String] = []
	for i in ammo_types.size():
		var a := ammo_types[i]
		var line := "[%d] %s %d/%d" % [i + 1, a["name"], mags[i], a["mag"]]
		if i == current:
			line = "> " + line
			if reload_left > 0.0:
				line += "  RELOADING..."
			elif mags[i] == 0:
				line += "  EMPTY - press R"
		parts.append(line)
	return "\n".join(parts)
