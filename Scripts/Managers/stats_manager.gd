extends Node
class_name EntityStatsManager

@export_group("Basic Info")
@export var max_health: float = 100
@export var max_mana: float = 50
@export var speed: float = 5.0
@export var base_damage: float = 10.0

@export_group("Experience & Level")
@export var max_level: int = 50

var current_health: float = 0
var current_mana: float = 0
var current_xp: float = 50
var max_xp: float = 100
var current_level: int = 1

signal died(spell_entity_died_by : Spell)
signal health_changed(current: float, max: float)
signal mana_changed(current: float, max: float)
signal xp_changed(current: float, max: int)
signal level_up(new_level: int)

var latest_spell_damaged_by : Spell = null

func _ready():
	current_health = max_health
	current_mana = max_mana
	current_level = 1

func add_xp(amount: float):
	current_xp += amount
	xp_changed.emit(current_xp, max_xp)
	
	# Check for level up
	while current_xp >= max_xp and current_level < max_level:
		level_up_entity()

func level_up_entity():
	current_xp -= max_xp
	current_level += 1
	max_xp = int(max_xp * 1.5)  # Increase XP requirement by 50%
	
	level_up.emit(current_level)
	xp_changed.emit(current_xp, max_xp)

func take_damage(damage: float, spell : Spell):
	latest_spell_damaged_by = spell
	current_health -= damage
	if current_health <= 0:
		current_health = 0
		die()
	health_changed.emit(current_health, max_health)
	

func die():
	died.emit(latest_spell_damaged_by)

func get_health() -> float:
	return current_health

func get_mana() -> float:
	return current_mana

func consume_mana(amount: float) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false
