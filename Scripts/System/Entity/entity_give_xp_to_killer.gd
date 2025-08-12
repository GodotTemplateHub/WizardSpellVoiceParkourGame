extends Node
class_name OnDeathGiveXPToKiller

@export var xp_to_give_to_killer: int = 50
var entity_stats_manager: EntityStatsManager

func _ready():
	entity_stats_manager = get_parent().get_node_or_null("EntityStatsManager")
	if entity_stats_manager:
		entity_stats_manager.died.connect(func(spell_killed_by): _on_entity_died(spell_killed_by.get_caster().get_node_or_null("EntityStatsManager")))

func _on_entity_died(killer_stats : EntityStatsManager):
	
	if killer_stats:
		killer_stats.add_xp(xp_to_give_to_killer)
	else:
		print("Killer has no EntityStatsManager - no XP awarded")

	rpc("death")


@rpc("call_local", "any_peer")		
func death():
	get_parent().queue_free()
