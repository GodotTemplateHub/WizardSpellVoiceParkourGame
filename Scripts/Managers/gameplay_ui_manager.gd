extends Node
class_name GameplayUIManager

@export var spell_manager: SpellManager
@export var entity_stats_manager: EntityStatsManager
@export var spell_slot_container: HBoxContainer
@export var spell_slot_prefab: PackedScene

# UI Elements for stats
@export_group("Stats UI")
@export var health_bar: ProgressBar
@export var mana_bar: ProgressBar
@export var speed_label: Label
@export var xp_bar: ProgressBar
@export var level_label: Label

var spell_slot_instances: Array = []
@export var player_sound_manager : PlayerSoundManager

func _ready():
	if spell_manager:
		spell_manager.spell_added.connect(_on_spell_added)
		spell_manager.spell_removed.connect(_on_spell_removed)
		spell_manager.spell_index_changed.connect(_on_spell_index_changed)
		
		# Initial population and selection
		populate_spell_slots()
		update_selected_spell_indicator()
	
	if entity_stats_manager:
		entity_stats_manager.health_changed.connect(_on_health_changed)
		entity_stats_manager.mana_changed.connect(_on_mana_changed)
		entity_stats_manager.xp_changed.connect(_on_xp_changed)
		entity_stats_manager.level_up.connect(_on_level_up)
		
		# Initial stats display
		update_stats_display()

func update_stats_display():
	if not entity_stats_manager:
		return
	
	# Update health bar
	if health_bar:
		health_bar.max_value = entity_stats_manager.max_health
		health_bar.value = entity_stats_manager.current_health
	
	# Update mana bar
	if mana_bar:
		mana_bar.max_value = entity_stats_manager.max_mana
		mana_bar.value = entity_stats_manager.current_mana
	
	# Update speed label
	if speed_label:
		speed_label.text = str(entity_stats_manager.speed)
	
	# Update XP bar
	if xp_bar:
		xp_bar.max_value = entity_stats_manager.max_xp
		xp_bar.value = entity_stats_manager.current_xp
	
	# Update level label
	if level_label:
		level_label.text = str(entity_stats_manager.current_level)

func _on_health_changed(current: float, max: float):
	if health_bar:
		health_bar.max_value = max
		health_bar.value = current

func _on_mana_changed(current: float, max: float):
	if mana_bar:
		mana_bar.max_value = max
		mana_bar.value = current

func _on_xp_changed(current: float, max: float):
	if xp_bar:
		xp_bar.max_value = max
		# Tween XP bar for smooth animation with curve
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(xp_bar, "value", current, 0.2)
		player_sound_manager.play_sound(SoundLibrary.get_sfx(SoundLibrary.SFX.XPGAIN))

func _on_level_up(new_level: int):
	if level_label:
		level_label.text = str(new_level)
	print("Level up! Now level " + str(new_level))
	player_sound_manager.play_sound(SoundLibrary.get_sfx(SoundLibrary.SFX.LEVELUP))

func populate_spell_slots():
	if not spell_slot_container or not spell_slot_prefab:
		return
	
	# Clear existing slots
	clear_spell_slots()
	
	# Create new slots for each spell
	var spells = spell_manager.get_all_spells()
	for i in range(spells.size()):
		var spell = spells[i]
		var slot_instance = spell_slot_prefab.instantiate()
		
		spell_slot_container.add_child(slot_instance)
		spell_slot_instances.append(slot_instance)
		
		# Configure the slot with spell data
		setup_spell_slot_ui(slot_instance, spell, i)

func setup_spell_slot_ui(slot_instance, spell: Spell, index: int):
	# Set spell name label
	var name_label = slot_instance.get_node_or_null("SpellNameLabel")
	if name_label:
		name_label.text = spell.spell_name
	
	# Set mana cost label
	var mana_label = slot_instance.get_node_or_null("SpellManaLabel")
	if mana_label:
		mana_label.text = str(spell.mana_cost)
	
	# Connect hover events for scaling
	if slot_instance.has_signal("mouse_entered"):
		slot_instance.mouse_entered.connect(_on_spell_slot_hover_enter.bind(slot_instance))
	if slot_instance.has_signal("mouse_exited"):
		slot_instance.mouse_exited.connect(_on_spell_slot_hover_exit.bind(slot_instance))
	
	# Call setup method if it exists (for backwards compatibility)
	if slot_instance.has_method("setup_spell_slot"):
		slot_instance.setup_spell_slot(spell, index)

func _on_spell_slot_hover_enter(slot_instance):
	# Scale up on hover
	var tween = create_tween()
	tween.tween_property(slot_instance, "scale", Vector2(1.2, 1.2), 0.01)

func _on_spell_slot_hover_exit(slot_instance):
	# Scale back to normal
	var tween = create_tween()
	tween.tween_property(slot_instance, "scale", Vector2(1.0, 1.0), 0.01)

func clear_spell_slots():
	for instance in spell_slot_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	spell_slot_instances.clear()

func update_selected_spell_indicator():
	var current_index = spell_manager.current_spell_index
	
	# Update all spell slots selection state
	for i in range(spell_slot_instances.size()):
		var slot = spell_slot_instances[i]
		var selected_panel = slot.get_node_or_null("SelectedPanel")
		
		if selected_panel:
			selected_panel.visible = (i == current_index)

func _on_spell_added(spell: Spell):
	populate_spell_slots()
	update_selected_spell_indicator()

func _on_spell_removed(spell: Spell):
	populate_spell_slots()
	update_selected_spell_indicator()

func _on_spell_index_changed(index: int):
	update_selected_spell_indicator()
