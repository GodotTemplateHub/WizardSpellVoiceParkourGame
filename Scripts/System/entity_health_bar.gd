extends Sprite3D
class_name EntityHealthBar

@export var entity_stats_manager: EntityStatsManager
@export var entity_health_progress_bar: ProgressBar

func _ready():
	if entity_stats_manager:
		entity_stats_manager.health_changed.connect(_on_health_changed)
		# Initial setup
		update_health_bar()

func update_health_bar():
	if entity_health_progress_bar and entity_stats_manager:
		entity_health_progress_bar.max_value = entity_stats_manager.max_health
		entity_health_progress_bar.value = entity_stats_manager.current_health

func _on_health_changed(current: float, max: float):
	if entity_health_progress_bar:
		entity_health_progress_bar.max_value = max
		entity_health_progress_bar.value = current
