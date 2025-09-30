# Weapon.gd
extends Node3D

var weapon_data: WeaponData
var can_fire: bool = true
var is_reloading: bool = false

@onready var mesh_instance = $MeshInstance3D
@onready var muzzle_point = $MuzzlePoint
@onready var audio_player = $AudioStreamPlayer3D
@onready var animation_player = $AnimationPlayer

signal ammo_changed(current: int, reserve: int)
signal reload_started
signal reload_finished


func setup(data: WeaponData):
	weapon_data = data
	mesh_instance.mesh = weapon_data.equipped_mesh
	emit_signal("ammo_changed", weapon_data.current_ammo, weapon_data.reserve_ammo)


func fire():
	if not can_fire or is_reloading or weapon_data.current_ammo <= 0:
		return false

	can_fire = false
	weapon_data.current_ammo -= 1

	# Visual/Audio feedback
	if weapon_data.fire_sound:
		audio_player.stream = weapon_data.fire_sound
		audio_player.play()

	if weapon_data.muzzle_flash_scene:
		var flash = weapon_data.muzzle_flash_scene.instantiate()
		muzzle_point.add_child(flash)

	# Spawn projectile
	_spawn_projectile()

	emit_signal("ammo_changed", weapon_data.current_ammo, weapon_data.reserve_ammo)

	# Fire rate cooldown
	await get_tree().create_timer(weapon_data.fire_rate).timeout
	can_fire = true

	return true


func _spawn_projectile():
	# Create a simple raycast or projectile
	var space_state = get_world_3d().direct_space_state
	var camera = get_viewport().get_camera_3d()
	var from = camera.global_position
	var to = from - camera.global_basis.z * 1000.0

	# Add spread
	to += (
		Vector3(
			randf_range(-weapon_data.bullet_spread, weapon_data.bullet_spread),
			randf_range(-weapon_data.bullet_spread, weapon_data.bullet_spread),
			0
		)
		* 100.0
	)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent()]  # Exclude the player

	var result = space_state.intersect_ray(query)
	if result:
		# Handle hit
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(weapon_data.damage)


func reload():
	if is_reloading or weapon_data.current_ammo == weapon_data.magazine_size:
		return

	if weapon_data.reserve_ammo <= 0:
		return

	is_reloading = true
	emit_signal("reload_started")

	if weapon_data.reload_sound:
		audio_player.stream = weapon_data.reload_sound
		audio_player.play()

	if animation_player.has_animation("reload"):
		animation_player.play("reload")

	await get_tree().create_timer(weapon_data.reload_time).timeout

	# Calculate ammo transfer
	var needed = weapon_data.magazine_size - weapon_data.current_ammo
	var transfer = min(needed, weapon_data.reserve_ammo)
	weapon_data.current_ammo += transfer
	weapon_data.reserve_ammo -= transfer

	is_reloading = false
	emit_signal("ammo_changed", weapon_data.current_ammo, weapon_data.reserve_ammo)
	emit_signal("reload_finished")
