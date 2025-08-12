extends Node3D
class_name Spell

enum TargetType {
	SELF,
	ENEMY
}

enum SpellType {
	SHOOT,
	AREA,
	TARGETED
}

enum CastType {
	INSTANT,
	HOLD
}

@export_group("Basic Info")
@export var spell_name: String = "Base Spell"
@export var description: String = "A basic spell"

@export_group("Spell Types")
@export var target_type: TargetType = TargetType.SELF
@export var spell_type: SpellType = SpellType.SHOOT
@export var cast_type: CastType = CastType.INSTANT

@export_group("Costs & Timers")
@export var mana_cost: int = 0
@export var cooldown_time: float = 0.0
@export var hold_spell_time: float = 2.0

var spell_level: int = 1
var current_spell_xp: int = 0
var max_spell_xp: int = 100

var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0

var is_charging: bool = false
var charge_timer: float = 0.0

signal spell_charged
signal spell_charge_progress(progress: float)

func _ready():
	set_process(cooldown_time > 0 or cast_type == CastType.HOLD)

func _process(delta):
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false
			if cast_type != CastType.HOLD:
				set_process(false)
	
	if is_charging:
		charge_timer += delta
		var progress = charge_timer / hold_spell_time
		spell_charge_progress.emit(progress)
		
		if charge_timer >= hold_spell_time:
			is_charging = false
			charge_timer = 0.0
			spell_charged.emit()
			if cast_type != CastType.HOLD or not is_on_cooldown:
				set_process(false)

func can_cast(caster, target = null) -> bool:
	if is_on_cooldown or is_charging:
		return false
	
	# Check if target is required based on spell type
	if spell_type == SpellType.TARGETED and target == null:
		return false
	
	# Add mana check if needed
	if caster.has_method("get_mana") and caster.get_mana() < mana_cost:
		return false
	
	return true

func start_cast(caster, target = null):
	if not can_cast(caster, target):
		return false
	
	if cast_type == CastType.INSTANT:
		return cast(caster, target)
	elif cast_type == CastType.HOLD:
		start_charging(caster, target)
		return true

func start_charging(caster, target = null):
	is_charging = true
	charge_timer = 0.0
	set_process(true)
	
	# Store caster and target for when spell finishes charging
	var callable = func(): cast(caster, target)
	spell_charged.connect(callable, CONNECT_ONE_SHOT)

func cancel_charging():
	if is_charging:
		is_charging = false
		charge_timer = 0.0
		# Disconnect any connected spell_charged signals
		for connection in spell_charged.get_connections():
			spell_charged.disconnect(connection.callable)

func cast(caster, target = null):
	if not can_cast(caster, target):
		return false
	
	# Consume mana
	if caster.has_method("consume_mana") and mana_cost > 0:
		caster.consume_mana(mana_cost)
	
	# Start cooldown
	if cooldown_time > 0:
		is_on_cooldown = true
		cooldown_timer = cooldown_time
		set_process(true)
	
	# Handle different spell types
	match spell_type:
		SpellType.SHOOT:
			# Fire like a bullet - no target needed
			on_cast_shoot(caster)
		SpellType.AREA:
			# Use Area3D child for area effect
			on_cast_area(caster)
		SpellType.TARGETED:
			# Requires target player
			on_cast_targeted(caster, target)
	
	return true

func on_cast_shoot(caster):
	# Override in derived classes for projectile spells
	print("Shooting " + spell_name)

func on_cast_area(caster):
	# Override in derived classes for area spells
	# Use Area3D child for detection
	var area = get_node_or_null("Area3D")
	if area:
		print("Casting area " + spell_name)
	else:
		print("No Area3D found for area spell " + spell_name)

func on_cast_targeted(caster, target):
	# Override in derived classes for targeted spells
	print("Casting " + spell_name + " on " + str(target))

func get_caster():
	# Return the player who owns this spell (parent of SpellManager)
	var spell_manager = get_parent()
	if spell_manager and spell_manager is SpellManager:
		return spell_manager.get_parent().get_parent()
	return null
