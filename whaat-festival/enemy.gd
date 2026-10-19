class_name Enemy
extends Area2D

signal died
signal reached_bottom

@export var max_hp := 3

var speed := 50.0
var hp := 3
var bottom_y := 600.0

@onready var visual: Sprite2D = $Body


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_update_color()


func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y >= bottom_y:
		reached_bottom.emit()
		queue_free()


func hit(damage: int) -> void:
	hp -= damage
	if hp <= 0:
		died.emit()
		queue_free()
	else:
		_update_color()


func _update_color() -> void:
	var t := clampf(hp / float(max_hp), 0.0, 1.0)
	visual.modulate = Color.WHITE.lerp(Color(1.0, 0.4, 0.4), 1.0 - t)
