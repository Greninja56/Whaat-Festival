class_name CloakedEnemy
extends Enemy

@export var cloaked_alpha := 0.0
@export var reveal_fade_time := 0.3

@onready var reveal_sound: AudioStreamPlayer2D = %Reveal
var revealed := false


func _ready() -> void:
	super._ready()
	_apply_visibility()


# cloaked_enemy.gd
func reveal() -> void:
	if revealed:
		return
	revealed = true
	reveal_sound.play()
	var tween := create_tween()
	tween.tween_property(visual, "self_modulate:a", 1.0, reveal_fade_time)


func _apply_visibility() -> void:
	visual.self_modulate.a = 1.0 if revealed else cloaked_alpha
