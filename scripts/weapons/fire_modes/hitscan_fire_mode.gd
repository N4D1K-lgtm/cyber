## HitscanFireMode.gd
## Instant raycast-based firing (for rifles, pistols, snipers, etc.)
##
## EDITOR SETUP:
## 1. Create HitscanFireMode resource
## 2. Set pellet_count for shotgun spread (1 = single bullet)
## 3. Set penetration_count for wall penetration
## 4. Assign to WeaponData's fire_mode
##
## FEATURES:
## - Multi-pellet support (shotguns)
## - Penetration through multiple targets
## - Bullet spread with stat modifiers
## - Automatic damage falloff with distance
class_name HitscanFireMode
extends FireMode

@export_group("Hitscan Properties")
## Number of pellets per shot (for shotguns, set to 8-12)
@export_range(1, 50, 1) var pellet_count: int = 1

## Number of objects this can penetrate (0 = no penetration)
@export_range(0, 10, 1) var penetration_count: int = 0

## Damage multiplier per penetration (0.5 = 50% damage after each penetration)
@export_range(0.0, 1.0, 0.05) var penetration_damage_multiplier: float = 0.7

## Enable damage falloff over distance
@export var use_damage_falloff: bool = false

## Distance where damage starts to fall off
@export_range(0.0, 1000.0, 1.0, "suffix:m") var falloff_start_distance: float = 50.0

## Distance where damage reaches minimum
@export_range(0.0, 1000.0, 1.0, "suffix:m") var falloff_end_distance: float = 200.0

## Minimum damage multiplier at max range (0.1 = 10% damage)
@export_range(0.0, 1.0, 0.05) var min_damage_multiplier: float = 0.3

## Show debug lines for raycasts (editor only)
@export var debug_show_rays: bool = false


func fire(weapon_controller: Node3D, weapon_data: Resource) -> void:
	if not can_fire(weapon_data):
		fire_blocked.emit("Cannot fire")
		return

	# Consume ammo
	if not consume_ammo(weapon_data, 1):
		fire_blocked.emit("No ammo")
		return

	# Get stats
	var damage: float = weapon_data.stats.get_value("damage")
	var max_range: float = weapon_data.stats.get_value("max_range")
	var spread: float = weapon_data.stats.get_value("bullet_spread")

	# Get player for exclusion
	var player = weapon_controller.get_parent().get_parent().get_parent()
	var exclude = [player] if player else []

	# Fire pellets
	for i in pellet_count:
		_fire_pellet(weapon_controller, damage, max_range, spread, exclude)

	# Effects
	spawn_muzzle_flash(weapon_controller, weapon_data.muzzle_flash_scene)
	play_fire_sound(weapon_controller, weapon_data.fire_sound)

	# Start cooldown
	start_cooldown(weapon_data.stats.get_value("fire_rate"))

	fire_executed.emit()


func _fire_pellet(weapon_controller: Node3D, damage: float, max_range: float, spread: float, exclude: Array) -> void:
	var camera = weapon_controller.get_viewport().get_camera_3d()
	if not camera:
		return

	var from = camera.global_position
	var direction = -camera.global_basis.z

	# Apply spread
	if spread > 0:
		direction = apply_spread(direction, spread)

	var to = from + direction * max_range

	# Perform raycast with penetration
	var penetrations_remaining = penetration_count
	var current_damage = damage
	var current_from = from
	var current_exclude = exclude.duplicate()

	while true:
		var space_state = weapon_controller.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(current_from, to)
		query.exclude = current_exclude
		query.collide_with_areas = false

		var result = space_state.intersect_ray(query)

		if result.is_empty():
			break

		var hit_point = result.position
		var distance = current_from.distance_to(hit_point)

		# Calculate damage with falloff
		var final_damage = current_damage
		if use_damage_falloff:
			final_damage *= _calculate_damage_falloff(distance)

		# Apply damage to target
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(final_damage)

		hit_detected.emit(result.collider, hit_point, result.normal)

		# Debug visualization
		if debug_show_rays and OS.has_feature("editor"):
			_draw_debug_ray(current_from, hit_point, weapon_controller)

		# Check penetration
		if penetrations_remaining <= 0:
			break

		penetrations_remaining -= 1
		current_damage *= penetration_damage_multiplier
		current_from = hit_point + direction * 0.01  # Offset slightly
		current_exclude.append(result.collider)


func _calculate_damage_falloff(distance: float) -> float:
	if distance <= falloff_start_distance:
		return 1.0

	if distance >= falloff_end_distance:
		return min_damage_multiplier

	var t = (distance - falloff_start_distance) / (falloff_end_distance - falloff_start_distance)
	return lerp(1.0, min_damage_multiplier, t)


func _draw_debug_ray(from: Vector3, to: Vector3, weapon_controller: Node3D) -> void:
	var debug_line = MeshInstance3D.new()
	weapon_controller.get_tree().current_scene.add_child(debug_line)

	var immediate_mesh = ImmediateMesh.new()
	debug_line.mesh = immediate_mesh

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	# Auto-delete after 0.1 seconds
	await weapon_controller.get_tree().create_timer(0.1).timeout
	debug_line.queue_free()
