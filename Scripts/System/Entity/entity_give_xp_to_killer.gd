extends Node
class_name EntityGivesXPToKiller

@export var xp_to_give_to_killer: int = 25
@export var entity_stats_manager: EntityStatsManager
@export var entity : Node3D

func _ready():
	if entity_stats_manager:
		entity_stats_manager.died.connect(func(spell_killed_by): print(spell_killed_by))
		#_on_entity_died(spell_killed_by.get("caster").get_node_or_null("EntityStatsManager")))

func _on_entity_died(killer_stats : EntityStatsManager):
	if killer_stats:
		killer_stats.add_xp(xp_to_give_to_killer)
