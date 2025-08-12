extends Node
class_name EntityDeath

@export var entity : Node3D
@export var entity_stats_manager : EntityStatsManager

enum OnDeath {
	QUEUE_FREE,
	NOTHING
}

@export var death_type : OnDeath

func _ready() -> void:
	entity_stats_manager.died.connect(func(): death())

func death():
	if death_type == OnDeath.QUEUE_FREE: entity.queue_free()
	else: pass
