class_name StarLayer
extends CPUParticles2D

@export var fall_speed := 30.0
@export var star_size := 1.5
@export var star_count := 60
@export var star_color := Color(1.0, 1.0, 1.0, 0.7)


func _ready() -> void:
	var size := get_viewport_rect().size
	position = Vector2(size.x * 0.5, -10.0)
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(size.x * 0.5, 1.0)
	direction = Vector2.DOWN
	spread = 0.0
	gravity = Vector2.ZERO
	initial_velocity_min = fall_speed
	initial_velocity_max = fall_speed
	lifetime = (size.y + 20.0) / fall_speed   # exactly one trip down the screen
	preprocess = lifetime                     # stars are already spread out at game start
	amount = star_count
	scale_amount_min = star_size * 0.5
	scale_amount_max = star_size
	color = star_color
	emitting = true
