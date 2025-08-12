extends Node3D
class_name SpellManager

@export var current_spell: Spell
var current_spell_index: int = 0
var spells: Array = []  # Cache spells array

signal spell_added(spell: Spell)
signal spell_removed(spell: Spell)
signal spell_index_changed(index: int)
signal spell_cast_attempted(spell: Spell, success: bool)

func _ready():
	update_spells_cache()

func _input(event):
	if !is_multiplayer_authority(): return
	if event.is_pressed():
		if spells.size() > 0:
			# Handle fire input
			if event.is_action_pressed("fire"):
				attempt_cast_current_spell()
			
			# Handle spell cycling
			elif event.is_action_pressed("next_spell"):
				cycle_spell(1)
			elif event.is_action_pressed("prev_spell"):
				cycle_spell(-1)

func cycle_spell(direction: int):
	var spells = get_all_spells()
	if spells.size() <= 1:
		return
	
	var new_index = current_spell_index + direction
	
	# Wrap around
	if new_index >= spells.size():
		new_index = 0
	elif new_index < 0:
		new_index = spells.size() - 1
	
	set_current_spell_index(new_index)
	print("Switched to spell: " + current_spell.spell_name if current_spell else "None")

func attempt_cast_current_spell():
	if not current_spell:
		print("No spell selected")
		spell_cast_attempted.emit(null, false)
		return
	
	# Get owner player (assuming SpellManager is child of player)
	var caster = get_parent()
	if not caster:
		print("No caster found")
		spell_cast_attempted.emit(current_spell, false)
		return
	
	# Check conditions and cast
	var success = current_spell.start_cast(caster, null)  # No target for now
	spell_cast_attempted.emit(current_spell, success)
	
	if success:
		print("Cast " + current_spell.spell_name)
	else:
		print("Failed to cast " + current_spell.spell_name)

func add_spell(spell: Spell):
	if spell:
		add_child(spell)
		update_spells_cache()
		update_current_spell()
		spell_added.emit(spell)

func remove_spell(spell: Spell):
	if spell and spell.get_parent() == self:
		if current_spell == spell:
			current_spell = null
		remove_child(spell)
		update_spells_cache()
		clamp_spell_index()
		update_current_spell()
		spell_removed.emit(spell)

func update_spells_cache():
	spells = []
	for child in get_children():
		if child is Spell:
			spells.append(child)

func get_all_spells() -> Array:
	return spells

func get_current_spell() -> Spell:
	return current_spell

func set_current_spell(spell: Spell):
	current_spell = spell
	# Update index to match the spell
	var spells = get_all_spells()
	current_spell_index = spells.find(spell)

func set_current_spell_index(index: int):
	var spells = get_all_spells()
	if spells.size() > 0:
		current_spell_index = clamp(index, 0, spells.size() - 1)
		update_current_spell()
		spell_index_changed.emit(current_spell_index)

func update_current_spell():
	var spells = get_all_spells()
	if spells.size() > 0 and current_spell_index < spells.size():
		current_spell = spells[current_spell_index]
	else:
		current_spell = null

func clamp_spell_index():
	var spells = get_all_spells()
	if spells.size() > 0:
		current_spell_index = clamp(current_spell_index, 0, spells.size() - 1)
	else:
		current_spell_index = 0
