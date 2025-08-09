extends CanvasLayer
class_name PlayerUIManager

@export var resume_button: Button
@export var quit_button: Button

@export var pause_ui : Control

var is_paused: bool = false

func _ready() -> void:
	# Connect buttons
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		
	pause_ui.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	if is_paused:
		unpause()
	else:
		pause()

func pause() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_ui.show()

func unpause() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_ui.hide()

func _on_resume_pressed() -> void:
	unpause()

func _on_quit_pressed() -> void:
	get_tree().quit()
