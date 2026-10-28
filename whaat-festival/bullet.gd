class_name Bullet
extends Area2D

var velocity := Vector2.ZERO
var damage := 1.0


func _process(delta: float) -> void:
	position += velocity * delta

var shield_damage := 0.1   # weak by default, so mini ships can't strip shields

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("hit"):
		area.hit(damage, shield_damage)
		queue_free()
