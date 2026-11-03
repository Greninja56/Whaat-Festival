extends Control

@export var game_scene: PackedScene   # drag your game scene here

const SETTINGS_PATH := "user://settings.cfg"
const LEADERBOARD_PATH := "user://leaderboard.json"

@onready var buttons: Control = %Buttons
@onready var panels: Array[Control] = [%LeaderPanel, %InstructionPanel, %SettingsPanel]
@onready var leaderboard_text: Label = %LeaderboardText
@onready var instructions_text: RichTextLabel = %InstructionsText
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider


func _ready() -> void:
	%Play.pressed.connect(_on_play)
	%Leaderboard.pressed.connect(_open.bind(%LeaderboardPanel))
	%Instructions.pressed.connect(_open.bind(%InstructionsPanel))
	%Settings.pressed.connect(_open.bind(%SettingsPanel))
	%LeaderboardBack.pressed.connect(_close)
	%InstructionsBack.pressed.connect(_close)
	%SettingsBack.pressed.connect(_close)

	master_slider.value_changed.connect(_on_volume_changed.bind("Master"))
	music_slider.value_changed.connect(_on_volume_changed.bind("Music"))

	instructions_text.bbcode_enabled = true
	instructions_text.text = _instructions()
	_load_settings()
	_close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not buttons.visible:
		_close()


func _on_play() -> void:
	get_tree().change_scene_to_packed(game_scene)


func _open(panel: Control) -> void:
	buttons.visible = false
	for p in panels:
		p.visible = (p == panel)
	if panel == %LeaderboardPanel:
		leaderboard_text.text = _leaderboard()
	# give keyboard/controller focus to the panel's back button
	var back := panel.find_child("*Back", true, false) as Button
	if back:
		back.grab_focus()


func _close() -> void:
	for p in panels:
		p.visible = false
	buttons.visible = true
	%Play.grab_focus()

# ---- Leaderboard ----
func _leaderboard() -> String:
	var lines: Array[String] = ["HIGH SCORES", ""]
	var data = null
	if FileAccess.file_exists(LEADERBOARD_PATH):
		var f := FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
		data = JSON.parse_string(f.get_as_text())
	if data is Array and not data.is_empty():
		for i in data.size():
			lines.append("%d. %s   %d" % [i + 1, data[i]["name"], int(data[i]["score"])])
	else:
		lines.append("No scores yet")
	return "\n".join(lines)


# ---- Settings ----
func _on_volume_changed(value: float, bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	AudioServer.set_bus_mute(idx, value <= 0.001)
	_save_settings()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)   # fine if the file doesn't exist yet
	master_slider.set_value_no_signal(cfg.get_value("audio", "Master", 1.0))
	music_slider.set_value_no_signal(cfg.get_value("audio", "Music", 1.0))
	_on_volume_changed(master_slider.value, "Master")
	_on_volume_changed(music_slider.value, "Music")


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "Master", master_slider.value)
	cfg.set_value("audio", "Music", music_slider.value)
	cfg.save(SETTINGS_PATH)


# ---- Instructions ----
func _instructions() -> String:
	return "\n".join([
		"[b]CONTROLS[/b]",
		"Aim: tilt the controller (or left/right arrows)",
		"Fire: [your fire key]    Reload: R",
		"Switch ammo: 1 / 2    Sonar: [your sonar key]",
		"Launch mini ship: [your launch key]",
		"",
		"[b]AMMO[/b]",
		"Standard is fast. Heavy breaks shields.",
		"",
		"[b]PROBLEMS[/b]",
		"[color=red]Red[/color]: gun overheating (slow fire)",
		"[color=cyan]Blue[/color]: power failure (HUD offline)",
		"[color=green]Green[/color]: oxygen leak (lose health)",
		"[color=yellow]Yellow[/color]: hangar offline",
		"White: shield failure (more damage taken)",
		"",
		"Shoot the heal ship to restore health.",
		"Cloaked enemies need sonar to be seen.",
	])
