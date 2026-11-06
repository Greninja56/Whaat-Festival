class_name HeavyEnemy
extends Enemy


func _ready() -> void:
	trail_size = 30.0
	trail_offset = Vector2(0, -100)
	trail_color = Color(0.958, 0.383, 0.0, 1.0)
	explosion_size = 3.0
	shield_radius = 128.0
	super._ready()

	trail.amount = 8
	trail.lifetime = 0.7
	trail.initial_velocity_min = 40.0
	trail.initial_velocity_max = 70.0
	trail.spread = 6.0
