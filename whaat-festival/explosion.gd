class_name Explosion
extends CPUParticles2D

var size := 1.0
var tint := Color(1.0, 0.6, 0.2)


# parent should be the main scene (or any node at the origin that isn't hidden)
static func spawn(parent: Node, pos: Vector2, size := 1.0, tint := Color(1.0, 0.6, 0.2)) -> void:
	var e := Explosion.new()
	e.size = size
	e.tint = tint
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
	ramp.set_color(0, Color(1.0, 1.0, 0.9, 1.0))        # white-hot core
	ramp.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))  # fades out in the tint color
	ramp.add_point(0.3, tint)
	color_ramp = ramp

	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m

	emitting = true
	get_tree().create_timer(lifetime + 0.2).timeout.connect(queue_free)
