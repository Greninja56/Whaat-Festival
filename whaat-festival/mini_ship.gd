class_name MiniShip
extends Node2D

@export var bullet_scene: PackedScene
@export var lifetime := 15.0
@export var fire_rate := 1.5     # shots per second
@export var bullet_speed := 400.0
@export var damage := 0.5
@export var aim_at_enemies := true  # false = always shoot straight up

var age := 0.0
var cooldown := 0.0


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return

	cooldown -= delta
	if cooldown <= 0.0:
		cooldown = 1.0 / fire_rate
		_shoot()


func _shoot() -> void:
	var dir := Vector2.UP
	if aim_at_enemies:
		var target := _find_target()
		if target:
			dir = _lead_direction(target)
			rotation = dir.angle() + PI / 2.0

	var b := bullet_scene.instantiate() as Bullet
	b.velocity = dir * bullet_speed
	b.damage = damage
	get_tree().current_scene.add_child(b)
	b.global_position = global_position


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
