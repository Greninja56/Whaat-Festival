extends PanelContainer

const MIN_DB := -40.0   # keep these the same as your menu's min_db / max_db
const MAX_DB := 20.0

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider


func _ready() -> void:
	for pair in [[master_slider, "Master"], [music_slider, "Music"]]:
		var sl: HSlider = pair[0]
		var bus: String = pair[1]
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.01
		# start where the bus actually is (the menu may have changed it)
		var idx := AudioServer.get_bus_index(bus)
		if idx != -1:
			var v := inverse_lerp(MIN_DB, MAX_DB, AudioServer.get_bus_volume_db(idx))
			sl.set_value_no_signal(clampf(v, 0.0, 1.0))
		sl.value_changed.connect(_apply.bind(bus))
	%SettingsBack.pressed.connect(close)
	visible = false


func _apply(value: float, bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, lerpf(MIN_DB, MAX_DB, value))
	AudioServer.set_bus_mute(idx, value <= 0.001)


func toggle() -> void:
	print("toggle, visible = ", visible, " pos = ", global_position, " size = ", size)
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true

func close() -> void:
	visible = false
	get_viewport().gui_release_focus()
