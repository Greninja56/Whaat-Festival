class_name CloakedEnemy
extends Enemy

@export var cloaked_alpha := 0.0
@export var reveal_fade_time := 0.3

@onready var reveal_sound: AudioStreamPlayer2D = %Reveal
var revealed := false


func _ready() -> void:
	trail_color = Color(0.821, 0.367, 0.984, 1.0)
	super._ready()
	_apply_visibility()
	
func _apply_visibility() -> void:
	visual.self_modulate.a = 1.0 if revealed else cloaked_alpha
	trail.visible = revealed


func reveal() -> void:
	if revealed:
		return
	revealed = true
	trail.visible = true
	reveal_sound.play()
	var tween := create_tween()
	tween.tween_property(visual, "self_modulate:a", 1.0, reveal_fade_time)
