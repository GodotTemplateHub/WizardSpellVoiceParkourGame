# simple_proximity_chat.gd
extends Node
class_name ProximityChatManager

@export var audio_player_3d: AudioStreamPlayer3D
@export var settings_manager: SettingsManager
@export var push_to_talk_action: String = "voice_chat"
@export var mic_transmitting_icon: Control
@export var mic_muted_icon: Control

var is_transmitting: bool = false
var push_to_talk_held: bool = false

func _ready() -> void:
	# Setup microphone input
	_setup_microphone()
	
	# Initialize voice transmission state
	_initialize_voice_transmission()
	
	# Set process mode for input handling
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize icon states
	_update_mic_icons()

func _input(event: InputEvent) -> void:
	if not settings_manager:
		return
	
	# Check if push-to-talk is enabled
	var enable_push_to_talk: bool = settings_manager.get_push_to_talk_enabled()
	
	if not enable_push_to_talk:
		return
	
	if event.is_action_pressed(push_to_talk_action):
		push_to_talk_held = true
		_update_voice_transmission()
	elif event.is_action_released(push_to_talk_action):
		push_to_talk_held = false
		_update_voice_transmission()

func _setup_microphone() -> void:
	if not audio_player_3d:
		print("ERROR: No AudioStreamPlayer3D assigned!")
		return
	
	# Setup microphone stream
	var mic_stream: AudioStreamMicrophone = AudioStreamMicrophone.new()
	audio_player_3d.stream = mic_stream
	audio_player_3d.bus = "Voice"
	
	print("Microphone connected to AudioStreamPlayer3D")

func _initialize_voice_transmission() -> void:
	# Wait for settings to load
	await get_tree().create_timer(0.5).timeout
	
	if not settings_manager:
		print("No settings manager - defaulting to push-to-talk")
		return
	
	var enable_push_to_talk: bool = settings_manager.get_push_to_talk_enabled()
	
	if not enable_push_to_talk:
		# Always-on mode
		start_voice_transmission()
		print("Always-on voice mode enabled")
	else:
		print("Push-to-talk mode enabled (Press V to talk)")

func _update_voice_transmission() -> void:
	if not settings_manager:
		return
	
	var should_transmit: bool = false
	var enable_push_to_talk: bool = settings_manager.get_push_to_talk_enabled()
	
	if enable_push_to_talk:
		should_transmit = push_to_talk_held
	else:
		should_transmit = true  # Always on
	
	if should_transmit and not is_transmitting:
		start_voice_transmission()
	elif not should_transmit and is_transmitting:
		stop_voice_transmission()

func start_voice_transmission() -> void:
	if not audio_player_3d:
		return
	
	is_transmitting = true
	audio_player_3d.play()
	_update_mic_icons()
	print("Voice transmission started")

func stop_voice_transmission() -> void:
	if not audio_player_3d:
		return
	
	is_transmitting = false
	audio_player_3d.stop()
	_update_mic_icons()
	print("Voice transmission stopped")

func _update_mic_icons() -> void:
	if mic_transmitting_icon:
		mic_transmitting_icon.visible = is_transmitting
	
	if mic_muted_icon:
		mic_muted_icon.visible = not is_transmitting
