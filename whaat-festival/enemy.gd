class_name Enemy
extends Area2D

signal died(value: int)
signal reached_bottom
signal shield_broken

@export var shield_radius := 32.0
@export var shield_color := Color(0.3, 0.8, 1.0)

var shield_hp := 0.0
var max_shield := 0.0

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


func hit(damage: float, shield_damage: float = 0.0) -> void:
	if hp <= 0:
		return
	if shield_hp > 0.0:
		# Shield soaks the whole hit; only shield_damage counts against it
		shield_hp = maxf(shield_hp - shield_damage, 0.0)
		queue_redraw()
		if shield_hp <= 0.0:
			shield_broken.emit()
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

func set_shield(amount: float) -> void:
	max_shield = amount
	shield_hp = amount


func _draw() -> void:
	if shield_hp <= 0.0:
		return
	var frac := shield_hp / max_shield
	var c := shield_color
	c.a = lerpf(0.4, 1.0, frac)   # shield fades as it weakens
	draw_circle(Vector2.ZERO, shield_radius, Color(c.r, c.g, c.b, 0.15))
	draw_arc(Vector2.ZERO, shield_radius, 0.0, TAU, 32, c, 2.0)

func _update_color() -> void:
	var t := clampf(hp / float(max_hp), 0.0, 1.0)
	visual.modulate = Color.WHITE.lerp(damaged_color, 1.0 - t)
