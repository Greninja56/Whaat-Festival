extends Control

const LEADERBOARD_PATH := "user://leaderboard.json"

@onready var buttons: Control = %Buttons
@onready var panels: Array[Control] = [%LeaderPanel, %SettingsPanel]
@onready var leaderboard_text: Label = %LeaderboardText
@onready var pictures: Control = %Pictures
var starting := false
@export var min_db := -40.0   # slider at 0 (silent below this)
@export var max_db := 20.0     # slider at 1 (buses can go above 0 dB)

func _ready() -> void:
	%PlayButton.pressed.connect(_on_play)
	%LeaderboardButton.pressed.connect(_open.bind(%LeaderPanel))
	%SettingsButton.pressed.connect(_open.bind(%SettingsPanel))
	%LeaderboardBack.pressed.connect(_close)
	_close()
	%SettingsPanel.visibility_changed.connect(func() -> void:
		if not %SettingsPanel.visible and not buttons.visible:
			_close())
	for bus in ["Master", "Music"]:
		var idx := AudioServer.get_bus_index(bus)
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, lerpf(-40.0, 6.0, 0.5))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not buttons.visible:
		_close()


func _on_play() -> void:
	if starting:
		return
	starting = true

	var layer := CanvasLayer.new()
	layer.layer = 100                      # above everything
	add_child(layer)

	var boot := BootSequence.new()
	layer.add_child(boot)
	boot.position = Vector2.ZERO
	boot.size = get_viewport_rect().size   # don't rely on anchors
	var fade := create_tween()
	fade.tween_property(%Music, "volume_db", -40.0, 4.0)
	await boot.run()
	Esp.send("START")
	get_tree().change_scene_to_file("res://main.tscn")

func _open(panel: Control) -> void:
	buttons.visible = false
	pictures.visible = false
	for p in panels:
		p.visible = (p == panel)
	if panel == %LeaderPanel:
		leaderboard_text.text = _leaderboard()


func _close() -> void:
	for p in panels:
		p.visible = false
	buttons.visible = true
	pictures.visible = true

# ---- Leaderboard ----
func _leaderboard() -> String:
	var lines: Array[String] = []
	var data = null
	if FileAccess.file_exists(LEADERBOARD_PATH):
		var f := FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
		data = JSON.parse_string(f.get_as_text())
	if not data is Array:
		data = []
	for i in 10:
		if i < data.size():
			lines.append("%2d.  %-8s  %d" % [i + 1, data[i]["name"], int(data[i]["score"])])
		else:
			lines.append("%2d.  --------  0" % [i + 1])
	return "\n".join(lines)
