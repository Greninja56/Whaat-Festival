class_name SonarShot
extends Area2D

@export var lifetime := 3.5
@export var pierce := true

const OFFSCREEN_MARGIN := 100.0

var velocity := Vector2.ZERO
var age := 0.0

func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += velocity * delta
	age += delta
	if age >= lifetime or not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		(area as Enemy).reveal()
		if not pierce:
			queue_free()
