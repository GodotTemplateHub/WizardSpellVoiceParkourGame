# enhanced_input_mapping_manager.gd
extends Node
class_name InputMappingManager

## Public signals
signal rebind_started(action: String)
signal rebind_finished(action: String, event: InputEvent)
signal rebind_canceled(action: String)
signal bindings_reset()

## Configure your actions + defaults here
var default_bindings: Dictionary = {
	"move_left":  { "type": "key", "physical_keycode": KEY_A },
	"move_right": { "type": "key", "physical_keycode": KEY_D },
	"move_up":    { "type": "key", "physical_keycode": KEY_W },
	"move_down":  { "type": "key", "physical_keycode": KEY_S },
	"jump":       { "type": "key", "physical_keycode": KEY_SPACE },
	"shoot":      { "type": "mouse_button", "button_index": MOUSE_BUTTON_LEFT },
	"aim":        { "type": "mouse_button", "button_index": MOUSE_BUTTON_RIGHT },
	"interact":   { "type": "key", "physical_keycode": KEY_E },
	"inventory":  { "type": "key", "physical_keycode": KEY_I },
	"pause":      { "type": "key", "physical_keycode": KEY_ESCAPE }
}

## Actions that cannot be rebound (for safety)
var protected_actions: Array[String] = ["pause", "quit_game"]

var _listening_action: String = ""
var _save_path: String = "user://input_bindings.json"
var _max_events_per_action: int = 2

func _ready() -> void:
	apply_defaults_if_missing()
	load_bindings()

# --- API -----------------------------------------------------------
func start_listen_for_rebind(action: String) -> void:
	if not InputMap.has_action(action):
		push_warning("Action '%s' does not exist." % action)
		return
	
	if action in protected_actions:
		push_warning("Action '%s' is protected and cannot be rebound." % action)
		return
		
	_listening_action = action
	set_process_unhandled_input(true)
	emit_signal("rebind_started", action)

func cancel_listen() -> void:
	if _listening_action != "":
		var a: String = _listening_action
		_listening_action = ""
		set_process_unhandled_input(false)
		emit_signal("rebind_canceled", a)

func rebind_action(action: String, event: InputEvent, replace_all: bool = true) -> bool:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	
	# Check for conflicts with other actions
	var conflict: String = find_conflicting_action(event, action)
	if conflict != "":
		push_warning("Event already bound to action: %s" % conflict)
		return false
	
	if replace_all:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
	else:
		# Add as additional binding (up to max limit)
		var current_events: Array[InputEvent] = InputMap.action_get_events(action)
		if current_events.size() >= _max_events_per_action:
			push_warning("Maximum number of bindings reached for action: %s" % action)
			return false
		InputMap.action_add_event(action, event)
	
	emit_signal("rebind_finished", action, event)
	return true

func remove_binding(action: String, event: InputEvent) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_event(action, event)

func get_action_events(action: String) -> Array[InputEvent]:
	if InputMap.has_action(action):
		return InputMap.action_get_events(action)
	return []

func get_action_display_string(action: String) -> String:
	var events: Array[InputEvent] = get_action_events(action)
	if events.is_empty():
		return "Unbound"
	
	var strings: Array[String] = []
	for event in events:
		strings.append(_event_to_display_string(event))
	
	return " / ".join(strings)

func find_conflicting_action(event: InputEvent, exclude_action: String = "") -> String:
	for action in InputMap.get_actions():
		if action == exclude_action or action.begins_with("ui_"):
			continue
		
		for existing_event in InputMap.action_get_events(action):
			if _events_match(event, existing_event):
				return action
	return ""

func reset_to_defaults() -> void:
	# Clear all current bindings
	for action in InputMap.get_actions():
		if not action.begins_with("ui_"):
			InputMap.action_erase_events(action)
	
	# Reapply defaults
	apply_defaults_if_missing()
	emit_signal("bindings_reset")

func reset_action_to_default(action: String) -> void:
	if action in default_bindings:
		InputMap.action_erase_events(action)
		var ev: InputEvent = _event_from_dict(default_bindings[action])
		if ev != null:
			InputMap.action_add_event(action, ev)

# --- Input capture -----------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _listening_action == "":
		return

	# Allow ESC to cancel rebinding
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		cancel_listen()
		get_viewport().set_input_as_handled()
		return

	var captured: InputEvent = _pick_rebindable_event(event)
	if captured == null:
		return

	if rebind_action(_listening_action, captured):
		_listening_action = ""
		set_process_unhandled_input(false)
	
	get_viewport().set_input_as_handled()

func _pick_rebindable_event(event: InputEvent) -> InputEvent:
	# Keys
	if event is InputEventKey and event.pressed and not event.echo:
		var e: InputEventKey = InputEventKey.new()
		e.physical_keycode = event.physical_keycode
		e.shift_pressed = event.shift_pressed
		e.alt_pressed = event.alt_pressed
		e.ctrl_pressed = event.ctrl_pressed
		e.meta_pressed = event.meta_pressed
		return e

	# Mouse buttons
	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = InputEventMouseButton.new()
		mb.button_index = event.button_index
		return mb

	# Joypad buttons
	if event is InputEventJoypadButton and event.pressed:
		var jb: InputEventJoypadButton = InputEventJoypadButton.new()
		jb.button_index = event.button_index
		jb.device = event.device
		return jb

	# Joypad axes (for triggers/analog sticks)
	if event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		var jm: InputEventJoypadMotion = InputEventJoypadMotion.new()
		jm.axis = event.axis
		jm.axis_value = sign(event.axis_value)
		jm.device = event.device
		return jm

	return null

