class_name HealShip
extends Area2D

signal collected(amount: int)

@export var speed := 275.0
@export var max_hp := 2.0
@export var heal_amount := 5
@export var heal_color := Color(0.4, 1.0, 0.5)

var hp := 0.0
var right_x := 1200.0

func _ready() -> void:
	hp = max_hp
	add_to_group("heal_ships")
	FuelTrail.attach(self, Vector2.LEFT, Vector2(-16, 0), heal_color, 8.0)

func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x >= right_x:
		queue_free()

func hit(damage: float, _shield_damage: float = 0.0) -> void:
	if hp <= 0.0:
		return
	hp -= damage
	if hp <= 0.0:
		Explosion.spawn(get_tree().current_scene, global_position, 1.5, heal_color)
		collected.emit(heal_amount)
		queue_free()
