class_name StarLayer
extends CPUParticles2D

@export var fall_speed := 30.0
@export var star_size := 1.5
@export var star_count := 60
@export var star_color := Color(1.0, 1.0, 1.0, 0.7)

const SPAWN_MARGIN := 10.0

func _ready() -> void:
	var view := get_viewport_rect().size
	var speed := maxf(fall_speed, 1.0)
	
	position = Vector2(view.x * 0.5, -SPAWN_MARGIN)
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(view.x * 0.5, 1.0)
	direction = Vector2.DOWN
	spread = 0.0
	gravity = Vector2.ZERO
	initial_velocity_min = speed
	initial_velocity_max = speed
	lifetime = (view.y + SPAWN_MARGIN * 2.0) / speed   # exactly one trip down the screen
	preprocess = lifetime                              # stars are already spread out at game start
	amount = star_count
	scale_amount_min = star_size * 0.5
	scale_amount_max = star_size
	color = star_color
	emitting = true
