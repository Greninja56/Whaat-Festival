extends PanelContainer

const MIN_DB := -40.0
const MAX_DB := 20.0
const DEFAULT_VOLUME := 0.4
const BUSES := ["Master", "Music"]

@onready var sliders := {
	"Master": %MasterSlider,
	"Music": %MusicSlider,
}

func _ready() -> void:
	for bus in BUSES:
		var sl: HSlider = sliders[bus]
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.01
		sl.value_changed.connect(_apply.bind(bus))
	%SettingsBack.pressed.connect(close)
	_sync_sliders()
	visible = false

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	_sync_sliders()
	visible = true

func close() -> void:
	visible = false
	get_viewport().gui_release_focus()

func _apply(value: float, bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, lerpf(MIN_DB, MAX_DB, value))
	AudioServer.set_bus_mute(idx, value <= 0.001)

func _sync_sliders() -> void:
	for bus in BUSES:
		var idx := AudioServer.get_bus_index(bus)
		if idx == -1:
			continue
		var v := inverse_lerp(MIN_DB, MAX_DB, AudioServer.get_bus_volume_db(idx))
		(sliders[bus] as HSlider).set_value_no_signal(clampf(v, 0.0, 1.0))
