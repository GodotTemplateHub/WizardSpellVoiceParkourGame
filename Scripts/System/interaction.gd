extends Node
class_name Interaction

@export var debug_mode : bool
@export var outline : Node3D

signal on_look_at_interaction
signal on_interaction_triggered

func _ready() -> void:
	outline.hide()
	get_parent().collision_layer = 3
	get_parent().collision_mask = 3 # bin: 11

func on_interact() -> void:
	on_interaction_triggered.emit()
	if debug_mode: print("Player Interacted With ", get_parent().name)

func on_look_at():
	on_look_at_interaction.emit()
	if outline:
		outline.show()

func on_look_off():
	if outline:
		outline.hide()
