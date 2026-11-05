class_name Enemy
extends Area2D

signal died(value: float, pos: Vector2)
signal reached_bottom
signal shield_broken

@export_group("Stats")
@export var max_hp := 3
@export var speed := 40.0
@export var bottom_y := 600.0
@export var currency_value := 1.0
@export var explosion_size := 1.5

@export_group("Look")
@export var damaged_color := Color(1.0, 0.4, 0.4)
@export var trail_color := Color(0.942, 0.0, 0.186, 1.0)
@export var trail_size := 5.0
@export var trail_offset := Vector2(1, -24)

@export_group("Shield")
@export var shield_radius := 32.0
@export var shield_color := Color(0.3, 0.8, 1.0)

var hp := 0.0
var shield_hp := 0.0
var max_shield := 0.0
var trail: FuelTrail

@onready var visual: Sprite2D = $Body

func _ready() -> void:
	hp = max_hp
	trail = FuelTrail.attach(self, Vector2.UP, trail_offset, trail_color, trail_size)
	_update_color()

func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y >= bottom_y:
		Explosion.spawn(get_tree().current_scene, global_position, 2.0, Color(1.0, 0.25, 0.15))
		reached_bottom.emit()
		queue_free()

func hit(damage: float, shield_damage: float = 0.0) -> void:
	if hp <= 0:
		return
	if shield_hp > 0.0:
		shield_hp = maxf(shield_hp - shield_damage, 0.0)
		queue_redraw()
		if shield_hp <= 0.0:
			shield_broken.emit()
		return
	hp -= damage
	if hp <= 0:
		Explosion.spawn(get_tree().current_scene, global_position, explosion_size)
		died.emit(currency_value, global_position)
		queue_free()
	else:
		_update_color()

func reveal() -> void:
	pass

func set_shield(amount: float) -> void:
	max_shield = amount
	shield_hp = amount
	queue_redraw()

func _draw() -> void:
	if shield_hp <= 0.0:
		return
	var frac := shield_hp / max_shield
	var c := shield_color
	c.a = lerpf(0.4, 1.0, frac)
	draw_circle(Vector2.ZERO, shield_radius, Color(c.r, c.g, c.b, 0.15))
	draw_arc(Vector2.ZERO, shield_radius, 0.0, TAU, 32, c, 2.0)


func _update_color() -> void:
	var t := clampf(hp / float(max_hp), 0.0, 1.0)
	visual.modulate = Color.WHITE.lerp(damaged_color, 1.0 - t)
