## StatModifier.gd
## Universal stat modification system - works for ANY numeric value
##
## USAGE IN EDITOR:
## 1. Create new StatModifier resource (right-click → New Resource → StatModifier)
## 2. Set stat_name to match the property you want to modify (e.g., "move_speed", "damage")
## 3. Choose modifier_type: ADD (flat bonus), MULTIPLY (percentage), or OVERRIDE (replace value)
## 4. Set value (e.g., 1.5 for 150% multiplier, or 10 for +10 flat)
## 5. Set priority (higher = applied later, useful for "final" modifiers)
##
## CODE USAGE:
##   var stats = StatContainer.new()
##   stats.set_base("damage", 50.0)
##   stats.add_modifier(StatModifier.create_multiply("damage", 1.5)) # 150% damage
##   print(stats.get_value("damage")) # = 75.0
class_name StatModifier
extends Resource

enum ModifierType {
	ADD,       ## Adds flat value: final = base + value
	MULTIPLY,  ## Multiplies value: final = base * value
	OVERRIDE   ## Replaces value: final = value
}

## Name of the stat this modifier affects (must match property name)
@export var stat_name: String = ""

## How this modifier changes the stat value
@export var modifier_type: ModifierType = ModifierType.ADD

## The modifier value (meaning depends on modifier_type)
@export var value: float = 0.0

## Priority for application order - higher values apply later (default: 0)
## Use 100+ for "final" modifiers that should apply after everything else
@export var priority: int = 0

## Optional: Source that created this modifier (for debugging/removal)
@export var source: String = ""

## Optional: Duration in seconds (0 = permanent)
@export var duration: float = 0.0

## Internal: Time remaining for temporary modifiers
var time_remaining: float = 0.0


func _init(p_stat_name: String = "", p_type: ModifierType = ModifierType.ADD, p_value: float = 0.0) -> void:
	stat_name = p_stat_name
	modifier_type = p_type
	value = p_value


## Factory method: Create a flat addition modifier
static func create_add(p_stat_name: String, p_value: float, p_source: String = "") -> StatModifier:
	var mod = StatModifier.new(p_stat_name, ModifierType.ADD, p_value)
	mod.source = p_source
	return mod


## Factory method: Create a multiplication modifier
static func create_multiply(p_stat_name: String, p_multiplier: float, p_source: String = "") -> StatModifier:
	var mod = StatModifier.new(p_stat_name, ModifierType.MULTIPLY, p_multiplier)
	mod.source = p_source
	return mod


## Factory method: Create an override modifier
static func create_override(p_stat_name: String, p_value: float, p_source: String = "") -> StatModifier:
	var mod = StatModifier.new(p_stat_name, ModifierType.OVERRIDE, p_value)
	mod.source = p_source
	return mod


## Apply this modifier to a value
func apply(base_value: float) -> float:
	match modifier_type:
		ModifierType.ADD:
			return base_value + value
		ModifierType.MULTIPLY:
			return base_value * value
		ModifierType.OVERRIDE:
			return value
	return base_value


## Check if this is a temporary modifier
func is_temporary() -> bool:
	return duration > 0.0


## Update temporary modifier timer
func update_timer(delta: float) -> bool:
	if not is_temporary():
		return false

	time_remaining -= delta
	return time_remaining <= 0.0  # Returns true if expired
