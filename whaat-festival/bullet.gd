class_name Bullet
extends Area2D

var velocity := Vector2.ZERO
var damage := 1.0
var shield_damage := 0.1
var used := false

const OFFSCREEN_MARGIN := 100.0

func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += velocity * delta
	_free_if_offscreen()

func _on_area_entered(area: Area2D) -> void:
	if used or not area.has_method("hit"):
		return
	used = true
	area.hit(damage, shield_damage)
	Explosion.spawn(get_tree().current_scene, global_position, 0.4 * scale.x, modulate)
	queue_free()


func _free_if_offscreen() -> void:
	var rect := get_viewport_rect().grow(OFFSCREEN_MARGIN)
	if not rect.has_point(global_position):
		queue_free()
