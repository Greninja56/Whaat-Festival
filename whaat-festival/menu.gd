extends Control

const LEADERBOARD_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10
const GAME_PATH := "res://main.tscn"

@onready var buttons: Control = %Buttons
@onready var panels: Array[Control] = [%LeaderPanel, %SettingsPanel]
@onready var leaderboard_text: Label = %LeaderboardText
@onready var pictures: Control = %Pictures

var starting := false

func _ready() -> void:
	%PlayButton.pressed.connect(_on_play)
	%LeaderboardButton.pressed.connect(_open.bind(%LeaderPanel))
	%SettingsButton.pressed.connect(_open.bind(%SettingsPanel))
	%LeaderboardBack.pressed.connect(_close)
	%SettingsPanel.visibility_changed.connect(func() -> void:
		if not %SettingsPanel.visible and not buttons.visible:
			_close())
	_close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not buttons.visible:
		_close()

func _on_play() -> void:
	if starting:
		return
	starting = true

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var boot := BootSequence.new()
	layer.add_child(boot)
	boot.position = Vector2.ZERO
	boot.size = get_viewport_rect().size

	create_tween().tween_property(%Music, "volume_db", -40.0, 4.0)
	await boot.run()

	Esp.send("START")
	get_tree().change_scene_to_file(GAME_PATH)

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

func _leaderboard() -> String:
	var data: Array = []
	if FileAccess.file_exists(LEADERBOARD_PATH):
		var f := FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Array:
			data = parsed

	var lines: Array[String] = []
	for i in MAX_ENTRIES:
		if i < data.size() and data[i] is Dictionary:
			lines.append("%2d.  %-3s  %d" % [i + 1, str(data[i].get("name", "???")).left(3), int(data[i].get("score", 0))])
		else:
			lines.append("%2d.  ---  0" % [i + 1])
	return "\n".join(lines)
