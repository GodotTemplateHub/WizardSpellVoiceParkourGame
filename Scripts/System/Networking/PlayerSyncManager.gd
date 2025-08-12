extends Node
@onready var camera = $"../Head/Camera3D"

## INFO: Here is all the other things that need to be synced, other then movement
@onready var char_1: MeshInstance3D = $"../PlayerBaseModel/Armature/Skeleton3D/char1"
@export var player_health_bar_showing : EntityHealthBar

func _ready():
	camera.current = is_multiplayer_authority()
	player_health_bar_showing.visible = !is_multiplayer_authority()
	if is_multiplayer_authority(): char_1.layers = 2
	
