## WeaponDataV2.gd
## Comprehensive weapon configuration with stat system and fire modes
##
## NOTE: FireMode, StatModifier, and StatContainer must be defined before using this class
##
## EDITOR SETUP GUIDE:
## ==================
## 1. CREATE WEAPON DATA:
##    - Right-click in FileSystem → New Resource → WeaponDataV2
##    - Name it descriptively (e.g., "assault_rifle_data.tres")
##
## 2. CONFIGURE BASIC INFO:
##    - weapon_name: Display name
##    - weapon_model: 3D scene for the weapon
##    - weapon_icon: UI icon (optional)
##
## 3. CHOOSE FIRE MODE:
##    - Create FireMode resource (HitscanFireMode, ProjectileFireMode, etc.)
##    - Assign to fire_mode property
##
## 4. CONFIGURE BASE STATS:
##    - Click "Initialize Default Stats" button in inspector
##    - Adjust values in inspector (damage, fire_rate, etc.)
##
## 5. ADD UPGRADES/MODIFIERS (Optional):
##    - Create StatModifier resources
##    - Add to starting_modifiers array
##    - Or apply at runtime via code
##
## CREATING DIFFERENT WEAPON TYPES:
## =================================
## ASSAULT RIFLE:
##   - fire_mode: HitscanFireMode
##   - damage: 25, fire_rate: 0.1, magazine_size: 30
##   - bullet_spread: 0.02, is_automatic: true
##
## SNIPER RIFLE:
##   - fire_mode: HitscanFireMode
##   - damage: 100, fire_rate: 1.5, magazine_size: 5
##   - bullet_spread: 0.001, is_automatic: false
##
## SHOTGUN:
##   - fire_mode: HitscanFireMode with pellet_count: 8
##   - damage: 15, fire_rate: 0.8, magazine_size: 8
##   - bullet_spread: 0.15, is_automatic: false
##
## ROCKET LAUNCHER:
##   - fire_mode: ProjectileFireMode
##   - projectile_scene: rocket.tscn, projectile_speed: 50
##   - damage: 200, fire_rate: 2.0, magazine_size: 1
##
## LASER RIFLE:
##   - fire_mode: ChargedFireMode
##   - min_charge_time: 0.5, max_charge_time: 3.0
##   - damage: 50 (scales with charge)
##
## SWORD/MELEE:
##   - fire_mode: MeleeFireMode
##   - attack_range: 2.0, attack_arc_angle: 60
##   - damage: 50, enable_combos: true
@tool
class_name WeaponDataV2
extends Resource

## Emitted when a stat changes
signal stat_changed(stat_name: String, old_value: float, new_value: float)

## Emitted when weapon is equipped
signal weapon_equipped
## Emitted when weapon is unequipped
signal weapon_unequipped

@export_group("Identification")
## Display name of the weapon
@export var weapon_name: String = "New Weapon"

## Weapon type category (for filtering, UI, etc.)
@export_enum("Rifle", "Pistol", "Shotgun", "Sniper", "Melee", "Explosive", "Energy", "Other") var weapon_type: String = "Rifle"

## 3D model scene for this weapon
@export var weapon_model: PackedScene

## Icon for UI display
@export var weapon_icon: Texture2D

## Short description
@export_multiline var description: String = ""


@export_group("Fire Mode")
## How this weapon fires (hitscan, projectile, melee, charged, etc.)
## Create a FireMode resource and assign here
@export var fire_mode: Resource:  # FireMode
	set(value):
		fire_mode = value
		if fire_mode and fire_mode.has_signal("fire_executed"):
			if not fire_mode.fire_executed.is_connected(_on_fire_executed):
				fire_mode.fire_executed.connect(_on_fire_executed)
		if fire_mode and fire_mode.has_signal("hit_detected"):
			if not fire_mode.hit_detected.is_connected(_on_hit_detected):
				fire_mode.hit_detected.connect(_on_hit_detected)

## If true, holding fire button continues firing
@export var is_automatic: bool = true


@export_group("Ammo System")
## Does this weapon use ammo?
@export var uses_ammo: bool = true

## Current ammo in magazine
@export var current_ammo: int = 30

## Magazine capacity
@export var magazine_size: int = 30

## Reserve ammo
@export var reserve_ammo: int = 90

## Maximum reserve ammo
@export var max_reserve_ammo: int = 300

## Reload time in seconds
@export_range(0.1, 10.0, 0.1, "suffix:s") var reload_time: float = 2.0

## If true, can reload one round at a time (like shotgun)
@export var reload_individual_rounds: bool = false


@export_group("Base Stats")
## Base damage per shot
@export_range(1.0, 1000.0, 1.0) var base_damage: float = 25.0

## Time between shots in seconds
@export_range(0.01, 10.0, 0.01, "suffix:s") var base_fire_rate: float = 0.1

## Maximum effective range in meters
@export_range(1.0, 10000.0, 10.0, "suffix:m") var base_max_range: float = 100.0

## Bullet spread (accuracy) - lower = more accurate
@export_range(0.0, 1.0, 0.001) var base_bullet_spread: float = 0.02

## Recoil strength
@export_range(0.0, 10.0, 0.1) var base_recoil: float = 1.0

