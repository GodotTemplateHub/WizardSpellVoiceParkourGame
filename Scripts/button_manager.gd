# button_manager.gd
extends Node
class_name ButtonManager

@export var hover_sound: AudioStream
@export var press_sound: AudioStream
@export var hover_scale: float = 1.1
@export var audio_bus: String = "SFX"

var audio_player: AudioStreamPlayer
var managed_buttons: Array[Button] = []

func _ready() -> void:
	# Create audio player
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = audio_bus
	add_child(audio_player)
	
	# Auto-find all buttons
	_find_all_buttons()

func _find_all_buttons() -> void:
	var root: Node = get_tree().current_scene
	if not root:
		root = get_parent()
	_find_buttons_recursive(root)

func _find_buttons_recursive(node: Node) -> void:
	if node is Button:
		_setup_button(node as Button)
	
	for child in node.get_children():
		_find_buttons_recursive(child)

func _setup_button(button: Button) -> void:
	if button in managed_buttons:
		return
	
	managed_buttons.append(button)
	
	# Set pivot to center for scaling
	button.pivot_offset = button.size / 2
	
	button.mouse_entered.connect(_on_hover.bind(button))
	button.mouse_exited.connect(_on_unhover.bind(button))
	button.pressed.connect(_on_press)

func _on_hover(button: Button) -> void:
	if hover_sound:
		audio_player.stream = hover_sound
		audio_player.play()
	
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * hover_scale, 0.1)

func _on_unhover(button: Button) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)

func _on_press() -> void:
	if press_sound:
		audio_player.stream = press_sound
		audio_player.play()
