extends Node
class_name PlayerStatsManager

signal stamina_changed(percentage: float)
signal stamina_depleted

@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 10.0  # per second while climbing
@export var stamina_regen_rate: float = 5.0   # per second while resting
@export var stamina_progress_bar: ProgressBar

var current_stamina: float
var is_climbing: bool = false
var is_resting: bool = false

func _ready():
	current_stamina = max_stamina
	update_progress_bar()

func _process(delta):
	if is_climbing:
		drain_stamina(stamina_drain_rate * delta)
	elif is_resting:
		regen_stamina(stamina_regen_rate * delta)

func update_progress_bar():
	var percentage = get_stamina_percentage()
	if stamina_progress_bar:
		stamina_progress_bar.value = percentage * 100  # ProgressBar uses 0-100 range
	stamina_changed.emit(percentage)

func start_climbing():
	is_climbing = true
	is_resting = false

func stop_climbing():
	is_climbing = false

func start_resting():
	is_resting = true
	is_climbing = false

func stop_resting():
	is_resting = false

func drain_stamina(amount: float):
	current_stamina = maxf(current_stamina - amount, 0.0)
	update_progress_bar()
	
	if current_stamina <= 0:
		stamina_depleted.emit()

func regen_stamina(amount: float):
	current_stamina = minf(current_stamina + amount, max_stamina)
	update_progress_bar()

func get_stamina_percentage() -> float:
	return current_stamina / max_stamina

func has_stamina() -> bool:
	return current_stamina > 0

func get_current_stamina() -> float:
	return current_stamina
