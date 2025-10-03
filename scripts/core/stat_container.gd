## StatContainer.gd
## Container for managing base stats and modifiers
##
## NOTE: StatModifier must be defined before using this class
##
## USAGE:
## 1. Create a StatContainer for your entity (weapon, player, enemy)
## 2. Set base values with set_base()
## 3. Add modifiers with add_modifier()
## 4. Query final values with get_value()
##
## FEATURES:
## - Automatic modifier priority sorting
## - Temporary modifiers with duration
## - Source tracking for debugging
## - Signal emissions for stat changes
##
## EXAMPLE:
##   var stats = StatContainer.new()
##   stats.set_base("damage", 10.0)
##   stats.set_base("fire_rate", 0.5)
##
##   var upgrade = StatModifier.create_multiply("damage", 1.5, "PowerUp")
##   stats.add_modifier(upgrade)
##
##   print(stats.get_value("damage"))  # 15.0
class_name StatContainer
extends Resource

## Emitted when a modifier is added
signal modifier_added(stat_name: String, modifier: Resource)
## Emitted when a modifier is removed
signal modifier_removed(stat_name: String, modifier: Resource)
## Emitted when a stat value changes
signal stat_changed(stat_name: String, old_value: float, new_value: float)

## Base stat values (before modifiers)
var base_stats: Dictionary = {}
## Active modifiers grouped by stat name
var modifiers: Dictionary = {}  # stat_name -> Array of StatModifier
## Cached final values (recalculated when modifiers change)
var cached_values: Dictionary = {}
## Dirty flags for cache invalidation
var dirty_stats: Dictionary = {}


## Set base value for a stat
func set_base(stat_name: String, value: float) -> void:
	var old_value = get_value(stat_name)
	base_stats[stat_name] = value
	_invalidate_cache(stat_name)
	stat_changed.emit(stat_name, old_value, get_value(stat_name))


## Get base value for a stat (before modifiers)
func get_base(stat_name: String) -> float:
	return base_stats.get(stat_name, 0.0)


## Add a modifier to a stat
func add_modifier(modifier: Resource) -> void:  # StatModifier
	if modifier.stat_name.is_empty():
		push_error("Cannot add modifier with empty stat_name")
		return

	if not modifiers.has(modifier.stat_name):
		modifiers[modifier.stat_name] = []

	var mod_array: Array = modifiers[modifier.stat_name]
	mod_array.append(modifier)

	# Sort by priority (lower priority = applied first)
	mod_array.sort_custom(func(a, b): return a.priority < b.priority)

	if modifier.is_temporary():
		modifier.time_remaining = modifier.duration

	_invalidate_cache(modifier.stat_name)
	modifier_added.emit(modifier.stat_name, modifier)


## Remove a specific modifier
func remove_modifier(modifier: Resource) -> bool:  # StatModifier
	if not modifiers.has(modifier.stat_name):
		return false

	var mod_array: Array = modifiers[modifier.stat_name]
	var idx = mod_array.find(modifier)
	if idx == -1:
		return false

	mod_array.remove_at(idx)
	_invalidate_cache(modifier.stat_name)
	modifier_removed.emit(modifier.stat_name, modifier)
	return true


## Remove all modifiers from a specific source
func remove_modifiers_from_source(source: String) -> int:
	var removed_count = 0
	for stat_name in modifiers.keys():
		var mod_array: Array = modifiers[stat_name]
		var to_remove: Array = []  # Array of StatModifier

		for mod in mod_array:
			if mod.source == source:
				to_remove.append(mod)

		for mod in to_remove:
			remove_modifier(mod)
			removed_count += 1

	return removed_count


## Get final calculated value for a stat (with all modifiers applied)
func get_value(stat_name: String) -> float:
	# Return cached value if available
	if not dirty_stats.get(stat_name, true):
		return cached_values.get(stat_name, 0.0)

	# Calculate fresh value
	var base = get_base(stat_name)
	var final_value = base

	if modifiers.has(stat_name):
		for modifier in modifiers[stat_name]:
			final_value = modifier.apply(final_value)

	# Cache result
	cached_values[stat_name] = final_value
	dirty_stats[stat_name] = false

	return final_value


## Update temporary modifiers (call this in _process or _physics_process)
func update_modifiers(delta: float) -> void:
	for stat_name in modifiers.keys():
		var mod_array: Array = modifiers[stat_name]
		var expired: Array[StatModifier] = []

		for mod in mod_array:
			if mod.update_timer(delta):
				expired.append(mod)

		for mod in expired:
			remove_modifier(mod)


## Get all modifiers affecting a stat
func get_modifiers(stat_name: String) -> Array:
	if not modifiers.has(stat_name):
		return []
	var result: Array = []  # Array of StatModifier
	result.assign(modifiers[stat_name])
	return result


## Clear all modifiers
func clear_modifiers() -> void:
	modifiers.clear()
	dirty_stats.clear()
	cached_values.clear()


## Invalidate cached value for a stat
func _invalidate_cache(stat_name: String) -> void:
	dirty_stats[stat_name] = true


## Debug: Print all stats with modifiers
func debug_print() -> void:
	print("=== StatContainer Debug ===")
	for stat_name in base_stats.keys():
		var base = get_base(stat_name)
		var final = get_value(stat_name)
		var mod_count = modifiers.get(stat_name, []).size()
		print("  %s: %.2f -> %.2f (%d modifiers)" % [stat_name, base, final, mod_count])
