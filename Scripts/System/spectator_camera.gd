extends Camera3D
class_name SpectatorCamera

@export var movement_speed: float = 10.0
@export var boost_speed_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.002

var velocity: Vector3 = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# Mouse look
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_object_local(Vector3(1, 0, 0), -event.relative.y * mouse_sensitivity)
		
		# Clamp vertical rotation
		rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	handle_movement(delta)

func handle_movement(delta):
	var input_vector = Vector3.ZERO
	
	# Get input
	if Input.is_action_pressed("forward"):
		input_vector -= transform.basis.z
	if Input.is_action_pressed("down"):
		input_vector += transform.basis.z
	if Input.is_action_pressed("left"):
		input_vector -= transform.basis.x
	if Input.is_action_pressed("right"):
		input_vector += transform.basis.x
	if Input.is_action_pressed("ui_up"):  # Space or E
		input_vector += Vector3.UP
	if Input.is_action_pressed("ui_down"):  # Shift or Q
		input_vector -= Vector3.UP
	
	# Normalize input to prevent faster diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	
	# Apply speed boost if holding shift
	var current_speed = movement_speed
	if Input.is_action_pressed("ui_accept"):  # Shift or boost key
		current_speed *= boost_speed_multiplier
	
	# Move the camera
	velocity = input_vector * current_speed
	global_position += velocity * delta
