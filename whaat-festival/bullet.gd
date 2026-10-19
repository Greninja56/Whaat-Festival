class_name Bullet
extends Area2D

var velocity := Vector2.ZERO
var damage := 1


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += velocity * delta
	if not get_viewport_rect().grow(50.0).has_point(position):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		area.hit(damage)
		queue_free()
