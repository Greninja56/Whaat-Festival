class_name HeavyEnemy
extends Enemy

func _ready() -> void:
	trail_size = 30.0
	trail_offset = Vector2(0, -100)
	trail_color = Color(0.958, 0.383, 0.0, 1.0)
	explosion_size = 3.0
	super._ready()
	max_hp = 8
	speed = 25.0
	trail.amount = 8                    # fewer particles so they don't pile up
	trail.lifetime = 0.7                # longer life, so they spread further along the trail
	trail.initial_velocity_min = 40.0   # push them away from the ship faster
	trail.initial_velocity_max = 70.0
	trail.spread = 6.0                  # tighter cone, so it reads as a stream
