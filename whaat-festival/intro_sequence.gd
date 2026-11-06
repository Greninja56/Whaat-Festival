class_name BootSequence
extends ColorRect

@export var text_color := Color(0.3, 1.0, 0.4)
@export var font_size := 20
@export var final_hold := 2.5
@export var line_delay_min := 0.1
@export var line_delay_max := 0.8
@export var final_char_delay := 0.07
@export var blink_interval := 0.4

const FINAL_LINE := "CRUISER TURRET ONLINE"

var boot_lines: PackedStringArray = [
	"BIOS v2.4.1 .......................... OK",
	"CHECKING MEMORY ...................... OK",
	"MOUNTING /dev/hangar ................. OK",
	"LOADING KERNEL MODULES",
	"  > gyro_driver.ko",
	"  > sonar_array.ko",
	"  > ammo_feed.ko",
	"  > shield_gen.ko",
	"  > hangar_doors.ko",
	"INIT OXYGEN TANKS .................... OK",
	"INIT POWER GRID ...................... OK",
	"CALIBRATING GYROSCOPE ................ OK",
	"LINKING SONAR ARRAY .................. OK",
	"LOADING AMMO: STANDARD ............... OK",
	"LOADING AMMO: HEAVY .................. OK",
	"ARMING FIGHTER BAYS .................. OK",
	"SHIELD GENERATOR ONLINE .............. OK",
	"ENGINES RUNNING AT FULL CAPACITY ..... OK",
	"DISPLAY ACTIVATED .................... OK",
	"ALL SYSTEMS NOMINAL",
	"W.R.S RANKIN ARMED",
	"PREPARING JUMP TO LIGHTSPEED",
	"",
]

var label: Label
var skipped := false

func _ready() -> void:
	color = Color.BLACK
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "Menlo", "monospace"])

	label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 40
	label.offset_top = 30
	label.offset_right = -40
	label.offset_bottom = -30
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.clip_text = true
	add_child(label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		skipped = true
		get_viewport().set_input_as_handled()

func run() -> void:
	var body := ""
	for line in boot_lines:
		if skipped:
			return
		body += line + "\n"
		label.text = body + "_"
		await _wait(randf_range(line_delay_min, line_delay_max))
		if skipped:
			return

	for i in FINAL_LINE.length() + 1:
		if skipped:
			return
		label.text = body + FINAL_LINE.left(i) + "_"
		await _wait(final_char_delay)

	var t := 0.0
	var on := true
	while t < final_hold and not skipped:
		label.text = body + FINAL_LINE + ("_" if on else " ")
		on = not on
		await _wait(blink_interval)
		t += blink_interval

func _wait(seconds: float) -> void:
	if skipped:
		return
	await get_tree().create_timer(seconds).timeout
