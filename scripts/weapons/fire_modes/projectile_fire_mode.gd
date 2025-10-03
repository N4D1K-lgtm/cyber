## ProjectileFireMode.gd
## Spawns physical projectiles (rockets, grenades, arrows, etc.)
##
## EDITOR SETUP:
## 1. Create ProjectileFireMode resource
## 2. Assign projectile_scene (must have RigidBody3D or Area3D root)
## 3. Set projectile_speed and other properties
## 4. Projectile scene should have script with methods:
##    - setup(damage: float, owner: Node3D) - called on spawn
##    - Optional: on_hit(target: Node3D, hit_point: Vector3)
##
## EXAMPLE PROJECTILE SCRIPT:
##   extends RigidBody3D
##   var damage: float = 10.0
##   var projectile_owner: Node3D
##
##   func setup(p_damage: float, p_owner: Node3D):
##       damage = p_damage
##       projectile_owner = p_owner
##
##   func _on_body_entered(body):
##       if body.has_method("take_damage"):
##           body.take_damage(damage)
##       queue_free()
class_name ProjectileFireMode
extends FireMode

@export_group("Projectile Properties")
## Projectile scene to spawn (must have RigidBody3D or Area3D root)
@export var projectile_scene: PackedScene

## Projectile speed in m/s
@export_range(1.0, 500.0, 1.0, "suffix:m/s") var projectile_speed: float = 50.0

## Use weapon spread for projectile accuracy
@export var use_weapon_spread: bool = true

## Additional projectile spread (added to weapon spread)
@export_range(0.0, 1.0, 0.01) var additional_spread: float = 0.0

## Inherit velocity from shooter
@export_range(0.0, 1.0, 0.05) var inherit_velocity: float = 0.0

## Spawn offset from muzzle (prevents self-collision)
@export_range(0.0, 5.0, 0.1, "suffix:m") var spawn_offset: float = 1.0

## Projectile gravity scale (0 = no gravity, 1 = normal, >1 = heavy)
@export_range(0.0, 10.0, 0.1) var gravity_scale: float = 1.0

## Projectile lifetime before auto-destroy (0 = infinite)
@export_range(0.0, 60.0, 0.5, "suffix:s") var lifetime: float = 10.0

@export_group("Multi-Shot")
## Number of projectiles to spawn per shot (for shotgun-style multi-projectile)
@export_range(1, 20, 1) var projectile_count: int = 1

## Spread angle for multi-projectile shots
@export_range(0.0, 45.0, 1.0, "suffix:°") var multi_shot_spread: float = 5.0


func fire(weapon_controller: Node3D, weapon_data: Resource) -> void:
	if not can_fire(weapon_data):
		fire_blocked.emit("Cannot fire")
		return

	if not projectile_scene:
		fire_blocked.emit("No projectile scene assigned")
		return

	# Consume ammo
	if not consume_ammo(weapon_data, 1):
		fire_blocked.emit("No ammo")
		return

	# Get stats
	var damage: float = weapon_data.stats.get_value("damage")
	var spread: float = 0.0
	if use_weapon_spread:
		spread = weapon_data.stats.get_value("bullet_spread") + additional_spread
	else:
		spread = additional_spread

	# Get shooter reference
	var shooter = weapon_controller.get_parent().get_parent().get_parent()

	# Spawn projectiles
	for i in projectile_count:
		_spawn_projectile(weapon_controller, shooter, damage, spread)

	# Effects
	spawn_muzzle_flash(weapon_controller, weapon_data.muzzle_flash_scene)
	play_fire_sound(weapon_controller, weapon_data.fire_sound)

	# Start cooldown
	start_cooldown(weapon_data.stats.get_value("fire_rate"))

	fire_executed.emit()


func _spawn_projectile(weapon_controller: Node3D, shooter: Node3D, damage: float, spread: float) -> void:
	var camera = weapon_controller.get_viewport().get_camera_3d()
	if not camera:
		return

	# Spawn projectile
	var projectile = projectile_scene.instantiate()
	weapon_controller.get_tree().current_scene.add_child(projectile)

	# Position at spawn point
	var spawn_pos = camera.global_position + (-camera.global_basis.z * spawn_offset)
	projectile.global_position = spawn_pos

	# Calculate direction with spread
	var direction = -camera.global_basis.z
	if spread > 0:
		direction = apply_spread(direction, spread)

	# For multi-shot, add additional spread
	if projectile_count > 1:
		var angle_offset = deg_to_rad(multi_shot_spread)
		var random_angle = randf_range(-angle_offset, angle_offset)
		direction = direction.rotated(Vector3.UP, random_angle)

	# Set velocity
	var velocity = direction * projectile_speed

	# Inherit shooter velocity
	if shooter is CharacterBody3D and inherit_velocity > 0:
		velocity += shooter.velocity * inherit_velocity

	# Apply to projectile
	if projectile is RigidBody3D:
		projectile.linear_velocity = velocity
		projectile.gravity_scale = gravity_scale
	elif projectile is Area3D:
		# For Area3D, store velocity and handle in projectile script
		if projectile.has_method("set_velocity"):
			projectile.set_velocity(velocity)

	# Setup projectile
	if projectile.has_method("setup"):
		projectile.setup(damage, shooter)

	# Set lifetime
	if lifetime > 0:
		await weapon_controller.get_tree().create_timer(lifetime).timeout
		if is_instance_valid(projectile):
			projectile.queue_free()


func validate() -> Array[String]:
	var errors = super.validate()
	if not projectile_scene:
		errors.append("ProjectileFireMode requires projectile_scene to be assigned")
	return errors
