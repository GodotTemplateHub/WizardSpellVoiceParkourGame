# settings_manager.gd
extends Node
class_name SettingsManager

## UI References
@export var master_slider: HSlider
@export var sfx_slider: HSlider
@export var music_slider: HSlider
@export var microphone_slider: HSlider
@export var mute_checkbox: CheckBox
@export var microphone_dropdown: OptionButton
@export var push_to_talk_checkbox: CheckBox  # <-- This is the export for push-to-talk!

## Default values
var default_master_volume: float = 0.5
var default_sfx_volume: float = 0.5
var default_music_volume: float = 0.5
var default_microphone_volume: float = 0.5
var default_mute: bool = false
var default_microphone_index: int = 0
var default_push_to_talk: bool = true

var reduce_volume: float = 30

## Save file path
var save_path: String = "user://settings.json"

## Audio bus names
var master_bus	: String = "Master"
var sfx_bus		: String = "SFX"
var music_bus	: String = "Music"
var microphone_bus : String = "Voice"

func _ready() -> void:
	_populate_microphone_dropdown()
	_connect_ui_signals()
	load_settings()

func _populate_microphone_dropdown() -> void:
	# Store current selection
	var current_selection: int = microphone_dropdown.selected
	var current_text: String = ""
	if current_selection >= 0:
		current_text = microphone_dropdown.get_item_text(current_selection)
	
	microphone_dropdown.clear()
	var input_devices: PackedStringArray = AudioServer.get_input_device_list()
	
	print("Available microphones: ", input_devices)  # Debug output
	
	if input_devices.is_empty():
		microphone_dropdown.add_item("No microphones found")
		microphone_dropdown.disabled = true
		return
	
	# Add "Default" option first
	microphone_dropdown.add_item("Default")
	
	# Add all detected devices
	for i in range(input_devices.size()):
		microphone_dropdown.add_item(input_devices[i])
	
	# Try to restore previous selection
	if current_text != "":
		for i in range(microphone_dropdown.get_item_count()):
			if microphone_dropdown.get_item_text(i) == current_text:
				microphone_dropdown.selected = i
				break
	
	microphone_dropdown.disabled = false

func refresh_microphone_list() -> void:
	_populate_microphone_dropdown()

func _connect_ui_signals() -> void:
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if microphone_slider:
		microphone_slider.value_changed.connect(_on_microphone_volume_changed)
	if mute_checkbox:
		mute_checkbox.toggled.connect(_on_mute_toggled)
	if microphone_dropdown:
		microphone_dropdown.item_selected.connect(_on_microphone_selected)
	if push_to_talk_checkbox:
		push_to_talk_checkbox.toggled.connect(_on_push_to_talk_toggled)

func _on_master_volume_changed(value: float) -> void:
	_set_bus_volume(master_bus, value / reduce_volume)
	save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume(sfx_bus, value / reduce_volume)
	save_settings()

func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume(music_bus, value / reduce_volume)
	save_settings()

func _on_microphone_volume_changed(value: float) -> void:
	_set_bus_volume(microphone_bus, value / reduce_volume)
	save_settings()

func _on_mute_toggled(is_muted: bool) -> void:
	_set_master_mute(is_muted)
	save_settings()

func _on_microphone_selected(index: int) -> void:
	var input_devices: PackedStringArray = AudioServer.get_input_device_list()
	
	if index == 0:
		# "Default" option selected
		AudioServer.input_device = ""
		print("Microphone changed to: Default")
	elif index > 0 and (index - 1) < input_devices.size():
		# Subtract 1 because we added "Default" at index 0
		var device_name: String = input_devices[index - 1]
		AudioServer.input_device = device_name
		print("Microphone changed to: ", device_name)
	
	save_settings()

func _on_push_to_talk_toggled(is_enabled: bool) -> void:
	print("Push to talk: ", "Enabled" if is_enabled else "Disabled")
	save_settings()

func get_push_to_talk_enabled() -> bool:
	if push_to_talk_checkbox:
		return push_to_talk_checkbox.button_pressed
	return default_push_to_talk

func get_microphone_volume() -> float:
	if microphone_slider:
		return microphone_slider.value
	return default_microphone_volume

func get_selected_microphone() -> String:
	# Get the actual current device being used
	var current_device: String = AudioServer.input_device
	
	# If no specific device is set, get the system default
	if current_device == "":
		var input_devices: PackedStringArray = AudioServer.get_input_device_list()
		if input_devices.size() > 0:
			current_device = input_devices[0]  # First device is usually system default
		else:
			return "No microphones available"
	
	# Update dropdown to match current device
	if microphone_dropdown:
		for i in range(microphone_dropdown.get_item_count()):
			var item_text: String = microphone_dropdown.get_item_text(i)
			if item_text == current_device or (item_text == "Default" and current_device == ""):
				microphone_dropdown.selected = i
				break
	
	return current_device

