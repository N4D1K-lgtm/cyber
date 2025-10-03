## WeaponControllerV2.gd
## Network-ready weapon controller with full fire mode support
##
## NOTE: WeaponDataV2, StatModifier must be defined before using this class
##
## EDITOR SETUP:
## 1. Add as child to Camera3D in player scene
## 2. Create child nodes:
##    - WeaponPivot (Node3D) - for weapon sway
##      - WeaponHolder (Node3D) - for animations
##        - MuzzlePoint (Marker3D) - spawn point for effects
## 3. Add AudioStreamPlayer3D as sibling
## 4. Assign weapon_data (WeaponDataV2 resource)
##
## NETWORK NOTES:
## - Client sends fire input to server
## - Server validates and executes
## - Client predicts for responsiveness
## - Visual effects play immediately on client
class_name WeaponControllerV2
extends Node3D

## Emitted when weapon fires
signal weapon_fired
## Emitted when weapon equipped
signal weapon_equipped(weapon_name: String)
## Emitted when ammo changes
signal ammo_changed(current: int, reserve: int)
## Emitted when reload starts
signal reload_started
## Emitted when reload finishes
signal reload_finished

@export_group("Configuration")
## Current weapon data
@export var weapon_data: Resource:  # WeaponDataV2
	set(value):
		weapon_data = value
		if weapon_data:
			_setup_weapon()

## Enable weapon sway
@export var enable_sway: bool = true

## Sway amount multiplier
@export_range(0.0, 1.0, 0.01) var sway_amount: float = 0.002

@export_group("Network")
## Is this the local player's weapon? (for input handling)
@export var is_local_player: bool = true

## Enable client-side prediction
@export var enable_prediction: bool = true

@export_group("Node References")
@onready var weapon_pivot: Node3D = $WeaponPivot
@onready var weapon_holder: Node3D = $WeaponPivot/WeaponHolder
@onready var muzzle_point: Marker3D = $WeaponPivot/WeaponHolder/MuzzlePoint
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

## Current weapon instance
var current_weapon_instance: Node3D

## Input state (for charged weapons)
var is_fire_pressed: bool = false


func _ready() -> void:
	if weapon_data:
		_setup_weapon()


func _process(delta: float) -> void:
	if weapon_data:
		weapon_data.update(delta)


func _physics_process(_delta: float) -> void:
	# Handle automatic fire
	if is_fire_pressed and weapon_data and weapon_data.is_automatic:
		fire()


## Setup weapon when data is assigned
func _setup_weapon() -> void:
	# Clear existing weapon
	if current_weapon_instance:
		current_weapon_instance.queue_free()

	# Instantiate weapon model
	if weapon_data.weapon_model:
		current_weapon_instance = weapon_data.weapon_model.instantiate()
		weapon_holder.add_child(current_weapon_instance)

	# Create muzzle point if missing
	if not muzzle_point:
		muzzle_point = Marker3D.new()
		muzzle_point.name = "MuzzlePoint"
		weapon_holder.add_child(muzzle_point)

	weapon_data.equip()
	weapon_equipped.emit(weapon_data.weapon_name)
	_update_ammo_display()

	print("[WeaponControllerV2] Equipped: %s" % weapon_data.weapon_name)


## Fire weapon (call from input)
func fire() -> bool:
	if not weapon_data or not weapon_data.fire_mode:
		return false

	# TODO: For multiplayer, send RPC to server here
	# For now, execute locally
	return _execute_fire()


## Execute fire (server authoritative)
func _execute_fire() -> bool:
	if not weapon_data.fire_mode.can_fire(weapon_data):
		return false

	# Fire mode handles everything
	weapon_data.fire_mode.fire(self, weapon_data)

	weapon_fired.emit()
	_update_ammo_display()

	# Play recoil animation
	_play_recoil_animation()

	return true


