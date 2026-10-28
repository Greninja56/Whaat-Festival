class_name SonarShot
extends Area2D

@export var lifetime := 3.5
@export var pierce := true  # keep flying and reveal everything along the path

var velocity := Vector2.ZERO


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta: float) -> void:
	position += velocity * delta


func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		area.reveal()
		if not pierce:
			queue_free()
