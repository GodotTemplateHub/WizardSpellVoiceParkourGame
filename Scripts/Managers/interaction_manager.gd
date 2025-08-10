extends Node
class_name InteractionManager

@export var disable_player_interaction : bool
@export var interaction_action = "interact"
var detected_interaction : Interaction = null

func _on_area_3d_body_entered(body: StaticBody3D) -> void:
	if !is_interaction(body): return	
	detected_interaction = body.get_node("Interaction")
	detected_interaction.on_look_at()

func _on_area_3d_body_exited(body: StaticBody3D) -> void:
	if !is_interaction(body): return	
	detected_interaction.on_look_off()
	detected_interaction = null
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(interaction_action) and !disable_player_interaction:
		if detected_interaction:
			detected_interaction.on_interact()

func is_interaction(body: StaticBody3D) -> bool:
	if body:
		if body.get_node("Interaction"):
			return true
		else:
			return false
	else:
		return false
