## FireMode.gd
## Base class for weapon fire modes (hitscan, projectile, melee, charged, etc.)
##
## HOW TO CREATE CUSTOM FIRE MODES:
## 1. Extend this class: class_name MyFireMode extends FireMode
## 2. Override fire() method with your firing logic
## 3. Override can_fire() for custom fire conditions
## 4. Use weapon_data.stats to access modified weapon stats
## 5. Emit fire_executed signal when fire completes
##
## EXAMPLE - Burst Fire Mode:
##   class_name BurstFireMode extends FireMode
##   @export var burst_count: int = 3
##   @export var burst_delay: float = 0.1
##
##   func fire(weapon_controller, weapon_data):
##       for i in burst_count:
##           _fire_single_shot(weapon_controller, weapon_data)
##           await weapon_controller.get_tree().create_timer(burst_delay).timeout
##       fire_executed.emit()
class_name FireMode
extends Resource

## Emitted when fire is successfully executed
signal fire_executed
## Emitted when fire is blocked (out of ammo, cooldown, etc.)
signal fire_blocked(reason: String)
## Emitted when projectile/hitscan hits something
signal hit_detected(target: Node3D, hit_point: Vector3, normal: Vector3)

## Display name for this fire mode
@export var mode_name: String = "Standard"

## Internal cooldown tracker
var cooldown_timer: float = 0.0


## Override this - execute the fire action
## weapon_controller: Reference to WeaponController node
## weapon_data: WeaponData resource with stats
func fire(_weapon_controller: Node3D, _weapon_data: Resource) -> void:
	push_error("FireMode.fire() must be overridden in subclass")


## Override this - check if weapon can fire (cooldown, ammo, etc.)
func can_fire(weapon_data: Resource) -> bool:
	# Check cooldown
	if cooldown_timer > 0:
		return false

	# Check ammo (if weapon uses ammo)
	if weapon_data.has("uses_ammo") and weapon_data.uses_ammo:
		if weapon_data.has("current_ammo") and weapon_data.current_ammo <= 0:
			return false

	return true


## Override this - called every frame to update cooldowns, etc.
func update(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta


## Override this - validate configuration in editor
func validate() -> Array[String]:
	var errors: Array[String] = []
	if mode_name.is_empty():
		errors.append("FireMode must have a mode_name")
	return errors


## Helper - start cooldown timer
func start_cooldown(fire_rate: float) -> void:
	cooldown_timer = fire_rate


## Helper - consume ammo from weapon data
func consume_ammo(weapon_data: Resource, amount: int = 1) -> bool:
	if not weapon_data.has("uses_ammo") or not weapon_data.uses_ammo:
		return true

	if not weapon_data.has("current_ammo"):
		return false

	var current = weapon_data.current_ammo
	if current < amount:
		return false

	weapon_data.current_ammo = current - amount
	return true


## Helper - perform raycast from camera center
func raycast_from_camera(weapon_controller: Node3D, max_range: float, exclude: Array = []) -> Dictionary:
	var camera = weapon_controller.get_viewport().get_camera_3d()
	if not camera:
		return {}

	var from = camera.global_position
	var to = from - camera.global_basis.z * max_range

	var space_state = weapon_controller.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	query.collide_with_areas = false

	return space_state.intersect_ray(query)


## Helper - apply spread to a direction vector
func apply_spread(direction: Vector3, spread_amount: float) -> Vector3:
	var spread_x = randf_range(-spread_amount, spread_amount)
	var spread_y = randf_range(-spread_amount, spread_amount)

	var right = direction.cross(Vector3.UP).normalized()
	var up = right.cross(direction).normalized()

	return (direction + right * spread_x + up * spread_y).normalized()


## Helper - spawn muzzle flash effect
func spawn_muzzle_flash(weapon_controller: Node3D, muzzle_flash_scene: PackedScene) -> void:
	if not muzzle_flash_scene:
		return

	var muzzle_point = weapon_controller.get_node_or_null("WeaponPivot/WeaponHolder/MuzzlePoint")
	if not muzzle_point:
		return

	var flash = muzzle_flash_scene.instantiate()
	muzzle_point.add_child(flash)


## Helper - play fire sound
func play_fire_sound(weapon_controller: Node3D, fire_sound: AudioStream) -> void:
	if not fire_sound:
		return

	var audio_player = weapon_controller.get_node_or_null("AudioStreamPlayer3D")
	if not audio_player:
		return

	audio_player.stream = fire_sound
	audio_player.play()
