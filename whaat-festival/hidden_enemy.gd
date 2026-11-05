class_name CloakedEnemy
extends Enemy

@export var cloaked_alpha := 0.0
@export var reveal_fade_time := 0.3

var revealed := false
var reveal_tween: Tween

@onready var reveal_sound: AudioStreamPlayer2D = %Reveal

func _ready() -> void:
	trail_color = Color(0.821, 0.367, 0.984, 1.0)
	super._ready()
	_apply_visibility()

func reveal() -> void:
	if not revealed:
		revealed = true
		trail.visible = true
		reveal_sound.play()
		_fade_to(1.0)

func _apply_visibility() -> void:
	visual.self_modulate.a = 1.0 if revealed else cloaked_alpha
	trail.visible = revealed

func _fade_to(alpha: float) -> void:
	if reveal_tween:
		reveal_tween.kill()
	reveal_tween = create_tween()
	reveal_tween.tween_property(visual, "self_modulate:a", alpha, reveal_fade_time)
