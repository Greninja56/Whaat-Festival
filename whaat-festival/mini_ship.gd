class_name MiniShip
extends Node2D

enum State { LAUNCH, ACTIVE, RETURN }

@export var travel_speed := 400.0

var state := State.LAUNCH
var home := Vector2.ZERO      # hangar position
var station := Vector2.ZERO   # where it hovers and shoots

@export var bullet_scene: PackedScene
@export var lifetime := 15.0
@export var fire_rate := 1.5     # shots per second
@export var bullet_speed := 400.0
@export var damage := 0.5
@export var aim_at_enemies := true  # false = always shoot straight up
@export var flash_size := 10.0
@export var flash_time := 0.1
@export var flash_color := Color(1.0, 0.904, 0.99, 1.0)

@onready var muzzle: Marker2D = %Muzzle
@onready var shoot_sound: AudioStreamPlayer2D = $Shoot
var aim_dir := Vector2.UP   # last direction aimed; reused when there's no target

var age := 0.0
var cooldown := 0.0


func _process(delta: float) -> void:
	trail.emitting = state != State.ACTIVE
	match state:
		State.LAUNCH:
			if _fly_to(station, delta):
				state = State.ACTIVE
				rotation = 0.0
				cooldown = 0.0   # fire as soon as it arrives
		State.ACTIVE:
			age += delta
			if age >= lifetime:
				state = State.RETURN
				return
			cooldown -= delta
			if cooldown <= 0.0:
				cooldown = 1.0 / fire_rate
				_shoot()
		State.RETURN:
			if _fly_to(home, delta):
				queue_free()


# Moves toward the target at travel_speed. Returns true once it has arrived.
func _fly_to(target: Vector2, delta: float) -> bool:
	var to := target - global_position
	if to.length() > 1.0:
		rotation = to.angle() + PI / 2.0   # face the direction of travel
	global_position = global_position.move_toward(target, travel_speed * delta)
	return global_position.distance_to(target) < 1.0

func _shoot() -> void:
	shoot_sound.pitch_scale = randf_range(0.95, 1.15)
	shoot_sound.play()

	if aim_at_enemies:
		var target := _find_target()
		if target:
			aim_dir = _lead_direction(target)

	rotation = aim_dir.angle() + PI / 2.0   # always face the aim direction
	_flash()

	var b := bullet_scene.instantiate() as Bullet
	b.velocity = aim_dir * bullet_speed
	b.damage = damage
	get_tree().current_scene.add_child(b)
	b.global_position = muzzle.global_position
	b.global_rotation = muzzle.global_rotation


func _lead_direction(target: Enemy) -> Vector2:
	var d := target.global_position - global_position
	var v := Vector2(0.0, target.speed)   # enemies only move straight down

	# Solve |d + v*t| = bullet_speed * t for the time t of impact
	var a := v.dot(v) - bullet_speed * bullet_speed
	var b := 2.0 * d.dot(v)
	var c := d.dot(d)

	var t := 0.0
	if absf(a) < 0.001:
		if absf(b) > 0.001:
			t = -c / b
	else:
		var disc := b * b - 4.0 * a * c
		if disc >= 0.0:
			var sq := sqrt(disc)
			var t1 := (-b - sq) / (2.0 * a)
			var t2 := (-b + sq) / (2.0 * a)
			t = minf(t1, t2) if (t1 > 0.0 and t2 > 0.0) else maxf(t1, t2)

	if t <= 0.0:
		return d.normalized()   # no valid intercept, aim directly
	return (d + v * t).normalized()


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best
	
func _flash() -> void:
	var f := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var ang := TAU * i / 8.0
		var r := flash_size if i % 2 == 0 else flash_size * 0.45
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	f.polygon = pts
	f.color = flash_color
	muzzle.add_child(f)

	var tween := create_tween()
	tween.tween_property(f, "modulate:a", 0.0, flash_time)
	tween.tween_callback(f.queue_free)
	
func setup(from: Vector2, to: Vector2) -> void:
	home = from
	station = to
	global_position = from

var trail: FuelTrail

func _ready() -> void:
	trail = FuelTrail.attach(self, Vector2.DOWN, Vector2(0, 12), Color(1.0, 1.0, 1.0, 1.0), 10.0)
