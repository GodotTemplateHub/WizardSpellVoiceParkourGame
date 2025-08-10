extends Node
class_name SpellManager

@export var current_spell: Spell
@export var fire_input_action: String = "fire"  # Input map action name

var owner_player  # Reference to the player who owns this spell manager
var all_players: Array = []  # Array of all players in the game
var selected_target  # Currently selected target for spells

signal spell_cast(spell: Spell, caster, target)
signal spell_failed(spell: Spell, reason: String)
signal target_selected(target)

func _ready():
	# Get reference to owner (assumes this is a child of a player)
	owner_player = get_parent()

func _input(event):
	if event.is_action_pressed(fire_input_action):
		attempt_cast_spell()

func set_current_spell(spell: Spell):
	current_spell = spell
	
	# Clear target when switching spells
	selected_target = null
	
	# Auto-select target for SELF spells
	if spell and spell.target_type == Spell.TargetType.SELF:
		selected_target = owner_player

func attempt_cast_spell():
	if not current_spell:
		spell_failed.emit(null, "No spell selected")
		return
	
	# Handle targeting
	var target = get_spell_target()
	
	# Attempt to cast the spell
	if current_spell.cast(owner_player, target):
		spell_cast.emit(current_spell, owner_player, target)
	else:
		var reason = get_cast_failure_reason()
		spell_failed.emit(current_spell, reason)

func get_spell_target():
	if not current_spell:
		return null
	
	match current_spell.target_type:
		Spell.TargetType.SELF:
			return owner_player
		Spell.TargetType.NONE:
			return null
		_:
			# For targeted spells, use selected_target or auto-target
			if selected_target:
				return selected_target
			else:
				# Auto-select first valid target if none selected
				var valid_targets = current_spell.get_valid_targets(owner_player, all_players)
				if valid_targets.size() > 0:
					return valid_targets[0]
	
	return null

func get_cast_failure_reason() -> String:
	if not current_spell:
		return "No spell selected"
	
	if current_spell.is_on_cooldown:
		return "Spell is on cooldown"
	
	if current_spell.target_type != Spell.TargetType.SELF and current_spell.target_type != Spell.TargetType.NONE:
		if not selected_target:
			return "No target selected"
	
	if owner_player.has_method("get_mana") and owner_player.get_mana() < current_spell.mana_cost:
		return "Not enough mana"
	
	return "Cannot cast spell"

func set_target(target):
	if not current_spell:
		return false
	
	# Check if target is valid for current spell
	var valid_targets = current_spell.get_valid_targets(owner_player, all_players)
	if target in valid_targets:
		selected_target = target
		target_selected.emit(target)
		return true
	
	return false

func get_valid_targets() -> Array:
	if not current_spell:
		return []
	
	return current_spell.get_valid_targets(owner_player, all_players)

func update_all_players(players: Array):
	all_players = players

# Utility functions
func has_spell() -> bool:
	return current_spell != null

func can_cast_current_spell() -> bool:
	if not current_spell:
		return false
	
	var target = get_spell_target()
	return current_spell.can_cast(owner_player, target)

func get_current_spell_info() -> Dictionary:
	if not current_spell:
		return {}
	
	return {
		"name": current_spell.spell_name,
		"description": current_spell.description,
		"mana_cost": current_spell.mana_cost,
		"cooldown": current_spell.cooldown_time,
		"target_type": current_spell.target_type,
		"on_cooldown": current_spell.is_on_cooldown,
		"cooldown_remaining": current_spell.cooldown_timer if current_spell.is_on_cooldown else 0.0
	}
