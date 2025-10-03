## MeleeFireMode.gd
## Melee attack system with swing arcs and combos
##
## EDITOR SETUP:
## 1. Create MeleeFireMode resource
## 2. Set attack range, arc angle, and damage
## 3. Configure combo chain (optional)
## 4. Assign swing animations to weapon model
##
## FEATURES:
## - Area-based damage in arc in front of player
## - Combo system with increasing damage
## - Block/parry window
## - Knockback support
class_name MeleeFireMode
extends FireMode

@export_group("Melee Properties")
## Attack range in meters
@export_range(0.5, 10.0, 0.1, "suffix:m") var attack_range: float = 2.0

## Attack arc angle (degrees from center)
@export_range(0.0, 180.0, 5.0, "suffix:°") var attack_arc_angle: float = 60.0

## Attack duration (for animation timing)
@export_range(0.1, 5.0, 0.05, "suffix:s") var attack_duration: float = 0.3

## Delay before damage is applied (wind-up)
@export_range(0.0, 2.0, 0.05, "suffix:s") var damage_delay: float = 0.1

## Knockback force applied to hit targets
@export_range(0.0, 100.0, 1.0) var knockback_force: float = 10.0

## Can hit multiple targets in one swing
@export var hit_multiple_targets: bool = true

## Maximum targets per swing (if hit_multiple_targets)
@export_range(1, 20, 1) var max_targets_per_swing: int = 5

@export_group("Combo System")
## Enable combo chaining
@export var enable_combos: bool = false

## Combo window - time after attack to continue combo (seconds)
@export_range(0.0, 5.0, 0.1, "suffix:s") var combo_window: float = 0.8

## Damage multiplier per combo level
@export var combo_damage_multipliers: Array[float] = [1.0, 1.2, 1.5, 2.0]

## Combo reset time (seconds of no attacks)
@export_range(0.0, 10.0, 0.1, "suffix:s") var combo_reset_time: float = 2.0

@export_group("Defense")
## Enable blocking
@export var enable_blocking: bool = false

## Damage reduction when blocking (0.5 = 50% reduction)
@export_range(0.0, 1.0, 0.05) var block_damage_reduction: float = 0.7

## Animation names (optional - for custom animations)
@export var attack_animation_name: String = "melee_attack"
@export var block_animation_name: String = "melee_block"

## Internal state
var current_combo_level: int = 0
var combo_timer: float = 0.0
var is_attacking: bool = false
var is_blocking: bool = false


func fire(weapon_controller: Node3D, weapon_data: Resource) -> void:
	if not can_fire(weapon_data):
		fire_blocked.emit("Cannot fire")
		return

	if is_attacking:
		return

	is_attacking = true

	# Play attack animation
	_play_attack_animation(weapon_controller)

	# Wait for wind-up
	await weapon_controller.get_tree().create_timer(damage_delay).timeout

	# Perform attack
	_perform_melee_attack(weapon_controller, weapon_data)

	# Wait for attack to finish
	await weapon_controller.get_tree().create_timer(attack_duration - damage_delay).timeout

	is_attacking = false

	# Combo management
	if enable_combos:
		combo_timer = combo_window
		if combo_timer > 0:
			current_combo_level = min(current_combo_level + 1, combo_damage_multipliers.size() - 1)

	# Start cooldown
	start_cooldown(weapon_data.stats.get_value("fire_rate"))

	fire_executed.emit()


func update(delta: float) -> void:
	super.update(delta)

	# Combo timer
	if enable_combos and combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			current_combo_level = 0


func _perform_melee_attack(weapon_controller: Node3D, weapon_data: Resource) -> void:
	var camera = weapon_controller.get_viewport().get_camera_3d()
	if not camera:
		return

	# Get damage with combo multiplier
	var base_damage = weapon_data.stats.get_value("damage")
	var combo_mult = combo_damage_multipliers[current_combo_level] if enable_combos else 1.0
	var final_damage = base_damage * combo_mult

	# Find targets in arc
	var targets = _find_targets_in_arc(weapon_controller, camera)

	var hit_count = 0
	for target in targets:
		if hit_multiple_targets:
			if hit_count >= max_targets_per_swing:
				break

		# Apply damage
		if target.has_method("take_damage"):
			target.take_damage(final_damage)

		# Apply knockback
		if knockback_force > 0 and target is RigidBody3D:
			var direction = (target.global_position - camera.global_position).normalized()
			target.apply_central_impulse(direction * knockback_force)

		hit_detected.emit(target, target.global_position, Vector3.ZERO)
		hit_count += 1

		if not hit_multiple_targets:
			break

	# Visual feedback
	play_fire_sound(weapon_controller, weapon_data.fire_sound)

	print("[MeleeFireMode] Hit %d targets with combo level %d (%.1fx damage)" % [hit_count, current_combo_level, combo_mult])


func _find_targets_in_arc(weapon_controller: Node3D, camera: Camera3D) -> Array:
	var targets: Array = []

	var forward = -camera.global_basis.z
	var player_pos = camera.global_position

	# Get all physics bodies in range
	var space_state = weapon_controller.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = attack_range

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), player_pos)

	var player = weapon_controller.get_parent().get_parent().get_parent()
	query.exclude = [player] if player else []

	var results = space_state.intersect_shape(query)

	for result in results:
		var target = result.collider
		var to_target = (target.global_position - player_pos).normalized()

		# Check if within arc angle
		var angle = rad_to_deg(forward.angle_to(to_target))
		if angle <= attack_arc_angle:
			targets.append(target)

	return targets


func _play_attack_animation(weapon_controller: Node3D) -> void:
	# Simple position-based "swing" animation
	var weapon_holder = weapon_controller.get_node_or_null("WeaponPivot/WeaponHolder")
	if not weapon_holder:
		return

	var tween = weapon_controller.create_tween()

	# Wind-up
	tween.tween_property(weapon_holder, "rotation:y", deg_to_rad(-45), damage_delay)

	# Swing
	tween.tween_property(weapon_holder, "rotation:y", deg_to_rad(45), attack_duration - damage_delay)

	# Return
	tween.tween_property(weapon_holder, "rotation:y", 0, 0.2)


func get_combo_level() -> int:
	return current_combo_level


func reset_combo() -> void:
	current_combo_level = 0
	combo_timer = 0.0
