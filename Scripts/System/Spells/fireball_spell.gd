extends Spell
class_name FireballSpell

@export var projectile_prefab: PackedScene
@export var projectile_speed: float = 20.0
@export var damage: float = 25.0

func on_cast_shoot(caster):
	if not projectile_prefab:
		print("No projectile prefab set for " + spell_name)
		return
	
	# Instantiate the projectile
	var projectile = projectile_prefab.instantiate()
	
	# Add to scene
	add_child(projectile)
	
	# Set direction (forward from spell's transform)
	var direction = -global_transform.basis.z
	
	# Connect collision signal if projectile has Area3D
	var area = projectile.get_node_or_null("Area3D")
	if area:
		area.body_entered.connect(_on_projectile_hit.bind(projectile))
		area.area_entered.connect(_on_projectile_hit.bind(projectile))
	
	# Simple movement along axis using Tween
	var tween = create_tween()
	var end_position = projectile.global_position + direction * 100.0  # Distance
	tween.tween_property(projectile, "global_position", end_position, 100.0 / projectile_speed)

func _on_projectile_hit(target, projectile):
	# Check if target has EntityStatsManager
	var stats_manager = target.get_node_or_null("EntityStatsManager")
	
	if stats_manager and stats_manager is EntityStatsManager:
		# Deal damage to entity
		stats_manager.rpc("take_damage", damage, get_spell_data())
		
		print("Fireball hit " + str(target.name) + " for " + str(damage) + " damage")
	else:
		print("Fireball hit " + str(target.name) + " (no damage)")
	
	# Destroy fireball
	projectile.queue_free()
