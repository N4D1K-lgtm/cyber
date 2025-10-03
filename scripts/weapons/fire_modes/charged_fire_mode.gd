## ChargedFireMode.gd
## Hold to charge, release to fire (for laser weapons, railguns, bows, etc.)
##
## EDITOR SETUP:
## 1. Create ChargedFireMode resource
## 2. Set min/max_charge_time and damage multipliers
## 3. Optionally assign charge_sound and charge_particle_effect
## 4. Configure actual fire behavior (uses_hitscan or projectile_on_release)
##
## FEATURES:
## - Damage scales with charge time
## - Visual/audio feedback during charge
## - Can release early for reduced damage
## - Can overcharge for bonus effects
class_name ChargedFireMode
extends FireMode

@export_group("Charge Properties")
## Minimum time to charge before can fire (seconds)
@export_range(0.0, 10.0, 0.1, "suffix:s") var min_charge_time: float = 0.5

## Maximum charge time for full power (seconds)
@export_range(0.0, 10.0, 0.1, "suffix:s") var max_charge_time: float = 3.0

## Damage multiplier at minimum charge
@export_range(0.1, 10.0, 0.1) var min_charge_damage_multiplier: float = 0.5

## Damage multiplier at maximum charge
@export_range(0.1, 10.0, 0.1) var max_charge_damage_multiplier: float = 3.0

## If true, auto-fires when fully charged
@export var auto_fire_when_charged: bool = false

## If true, drains ammo continuously while charging
@export var drain_ammo_while_charging: bool = false

## Ammo drain rate per second while charging
@export_range(0.0, 100.0, 1.0, "suffix:/s") var ammo_drain_rate: float = 5.0

@export_group("Charge Effects")
## Sound to loop during charging
@export var charge_sound: AudioStream

## Particle effect during charging (spawned at muzzle)
@export var charge_particle_effect: PackedScene

## Camera shake intensity during charge (0 = none)
@export_range(0.0, 10.0, 0.1) var charge_shake_intensity: float = 0.0

@export_group("Release Behavior")
## Fire mode when released: true = hitscan, false = projectile
@export var uses_hitscan: bool = true

## Projectile to spawn on release (if not hitscan)
@export var projectile_scene: PackedScene

## Projectile speed multiplier based on charge (1.0 = no scaling)
@export_range(0.0, 10.0, 0.1) var projectile_speed_charge_multiplier: float = 1.0

## Max range for hitscan
@export_range(1.0, 10000.0, 10.0, "suffix:m") var hitscan_max_range: float = 1000.0

## Internal state
var is_charging: bool = false
var charge_time: float = 0.0
var charge_audio_player: AudioStreamPlayer3D
var charge_particles: Node3D


func fire(weapon_controller: Node3D, weapon_data: Resource) -> void:
	if not can_fire(weapon_data):
		fire_blocked.emit("Cannot fire")
		return

	# Start charging
	_start_charge(weapon_controller, weapon_data)


func update(delta: float) -> void:
	super.update(delta)

	if is_charging:
		charge_time += delta

		# Auto-fire when fully charged
		if auto_fire_when_charged and charge_time >= max_charge_time:
			_release_charge(null, null)  # Will be called with proper params


func _start_charge(weapon_controller: Node3D, weapon_data: Resource) -> void:
	is_charging = true
	charge_time = 0.0

	# Play charge sound
	if charge_sound:
		charge_audio_player = AudioStreamPlayer3D.new()
		weapon_controller.add_child(charge_audio_player)
		charge_audio_player.stream = charge_sound
		charge_audio_player.play()

	# Spawn charge particles
	if charge_particle_effect:
		var muzzle = weapon_controller.get_node_or_null("WeaponPivot/WeaponHolder/MuzzlePoint")
		if muzzle:
			charge_particles = charge_particle_effect.instantiate()
			muzzle.add_child(charge_particles)

	print("[ChargedFireMode] Charging started...")


func _release_charge(weapon_controller: Node3D, weapon_data: Resource) -> void:
	if not is_charging:
		return

	# Check minimum charge time
	if charge_time < min_charge_time:
		fire_blocked.emit("Not charged enough")
		_cancel_charge()
		return

	# Calculate charge percentage
	var charge_percent = clamp(charge_time / max_charge_time, 0.0, 1.0)
	var damage_multiplier = lerp(min_charge_damage_multiplier, max_charge_damage_multiplier, charge_percent)

	# Get damage
	var base_damage = weapon_data.stats.get_value("damage")
	var final_damage = base_damage * damage_multiplier

	print("[ChargedFireMode] Released at %.0f%% charge (%.1fx damage)" % [charge_percent * 100, damage_multiplier])

	# Consume ammo
	if not consume_ammo(weapon_data, 1):
		fire_blocked.emit("No ammo")
		_cancel_charge()
		return

	# Fire based on mode
	if uses_hitscan:
		_fire_hitscan(weapon_controller, weapon_data, final_damage)
	else:
		_fire_projectile(weapon_controller, weapon_data, final_damage, charge_percent)

	# Effects
	spawn_muzzle_flash(weapon_controller, weapon_data.muzzle_flash_scene)
	play_fire_sound(weapon_controller, weapon_data.fire_sound)

	# Cleanup
	_cancel_charge()

	# Start cooldown
	start_cooldown(weapon_data.stats.get_value("fire_rate"))

	fire_executed.emit()


func _cancel_charge() -> void:
	is_charging = false
	charge_time = 0.0

	if charge_audio_player:
		charge_audio_player.queue_free()
		charge_audio_player = null

	if charge_particles:
		charge_particles.queue_free()
		charge_particles = null


func _fire_hitscan(weapon_controller: Node3D, weapon_data: Resource, damage: float) -> void:
	var camera = weapon_controller.get_viewport().get_camera_3d()
	if not camera:
		return

	var from = camera.global_position
	var to = from - camera.global_basis.z * hitscan_max_range

	var space_state = weapon_controller.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)

	var player = weapon_controller.get_parent().get_parent().get_parent()
	query.exclude = [player] if player else []

	var result = space_state.intersect_ray(query)
	if result:
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(damage)
		hit_detected.emit(result.collider, result.position, result.normal)


func _fire_projectile(weapon_controller: Node3D, weapon_data: Resource, damage: float, charge_percent: float) -> void:
	if not projectile_scene:
		return

	var camera = weapon_controller.get_viewport().get_camera_3d()
	if not camera:
		return

	var projectile = projectile_scene.instantiate()
	weapon_controller.get_tree().current_scene.add_child(projectile)

	projectile.global_position = camera.global_position + (-camera.global_basis.z * 1.0)

	var direction = -camera.global_basis.z
	var base_speed = 50.0  # Default, should come from projectile config
	var speed = base_speed * (1.0 + (charge_percent * (projectile_speed_charge_multiplier - 1.0)))

	if projectile is RigidBody3D:
		projectile.linear_velocity = direction * speed

	if projectile.has_method("setup"):
		var shooter = weapon_controller.get_parent().get_parent().get_parent()
		projectile.setup(damage, shooter)


## Called from weapon controller when input is released
func on_input_released(weapon_controller: Node3D, weapon_data: Resource) -> void:
	if is_charging:
		_release_charge(weapon_controller, weapon_data)


func validate() -> Array[String]:
	var errors = super.validate()
	if not uses_hitscan and not projectile_scene:
		errors.append("ChargedFireMode with projectile mode requires projectile_scene")
	return errors
