extends Node
class_name ClimbingManager

signal started_climbing
signal stopped_climbing

@export var climbing_speed: float = 2.0
@export var climb_detection_distance: float = 1.5
@export var wall_layer_mask: int = 1  # Which physics layers count as climbable

@export var player: CharacterBody3D
@export var stats_manager: PlayerStatsManager
var is_climbing: bool = false
var can_climb: bool = false
var wall_normal: Vector3

func _process(delta):
	check_for_climbable_wall()
	handle_climbing_input()

func check_for_climbable_wall():
	if not player:
		return
		
	# Cast ray forward from player to detect walls
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		player.global_position,
		player.global_position + -player.global_transform.basis.z * climb_detection_distance,
		wall_layer_mask
	)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Check if the hit object has a "Climbable" node
		var hit_body = result.collider
		var climbable_node = hit_body.get_node_or_null("Climbable")
		
		if climbable_node:
			wall_normal = result.normal
			can_climb = true
		else:
			can_climb = false
			if is_climbing:
				stop_climbing()
	else:
		can_climb = false
		if is_climbing:
			stop_climbing()

func handle_climbing_input():
	if not stats_manager or not stats_manager.has_stamina():
		if is_climbing:
			stop_climbing()
		return
	
	# Check for climb input (left mouse button)
	if Input.is_action_pressed("climb") and can_climb:
		if not is_climbing:
			start_climbing()
		
		# Get mouse movement for climbing direction
		var mouse_delta = Input.get_last_mouse_velocity() * 0.001
		apply_climbing_movement(mouse_delta)
	else:
		if is_climbing:
			stop_climbing()

func start_climbing():
	is_climbing = true
	stats_manager.start_climbing()
	started_climbing.emit()
	
	# Disable gravity while climbing
	player.gravity = 0

func stop_climbing():
	is_climbing = false
	stats_manager.stop_climbing()
	stopped_climbing.emit()
	
	# Re-enable gravity
	player.gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func apply_climbing_movement(mouse_delta: Vector2):
	if not is_climbing or not player:
		return
	
	# Convert mouse movement to 3D climbing direction
	var climb_direction = Vector3()
	
	# Horizontal movement (left/right along wall)
	var wall_right = wall_normal.cross(Vector3.UP).normalized()
	climb_direction += wall_right * mouse_delta.x
	
	# Vertical movement (up/down)
	climb_direction += Vector3.UP * -mouse_delta.y
	
	# Apply movement
	player.velocity = climb_direction * climbing_speed
	player.move_and_slide()

func can_player_climb() -> bool:
	return can_climb and stats_manager and stats_manager.has_stamina()
