class_name FuelTrail
extends CPUParticles2D

@export var trail_color := Color(1.0, 0.6, 0.2)
@export var trail_size := 4.0
@export var trail_time := 0.4

static func attach(ship: Node2D, dir: Vector2, offset: Vector2, p_color: Color, p_size: float) -> FuelTrail:
	var t := FuelTrail.new()
	t.direction = dir
	t.position = offset
	t.trail_color = p_color
	t.trail_size = p_size
	ship.add_child(t)
	return t

func _ready() -> void:
	local_coords = false
	show_behind_parent = true
	amount = 20
	lifetime = trail_time
	spread = 12.0
	gravity = Vector2.ZERO
	initial_velocity_min = 15.0
	initial_velocity_max = 35.0
	scale_amount_min = trail_size * 0.6
	scale_amount_max = trail_size

	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	scale_amount_curve = shrink

	var fade := Gradient.new()
	fade.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.9))
	fade.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	color_ramp = fade

	emitting = true
