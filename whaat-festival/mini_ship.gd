class_name MiniShip
extends Node2D

@export var speed := 300.0
@export var damage := 1
@export var lifetime := 6.0
@export var hit_radius := 24.0
@export var hit_interval := 0.4

var age := 0.0
var hit_timer := 0.0
var target: Node2D


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return

	hit_timer = maxf(hit_timer - delta, 0.0)

	if not is_instance_valid(target):
		target = _find_target()

	if target:
		var to_target := target.global_position - global_position
		rotation = to_target.angle() + PI / 2.0
		global_position += to_target.normalized() * speed * delta
		if to_target.length() <= hit_radius and hit_timer <= 0.0:
			target.take_damage(damage)
			hit_timer = hit_interval
	else:
		global_position += Vector2.UP * speed * delta   # no enemies: fly forward


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best
