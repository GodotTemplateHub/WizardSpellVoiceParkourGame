# rebind_button.gd
extends Button
class_name RebindButton

## The action this button is responsible for rebinding
@export var action_name: String = ""
## Reference to the input manager (set automatically if it's an autoload)
@export var input_manager: InputMappingManager

## Visual feedback
var original_text: String = ""
var is_listening: bool = false

func _ready() -> void:
	
	# Connect signals
	input_manager.rebind_started.connect(_on_rebind_started)
	input_manager.rebind_finished.connect(_on_rebind_finished)
	input_manager.rebind_canceled.connect(_on_rebind_canceled)
	
	# Connect button press
	pressed.connect(_on_button_pressed)
	
	# Set initial text
	_update_button_text()

func _on_button_pressed() -> void:
	if not is_listening:
		input_manager.start_listen_for_rebind(action_name)

func _on_rebind_started(action: String) -> void:
	if action == action_name:
		is_listening = true
		original_text = text
		text = "Press any key... (ESC to cancel)"
		disabled = false

func _on_rebind_finished(action: String, event: InputEvent) -> void:
	if action == action_name:
		is_listening = false
		disabled = false
		_update_button_text()
		# Auto-save the new binding
		input_manager.save_bindings()

func _on_rebind_canceled(action: String) -> void:
	if action == action_name:
		is_listening = false
		disabled = false
		_update_button_text()

func _update_button_text() -> void:
	if action_name == "":
		text = "None"
		return
	
	var display_string: String = input_manager.get_action_display_string(action_name)
	text = "%s" % [display_string]

# Optional: Allow right-click to reset to default
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		input_manager.reset_action_to_default(action_name)
		input_manager.save_bindings()
		_update_button_text()
		accept_event()
