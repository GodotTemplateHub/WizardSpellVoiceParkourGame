extends Node

# In your UI script
@export var state_label : Label
@export var timer_label : Label

@export var game_manager : GameManager

func _ready():
	game_manager.state_changed.connect(_on_state_changed)
	game_manager.state_timer_updated.connect(_on_timer_updated)
	
	if !game_manager.phase_system_enabled:
		timer_label.get_parent().hide()

func _on_state_changed(old_state, new_state):
	state_label.text = game_manager.get_current_state_name()

func _on_timer_updated(time_remaining):
	timer_label.text = game_manager.get_time_remaining_formatted()
