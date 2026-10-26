class_name Enemy
extends Area2D

signal died(value: int)
signal reached_bottom

@export var max_hp := 3
@export var speed := 40.0
@export var bottom_y := 600.0
@export var damaged_color := Color(1.0, 0.4, 0.4)

@onready var hp : float = max_hp
@onready var visual: Sprite2D = $Body
var currency_value := 10


func _ready() -> void:
	_update_color()


func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y >= bottom_y:
		reached_bottom.emit()
		queue_free()


func hit(damage: float) -> void:
	if hp <= 0:
		return
	hp -= damage
	if hp <= 0:
		died.emit(currency_value)
		queue_free()
	else:
		_update_color()


# Called by radar shots. Does nothing for normal enemies.
func reveal() -> void:
	pass


func _update_color() -> void:
	var t := clampf(hp / float(max_hp), 0.0, 1.0)
	visual.modulate = Color.WHITE.lerp(damaged_color, 1.0 - t)