func _set_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		# Convert linear volume (0-1) to decibels with a much quieter max
		# Map 0-1 to -80db to -30db (much more reasonable range)
		var min_db: float = -80.0
		var max_db: float = -30.0
		var db: float = min_db + (volume * (max_db - min_db))
		AudioServer.set_bus_volume_db(bus_index, db)

func _set_master_mute(is_muted: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(master_bus)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, is_muted)

func save_settings() -> void:
	var settings_data: Dictionary = {
		"master_volume": master_slider.value if master_slider else default_master_volume,
		"sfx_volume": sfx_slider.value if sfx_slider else default_sfx_volume,
		"music_volume": music_slider.value if music_slider else default_music_volume,
		"microphone_volume": microphone_slider.value if microphone_slider else default_microphone_volume,
		"mute": mute_checkbox.button_pressed if mute_checkbox else default_mute,
		"microphone_index": microphone_dropdown.selected if microphone_dropdown else default_microphone_index,
		"push_to_talk": push_to_talk_checkbox.button_pressed if push_to_talk_checkbox else default_push_to_talk
	}
	
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings_data))
		file.close()
		print("Settings saved")
	else:
		push_error("Failed to save settings")

func load_settings() -> void:
	if not FileAccess.file_exists(save_path):
		# No save file exists, apply defaults
		apply_defaults()
		return
	
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("Failed to load settings")
		apply_defaults()
		return
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var parsed_data: Variant = JSON.parse_string(json_text)
	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("Invalid settings file")
		apply_defaults()
		return
	
	var settings_data: Dictionary = parsed_data as Dictionary
	
	# Apply loaded settings
	var master_volume: float = settings_data.get("master_volume", default_master_volume)
	var sfx_volume: float = settings_data.get("sfx_volume", default_sfx_volume)
	var music_volume: float = settings_data.get("music_volume", default_music_volume)
	var microphone_volume: float = settings_data.get("microphone_volume", default_microphone_volume)
	var mute: bool = settings_data.get("mute", default_mute)
	var microphone_index: int = settings_data.get("microphone_index", default_microphone_index)
	var push_to_talk: bool = settings_data.get("push_to_talk", default_push_to_talk)
	
	# Update UI
	if master_slider:
		master_slider.value = master_volume
	if sfx_slider:
		sfx_slider.value = sfx_volume
	if music_slider:
		music_slider.value = music_volume
	if microphone_slider:
		microphone_slider.value = microphone_volume
	if mute_checkbox:
		mute_checkbox.button_pressed = mute
	if microphone_dropdown and microphone_index < microphone_dropdown.get_item_count():
		microphone_dropdown.selected = microphone_index
		_on_microphone_selected(microphone_index)
	if push_to_talk_checkbox:
		push_to_talk_checkbox.button_pressed = push_to_talk
	
	# Apply to audio system
	_set_bus_volume(master_bus, master_volume / reduce_volume)
	_set_bus_volume(sfx_bus, sfx_volume / reduce_volume)
	_set_bus_volume(music_bus, music_volume / reduce_volume)
	_set_bus_volume(microphone_bus, microphone_volume / reduce_volume)
	_set_master_mute(mute)
	
	print("Settings loaded")

func apply_defaults() -> void:
	# Update UI with defaults
	if master_slider:
		master_slider.value = default_master_volume
	if sfx_slider:
		sfx_slider.value = default_sfx_volume
	if music_slider:
		music_slider.value = default_music_volume
	if microphone_slider:
		microphone_slider.value = default_microphone_volume
	if mute_checkbox:
		mute_checkbox.button_pressed = default_mute
	if microphone_dropdown:
		microphone_dropdown.selected = default_microphone_index
	if push_to_talk_checkbox:
		push_to_talk_checkbox.button_pressed = default_push_to_talk
	
	# Apply defaults to audio system
	_set_bus_volume(master_bus, default_master_volume / reduce_volume)
	_set_bus_volume(sfx_bus, default_sfx_volume / reduce_volume)
	_set_bus_volume(music_bus, default_music_volume / reduce_volume)
	_set_bus_volume(microphone_bus, default_microphone_volume / reduce_volume)
	_set_master_mute(default_mute)
	
	print("Default settings applied")

func reset_to_defaults() -> void:
	apply_defaults()
	save_settings()