## Reload weapon
func reload() -> bool:
	if not weapon_data:
		return false

	if not weapon_data.reload():
		return false

	reload_started.emit()

	# Play reload animation
	_play_reload_animation()

	# Play reload sound
	if weapon_data.reload_sound:
		audio_player.stream = weapon_data.reload_sound
		audio_player.play()

	# Wait for reload time
	await get_tree().create_timer(weapon_data.reload_time).timeout

	weapon_data.finish_reload()
	reload_finished.emit()
	_update_ammo_display()

	print("[WeaponControllerV2] Reload complete: %d/%d" % [weapon_data.current_ammo, weapon_data.reserve_ammo])

	return true


## Handle input (call from player controller)
func handle_fire_pressed() -> void:
	is_fire_pressed = true

	# For charged weapons, start charging
	if weapon_data and weapon_data.fire_mode and weapon_data.fire_mode.has_method("on_input_released"):
		weapon_data.fire_mode.fire(self, weapon_data)
	# For non-automatic, fire once
	elif weapon_data and not weapon_data.is_automatic:
		fire()


## Handle input release
func handle_fire_released() -> void:
	is_fire_pressed = false

	# For charged weapons, release charge
	if weapon_data and weapon_data.fire_mode and weapon_data.fire_mode.has_method("on_input_released"):
		weapon_data.fire_mode.on_input_released(self, weapon_data)


## Handle reload input
func handle_reload_pressed() -> void:
	reload()


## Update weapon sway based on mouse movement
func update_sway(mouse_delta: Vector2) -> void:
	if not enable_sway or not weapon_pivot:
		return

	var target_rotation = Vector3(
		mouse_delta.y * sway_amount,
		-mouse_delta.x * sway_amount,
		-mouse_delta.x * sway_amount * 0.5
	)

	weapon_pivot.rotation = weapon_pivot.rotation.lerp(target_rotation, 0.1)


## Play recoil animation
func _play_recoil_animation() -> void:
	if not weapon_holder:
		return

	var recoil_strength = weapon_data.get_stat("recoil") if weapon_data else 1.0

	var tween = create_tween()
	tween.tween_property(weapon_holder, "position:z", 0.05 * recoil_strength, 0.05)
	tween.tween_property(weapon_holder, "rotation:x", deg_to_rad(-2 * recoil_strength), 0.05)
	tween.tween_property(weapon_holder, "position:z", 0, 0.15).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(weapon_holder, "rotation:x", 0, 0.15).set_ease(Tween.EASE_OUT)


## Play reload animation
func _play_reload_animation() -> void:
	if not weapon_holder:
		return

	var tween = create_tween()
	tween.tween_property(weapon_holder, "rotation:z", deg_to_rad(-45), 0.3)
	tween.tween_property(weapon_holder, "rotation:z", 0, 0.3)


## Play equip animation
func _play_equip_animation() -> void:
	if not weapon_holder:
		return

	weapon_holder.position.y = -0.3
	var tween = create_tween()
	tween.tween_property(weapon_holder, "position:y", 0, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## Update ammo display
func _update_ammo_display() -> void:
	if not weapon_data:
		return

	var ammo_info = weapon_data.get_ammo_info()
	ammo_changed.emit(ammo_info.current, ammo_info.reserve)


## Equip a new weapon
func equip_weapon(new_weapon_data: Resource) -> void:  # WeaponDataV2
	if weapon_data:
		weapon_data.unequip()

	weapon_data = new_weapon_data
	_play_equip_animation()


## Get current weapon name
func get_weapon_name() -> String:
	return weapon_data.weapon_name if weapon_data else ""


## Check if weapon can fire
func can_fire() -> bool:
	if not weapon_data or not weapon_data.fire_mode:
		return false
	return weapon_data.fire_mode.can_fire(weapon_data)


## Add modifier to current weapon
func add_weapon_modifier(modifier: Resource) -> void:  # StatModifier
	if weapon_data:
		weapon_data.add_modifier(modifier)


## Remove modifier from current weapon
func remove_weapon_modifier(modifier: Resource) -> void:  # StatModifier
	if weapon_data:
		weapon_data.remove_modifier(modifier)


## Debug: Print weapon stats
func debug_print_weapon() -> void:
	if weapon_data:
		weapon_data.debug_print_stats()
