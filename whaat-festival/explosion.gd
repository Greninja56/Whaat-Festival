class_name Explosion
extends CPUParticles2D

var size := 1.0
var tint := Color(1.0, 0.6, 0.2)

static func spawn(parent: Node, pos: Vector2, p_size := 1.0, p_tint := Color(1.0, 0.6, 0.2)) -> void:
	if not is_instance_valid(parent):
		return
	var e := Explosion.new()
	e.size = p_size
	e.tint = p_tint
	e.position = pos
	parent.add_child(e)
	e.global_position = pos

func _ready() -> void:
	one_shot = true
	explosiveness = 1.0
	amount = int(10.0 * size) + 4
	lifetime = 0.35 + 0.15 * size
	direction = Vector2.UP
	spread = 180.0
	gravity = Vector2.ZERO
	initial_velocity_min = 40.0 * size
	initial_velocity_max = 130.0 * size
	damping_min = 60.0
	damping_max = 110.0
	scale_amount_min = 1.5 * size
	scale_amount_max = 4.0 * size
	z_index = 5

	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 0.9, 1.0))           # white-hot core
	ramp.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))  # fades out in the tint color
	ramp.add_point(0.3, tint)
	color_ramp = ramp

	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m

	emitting = true
	finished.connect(queue_free)
