extends Node
class_name SpectatorModeManager

@export var entity_stats_manager: EntityStatsManager
@export var nodes_to_hide: Array[Node] = []

var is_spectator_mode: bool = false

@export var spectator_nodes : Node3D
@export var alive_nodes : Node3D

@export var spectator_camera = preload("res://Scenes/spectator_camera.tscn")

func _ready() -> void:
	Console.add_command("spectate", func(): enter_spectator_mode())


func enter_spectator_mode():
	is_spectator_mode = true
	