## Movement speed multiplier when holding this weapon
@export_range(0.1, 2.0, 0.05) var base_move_speed_multiplier: float = 1.0


@export_group("Audio")
## Sound when firing
@export var fire_sound: AudioStream

## Sound when reloading
@export var reload_sound: AudioStream

## Sound when out of ammo (dry fire)
@export var empty_sound: AudioStream


@export_group("Visual Effects")
## Muzzle flash particle effect
@export var muzzle_flash_scene: PackedScene

## Reload animation name (if using AnimationPlayer)
@export var reload_animation: String = "reload"

## Fire animation name
@export var fire_animation: String = "fire"


@export_group("Upgrades & Modifiers")
## Modifiers applied to this weapon's stats
## Add StatModifier resources here to boost damage, fire rate, etc.
@export var starting_modifiers: Array = []  # Array of StatModifier


## Runtime stat container (initialized in _init)
var stats: StatContainer

## Internal flags
var is_equipped: bool = false
var is_reloading: bool = false


func _init() -> void:
	# Initialize stat container
	stats = StatContainer.new()
	_initialize_stats()


## Initialize base stats in the stat container
func _initialize_stats() -> void:
	stats.set_base("damage", base_damage)
	stats.set_base("fire_rate", base_fire_rate)
	stats.set_base("max_range", base_max_range)
	stats.set_base("bullet_spread", base_bullet_spread)
	stats.set_base("recoil", base_recoil)
	stats.set_base("move_speed_multiplier", base_move_speed_multiplier)

	# Apply starting modifiers
	for modifier in starting_modifiers:
		stats.add_modifier(modifier)

	# Connect stat change signals
	stats.stat_changed.connect(_on_stat_changed)


## Add a modifier to this weapon (for upgrades, powerups, etc.)
func add_modifier(modifier: Resource) -> void:  # StatModifier
	stats.add_modifier(modifier)


## Remove a modifier
func remove_modifier(modifier: Resource) -> void:  # StatModifier
	stats.remove_modifier(modifier)


## Remove all modifiers from a specific source
func remove_modifiers_from_source(source: String) -> int:
	return stats.remove_modifiers_from_source(source)


## Get current stat value (with modifiers applied)
func get_stat(stat_name: String) -> float:
	return stats.get_value(stat_name)


## Update weapon (for temporary modifiers, etc.)
func update(delta: float) -> void:
	stats.update_modifiers(delta)
	if fire_mode:
		fire_mode.update(delta)


## Validate weapon configuration
func validate() -> Array[String]:
	var errors: Array[String] = []

	if weapon_name.is_empty():
		errors.append("Weapon must have a name")

	if not fire_mode:
		errors.append("Weapon must have a fire_mode assigned")
	else:
		errors.append_array(fire_mode.validate())

	if uses_ammo and magazine_size <= 0:
		errors.append("Weapon with ammo must have magazine_size > 0")

	return errors


## Get ammo info for UI
func get_ammo_info() -> Dictionary:
	return {
		"current": current_ammo,
		"reserve": reserve_ammo,
		"magazine_size": magazine_size,
		"uses_ammo": uses_ammo
	}


## Consume ammo
func consume_ammo(amount: int = 1) -> bool:
	if not uses_ammo:
		return true

	if current_ammo < amount:
		return false

	current_ammo -= amount
	return true


## Reload weapon
func reload() -> bool:
	if not uses_ammo:
		return false

	if is_reloading:
		return false

	if current_ammo == magazine_size:
		return false

	if reserve_ammo <= 0:
		return false

	is_reloading = true
	return true


## Finish reload (call after reload_time)
func finish_reload() -> void:
	if not is_reloading:
		return

	if reload_individual_rounds:
		# Reload one round at a time
		if reserve_ammo > 0 and current_ammo < magazine_size:
			reserve_ammo -= 1
			current_ammo += 1
	else:
		# Reload entire magazine
		var needed = magazine_size - current_ammo
		var transfer = min(needed, reserve_ammo)
		current_ammo += transfer
		reserve_ammo -= transfer

	is_reloading = false


## Cancel reload
func cancel_reload() -> void:
	is_reloading = false


## Mark as equipped
func equip() -> void:
	is_equipped = true
	weapon_equipped.emit()


## Mark as unequipped
func unequip() -> void:
	is_equipped = false
	weapon_unequipped.emit()


## Internal callbacks
func _on_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	stat_changed.emit(stat_name, old_value, new_value)


func _on_fire_executed() -> void:
	pass  # Hook point for custom behavior


func _on_hit_detected(_target: Node3D, _hit_point: Vector3, _normal: Vector3) -> void:
	pass  # Hook point for custom behavior


## Debug print all stats
func debug_print_stats() -> void:
	print("=== %s Stats ===" % weapon_name)
	stats.debug_print()


## Editor helper - reinitialize stats
func _validate_property(property: Dictionary) -> void:
	# Hide ammo properties if not using ammo
	if not uses_ammo:
		if property.name in ["current_ammo", "magazine_size", "reserve_ammo", "max_reserve_ammo", "reload_time", "reload_individual_rounds"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
