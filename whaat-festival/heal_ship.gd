class_name HealShip
extends Area2D

signal collected(amount: int)

@export var speed := 300.0
@export var max_hp := 2.0
@export var heal_amount := 10

var hp := 0.0
var right_x := 1200.0   # set by main so it knows where the screen ends


func _ready() -> void:
	hp = max_hp
	add_to_group("heal_ships")


func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x >= right_x:
		queue_free()


func hit(damage: float) -> void:
	if hp <= 0.0:
		return
	hp -= damage
	if hp <= 0.0:
		collected.emit(heal_amount)
		queue_free()