# --- Defaults and validation ------------------------------------------------

func apply_defaults_if_missing() -> void:
	for action in default_bindings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var ev: InputEvent = _event_from_dict(default_bindings[action])
			if ev != null:
				InputMap.action_add_event(action, ev)

# --- Save / Load ------------------------------------------------------------

func save_bindings(path: String = _save_path) -> bool:
	var data: Dictionary = {}
	for action in InputMap.get_actions():
		if not action.begins_with("ui_"):  # Skip built-in UI actions
			var events: Array[InputEvent] = get_action_events(action)
			if not events.is_empty():
				data[action] = []
				for event in events:
					var event_dict: Dictionary = _event_to_dict(event)
					if not event_dict.is_empty():
						data[action].append(event_dict)

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		return true
	else:
		push_error("Failed to save bindings to %s" % path)
		return false

func load_bindings(path: String = _save_path) -> bool:
	if not FileAccess.file_exists(path):
		return false
		
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open %s for reading" % path)
		return false

	var txt: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid bindings file format")
		return false

	# Apply loaded bindings
	for action in parsed.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		InputMap.action_erase_events(action)
		var events_data: Variant = parsed[action]
		
		if typeof(events_data) == TYPE_ARRAY:
			# New format: multiple events per action
			for event_dict in events_data:
				var ev: InputEvent = _event_from_dict(event_dict)
				if ev != null:
					InputMap.action_add_event(action, ev)
		else:
			# Legacy format: single event per action
			var ev: InputEvent = _event_from_dict(events_data)
			if ev != null:
				InputMap.action_add_event(action, ev)

	return true

# --- Helpers ----------------------------------------------------------------

func _events_match(event1: InputEvent, event2: InputEvent) -> bool:
	if event1.get_class() != event2.get_class():
		return false
	
	if event1 is InputEventKey and event2 is InputEventKey:
		return (event1.physical_keycode == event2.physical_keycode and
				event1.shift_pressed == event2.shift_pressed and
				event1.alt_pressed == event2.alt_pressed and
				event1.ctrl_pressed == event2.ctrl_pressed and
				event1.meta_pressed == event2.meta_pressed)
	
	if event1 is InputEventMouseButton and event2 is InputEventMouseButton:
		return event1.button_index == event2.button_index
	
	if event1 is InputEventJoypadButton and event2 is InputEventJoypadButton:
		return (event1.button_index == event2.button_index and
				event1.device == event2.device)
	
	if event1 is InputEventJoypadMotion and event2 is InputEventJoypadMotion:
		return (event1.axis == event2.axis and
				sign(event1.axis_value) == sign(event2.axis_value) and
				event1.device == event2.device)
	
	return false

func _event_to_display_string(event: InputEvent) -> String:
	if event is InputEventKey:
		var modifiers: Array[String] = []
		if event.ctrl_pressed: modifiers.append("Ctrl")
		if event.alt_pressed: modifiers.append("Alt")
		if event.shift_pressed: modifiers.append("Shift")
		if event.meta_pressed: modifiers.append("Meta")
		
		var key_name: String = OS.get_keycode_string(event.physical_keycode)
		if not modifiers.is_empty():
			return "+".join(modifiers) + "+" + key_name
		return key_name
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
			_: return "Mouse %d" % event.button_index
	
	if event is InputEventJoypadButton:
		return "Joy Button %d" % event.button_index
	
	if event is InputEventJoypadMotion:
		var direction: String = "+" if event.axis_value > 0 else "-"
		return "Joy Axis %d%s" % [event.axis, direction]
	
	return "Unknown"

func _event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"physical_keycode": event.physical_keycode,
			"shift": event.shift_pressed,
			"alt": event.alt_pressed,
			"ctrl": event.ctrl_pressed,
			"meta": event.meta_pressed
		}
	if event is InputEventMouseButton:
		return {
			"type": "mouse_button",
			"button_index": event.button_index
		}
	if event is InputEventJoypadButton:
		return {
			"type": "joy_button",
			"button_index": event.button_index,
			"device": event.device
		}
	if event is InputEventJoypadMotion:
		return {
			"type": "joy_motion",
			"axis": event.axis,
			"axis_value": event.axis_value,
			"device": event.device
		}
	return {}

func _event_from_dict(d: Dictionary) -> InputEvent:
	if not d.has("type"):
		return null

	match String(d.type):
		"key":
			var e: InputEventKey = InputEventKey.new()
			e.physical_keycode = int(d.get("physical_keycode", KEY_NONE))
			e.shift_pressed = bool(d.get("shift", false))
			e.alt_pressed = bool(d.get("alt", false))
			e.ctrl_pressed = bool(d.get("ctrl", false))
			e.meta_pressed = bool(d.get("meta", false))
			return e
		"mouse_button":
			var mb: InputEventMouseButton = InputEventMouseButton.new()
			mb.button_index = int(d.get("button_index", MOUSE_BUTTON_LEFT))
			return mb
		"joy_button":
			var jb: InputEventJoypadButton = InputEventJoypadButton.new()
			jb.button_index = int(d.get("button_index", 0))
			jb.device = int(d.get("device", 0))
			return jb
		"joy_motion":
			var jm: InputEventJoypadMotion = InputEventJoypadMotion.new()
			jm.axis = int(d.get("axis", 0))
			jm.axis_value = float(d.get("axis_value", 0.0))
			jm.device = int(d.get("device", 0))
			return jm
		_:
			return null
