extends Node
class_name Spell

enum TargetType {
	SELF,
	ALL_OTHER_PLAYER,
	ENEMY,
	ALL_ENEMIES,
	ALL_PLAYERS,
	NONE
}

@export var spell_name: String = "Base Spell"
@export var target_type: TargetType = TargetType.SELF
@export var mana_cost: int = 0
@export var cooldown_time: float = 0.0
@export var description: String = "A basic spell"

var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0

func _ready():
	set_process(cooldown_time > 0)

func _process(delta):
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false
			set_process(false)

func can_cast(caster, target = null) -> bool:
	if is_on_cooldown:
		return false
	
	# Check if target is required and provided
	if target_type != TargetType.SELF and target_type != TargetType.NONE and target == null:
		return false
	
	# Add mana check if needed
	if has_method("get_mana") and caster.get_mana() < mana_cost:
		return false
	
	return true

func cast(caster, target = null):
	if not can_cast(caster, target):
		return false
	
	# Consume mana
	if has_method("consume_mana") and mana_cost > 0:
		caster.consume_mana(mana_cost)
	
	# Start cooldown
	if cooldown_time > 0:
		is_on_cooldown = true
		cooldown_timer = cooldown_time
		set_process(true)
	
	# Call the spell effect
	on_cast(caster, target)
	return true

func on_cast(caster, target = null):
	# Override this in derived classes
	print("Casting " + spell_name)
