extends Node
class_name GameManager

@export var arena_manager: ArenaManager

var players: Array = []

enum CurrentLevelState {
	PREGAME,
	LEVELUP,
	ARENA
}

@export var current_state: CurrentLevelState = CurrentLevelState.PREGAME

# Inspector-editable durations for each phase
@export_group("Phase Durations")
@export var pregame_duration: float = 10.0
@export var levelup_duration: float = 20.0
@export var arena_duration: float = 120.0

@export var phase_system_enabled: bool = true  # Toggle to disable timer system for testing

var state_timer: float = 0.0
var is_timer_active: bool = false

signal state_changed(old_state: CurrentLevelState, new_state: CurrentLevelState)
signal state_timer_updated(time_remaining: float)
signal state_timer_finished()

func _ready():
	set_process(false)
	# Set up multiplayer authority (only host manages timer)
	set_multiplayer_authority(1)
	change_state(CurrentLevelState.PREGAME)

func _process(delta):
	# Only host processes the timer and only if timer is enabled
	if is_timer_active and is_multiplayer_authority() and phase_system_enabled:
		state_timer -= delta
		
		# Sync timer to all clients
		rpc("sync_timer", state_timer)
		
		state_timer_updated.emit(state_timer)
		
		if state_timer <= 0:
			state_timer = 0.0
			is_timer_active = false
			set_process(false)
			state_timer_finished.emit()
			
			# Auto-advance to next state (host only)
			advance_to_next_state()

@rpc("any_peer", "call_local", "reliable")
func change_state(new_state: CurrentLevelState, duration: float = -1):
	var old_state = current_state
	current_state = new_state
	
	# Set timer duration based on state or override
	var timer_duration = duration
	if duration <= 0:
		match current_state:
			CurrentLevelState.PREGAME:
				timer_duration = pregame_duration
			CurrentLevelState.LEVELUP:
				timer_duration = levelup_duration
			CurrentLevelState.ARENA:
				timer_duration = arena_duration
	
	# Only host starts the timer (and only if timer is enabled)
	if is_multiplayer_authority() and phase_system_enabled:
		start_timer(timer_duration)
	elif phase_system_enabled:
		# Clients just set the timer value for display
		state_timer = timer_duration
	else:
		# Timer disabled - set to 0 for display
		state_timer = 0.0
	
	state_changed.emit(old_state, new_state)
	print("State changed from ", get_state_name(old_state), " to ", get_state_name(new_state))
	
	# Handle state-specific logic
	handle_state_enter(new_state)

func start_timer(duration: float):
	# Only host can start timers and only if timer is enabled
	if not is_multiplayer_authority() or not phase_system_enabled:
		return
		
	state_timer = duration
	is_timer_active = true
	set_process(true)
	
	# Sync initial timer to all clients
	rpc("sync_timer", state_timer)

@rpc("authority", "call_local", "reliable")
func sync_timer(time: float):
	state_timer = time
	state_timer_updated.emit(state_timer)

func stop_timer():
	# Only host can stop timers
	if not is_multiplayer_authority():
		return
		
	is_timer_active = false
	set_process(false)
	
	# Sync stop to all clients
	rpc("sync_timer_stop")

@rpc("authority", "call_local", "reliable")
func sync_timer_stop():
	is_timer_active = false
	set_process(false)

func extend_timer(additional_time: float):
	# Only host can extend timers
	if not is_multiplayer_authority():
		return
		
	state_timer += additional_time
	
	# Sync extended timer to all clients
	rpc("sync_timer", state_timer)

func get_time_remaining() -> float:
	return state_timer

func get_time_remaining_formatted() -> String:
	var minutes = int(state_timer) / 60
	var seconds = int(state_timer) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_state_name(state: CurrentLevelState = current_state) -> String:
	match state:
		CurrentLevelState.PREGAME:
			return "Pre-Game"
		CurrentLevelState.LEVELUP:
			return "Level Up"
		CurrentLevelState.ARENA:
			return "Arena Battle"
		_:
			return "Unknown"

func get_current_state_name() -> String:
	return get_state_name(current_state)

func advance_to_next_state():
	# Only host can advance states
	if not is_multiplayer_authority():
		return
		
	match current_state:
		CurrentLevelState.PREGAME:
			rpc("change_state", CurrentLevelState.ARENA)
		CurrentLevelState.LEVELUP:
			rpc("change_state", CurrentLevelState.ARENA)
		CurrentLevelState.ARENA:
			rpc("change_state", CurrentLevelState.LEVELUP)  # Loop: ARENA -> LEVELUP -> ARENA

func handle_state_enter(state: CurrentLevelState):
	match state:
		CurrentLevelState.PREGAME:
			print("Game starting soon...")
			# Initialize game systems
		
		CurrentLevelState.LEVELUP:
			print("Level up phase!")
			# Show level up options, pause arena
		
		CurrentLevelState.ARENA:
			print("Arena battle begins!")
			if arena_manager:
				arena_manager.start_arena()

func force_state_change(new_state: CurrentLevelState):
	# Only host can force state changes
	if not is_multiplayer_authority():
		return
		
	stop_timer()
	rpc("change_state", new_state)

func is_in_combat() -> bool:
	return current_state == CurrentLevelState.ARENA

func can_level_up() -> bool:
	return current_state == CurrentLevelState.LEVELUP

# Debug functions (host only)
func skip_to_arena():
	if is_multiplayer_authority():
		force_state_change(CurrentLevelState.ARENA)

func trigger_levelup():
	if is_multiplayer_authority():
		force_state_change(CurrentLevelState.LEVELUP)
