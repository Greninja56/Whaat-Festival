class_name Bullet
extends Area2D

var velocity := Vector2.ZERO
var damage := 1.0


func _process(delta: float) -> void:
	position += velocity * delta


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("hit"):
		area.hit(damage)
		queue_free()
