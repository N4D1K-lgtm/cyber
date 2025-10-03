## PlayerControllerV2.gd
## Complete FPS player controller using the new movement and weapon systems
##
## SETUP:
## 1. Attach to CharacterBody3D root
## 2. Create child nodes as documented below
## 3. Assign movement_config and optional weapon_data
## 4. All input is handled automatically
extends CharacterBody3D

## ===== SIGNALS =====
signal health_changed(current: float, max_value: float)
signal died
signal entered_interaction_zone(interactable: Node3D)
signal exited_interaction_zone(interactable: Node3D)

## ===== NODE REFERENCES =====
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var movement_sm: Node = $MovementStateMachine
@onready var weapon_controller: Node3D = $CameraRig/Camera3D/WeaponController

# UI References (optional - checks for existence)
@onready var ui_ammo_current: Label = get_node_or_null("UI/HUD/AmmoDisplay/CurrentAmmo")
@onready var ui_ammo_reserve: Label = get_node_or_null("UI/HUD/AmmoDisplay/ReserveAmmo")
@onready var ui_weapon_name: Label = get_node_or_null("UI/HUD/WeaponInfo/WeaponName")
@onready var ui_interaction_prompt: Label = get_node_or_null("UI/InteractionPrompt")
@onready var ui_crosshair: Control = get_node_or_null("UI/HUD/Crosshair")
@onready var ui_health_bar: ProgressBar = get_node_or_null("UI/HUD/HealthBar")

## ===== CONFIGURATION =====
@export_group("Configuration")
## Movement configuration (required)
@export var movement_config: Resource  # MovementConfig

## Starting weapon data (optional)
@export var starting_weapon: Resource  # WeaponDataV2

## Player health
@export_range(1.0, 1000.0, 1.0) var max_health: float = 100.0

## Can take damage
@export var invulnerable: bool = false

@export_group("Camera")
## Camera vertical offset from player origin
@export var camera_height: float = 0.6

## Camera tilt on movement
@export var camera_tilt_enabled: bool = true
@export_range(0.0, 10.0, 0.1) var camera_tilt_amount: float = 2.0

@export_group("Interaction")
## Interaction range in meters
@export_range(0.5, 10.0, 0.1) var interaction_range: float = 3.0

## ===== STATE =====
var camera_rotation: Vector2 = Vector2.ZERO
var current_health: float = 100.0
var is_alive: bool = true
var nearby_interactables: Array = []
var bob_time: float = 0.0

## Camera smoothing accumulator
var camera_rotation_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Initialize
	current_health = max_health

	# Setup input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Setup collision
	add_to_group("player")
	collision_layer = 2  # Player layer
	collision_mask = 1   # World layer

	# Setup camera
	if camera:
		camera.position.y = camera_height

	# Setup weapon
	if starting_weapon and weapon_controller:
		weapon_controller.weapon_data = starting_weapon

	# Connect signals
	if weapon_controller:
		if weapon_controller.has_signal("weapon_equipped"):
			weapon_controller.weapon_equipped.connect(_on_weapon_equipped)
		if weapon_controller.has_signal("ammo_changed"):
			weapon_controller.ammo_changed.connect(_on_ammo_changed)

	if movement_sm and movement_sm.has_signal("state_changed"):
		movement_sm.state_changed.connect(_on_movement_state_changed)

	# Initialize UI
	_update_health_ui()
	_update_ammo_ui(0, 0)


func _input(event: InputEvent) -> void:
	if not is_alive:
		return

	# Mouse capture toggle
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

	# Camera look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_camera_look(event.relative)

	# Weapon input
	if weapon_controller and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("primary_action"):
			weapon_controller.handle_fire_pressed()

		if event.is_action_released("primary_action"):
			weapon_controller.handle_fire_released()

		if event.is_action_pressed("reload"):
			weapon_controller.handle_reload_pressed()

		if event.is_action_pressed("secondary_action"):
			_handle_secondary_action()

	# Interaction
	if event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Movement is handled by MovementStateMachine automatically

	# Update camera effects
	_update_camera_effects(delta)

	# Update weapon sway
	if weapon_controller and weapon_controller.has_method("update_sway"):
		var mouse_vel = camera_rotation_velocity * 50.0  # Scale for sway
		weapon_controller.update_sway(mouse_vel)


## Handle camera rotation with smoothing
func _handle_camera_look(mouse_delta: Vector2) -> void:
	if not movement_config:
		return

	var sensitivity = movement_config.camera_mouse_sensitivity
	var delta_rotation = mouse_delta * sensitivity

	# Apply smoothing if enabled
	if movement_config.camera_smoothing > 0:
		camera_rotation_velocity = camera_rotation_velocity.lerp(delta_rotation, 1.0 - movement_config.camera_smoothing)
		camera_rotation += camera_rotation_velocity
	else:
		camera_rotation += delta_rotation

	# Clamp vertical rotation
	var pitch_limit_down = deg_to_rad(movement_config.camera_pitch_limit_down)
	var pitch_limit_up = deg_to_rad(movement_config.camera_pitch_limit_up)
	camera_rotation.y = clamp(camera_rotation.y, -pitch_limit_down, pitch_limit_up)

	# Apply rotation
	rotation.y = -camera_rotation.x
	if camera_rig:
		camera_rig.rotation.x = -camera_rotation.y


## Update camera effects (bob, tilt, FOV)
func _update_camera_effects(delta: float) -> void:
	if not camera or not movement_config:
		return

	# Head bob
	if is_on_floor() and velocity.length() > 0.1:
		bob_time += delta * movement_config.camera_bob_frequency
		var bob_offset = sin(bob_time) * movement_config.camera_bob_intensity
		camera.position.y = camera_height + bob_offset
	else:
		bob_time = 0.0
		camera.position.y = lerp(camera.position.y, camera_height, delta * 10.0)

	# Movement tilt
	if camera_tilt_enabled:
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var target_tilt = -input_dir.x * deg_to_rad(camera_tilt_amount)
		camera.rotation.z = lerp(camera.rotation.z, target_tilt, delta * 10.0)

	# FOV scaling with speed
	if movement_config.camera_fov_speed_scale:
		var current_speed = Vector2(velocity.x, velocity.z).length()
		var speed_ratio = clamp(current_speed / movement_config.move_speed, 0.0, 1.0)
		var target_fov = movement_config.camera_base_fov + (speed_ratio * movement_config.camera_max_fov_bonus)
		camera.fov = lerp(camera.fov, target_fov, delta * 5.0)


## Try to interact with nearby interactable
func _try_interact() -> void:
	if nearby_interactables.is_empty():
		return

	# Get closest interactable
	var closest = _get_closest_interactable()
	if closest and closest.has_method("interact"):
		closest.interact(self)


## Get closest interactable in range
func _get_closest_interactable() -> Node3D:
	if nearby_interactables.is_empty():
		return null

	var closest: Node3D = null
	var closest_dist: float = INF

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue
		var dist = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = interactable

	return closest


## Secondary weapon action (aim down sights, alt fire, etc.)
func _handle_secondary_action() -> void:
	# Hook point for ADS, grenade throw, etc.
	pass


## Damage handling
func take_damage(amount: float, source: Node3D = null) -> void:
	if invulnerable or not is_alive:
		return

	current_health -= amount
	current_health = max(current_health, 0.0)

	health_changed.emit(current_health, max_health)
	_update_health_ui()

	if current_health <= 0:
		die()


## Healing
func heal(amount: float) -> void:
	if not is_alive:
		return

	current_health += amount
	current_health = min(current_health, max_health)

	health_changed.emit(current_health, max_health)
	_update_health_ui()


## Death
func die() -> void:
	if not is_alive:
		return

	is_alive = false
	died.emit()

	# Disable physics
	set_physics_process(false)

	# Release mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	print("[Player] Died")


## Add interactable to nearby list
func add_nearby_interactable(interactable: Node3D) -> void:
	if interactable not in nearby_interactables:
		nearby_interactables.append(interactable)
		entered_interaction_zone.emit(interactable)
		_update_interaction_ui()


## Remove interactable from nearby list
func remove_nearby_interactable(interactable: Node3D) -> void:
	var idx = nearby_interactables.find(interactable)
	if idx != -1:
		nearby_interactables.remove_at(idx)
		exited_interaction_zone.emit(interactable)
		_update_interaction_ui()


## Get current movement state name
func get_movement_state() -> String:
	if movement_sm and movement_sm.has_method("get_current_state_name"):
		return movement_sm.get_current_state_name()
	return "Unknown"


## Get current weapon
func get_current_weapon() -> Resource:
	if weapon_controller:
		return weapon_controller.weapon_data
	return null


## Equip weapon from weapon data
func equip_weapon(weapon_data: Resource) -> void:
	if weapon_controller and weapon_controller.has_method("equip_weapon"):
		weapon_controller.equip_weapon(weapon_data)


## ===== UI UPDATES =====
func _update_health_ui() -> void:
	if ui_health_bar:
		ui_health_bar.max_value = max_health
		ui_health_bar.value = current_health


func _update_ammo_ui(current: int, reserve: int) -> void:
	if ui_ammo_current:
		ui_ammo_current.text = str(current)
	if ui_ammo_reserve:
		ui_ammo_reserve.text = str(reserve)


func _update_interaction_ui() -> void:
	if not ui_interaction_prompt:
		return

	if nearby_interactables.is_empty():
		ui_interaction_prompt.visible = false
	else:
		ui_interaction_prompt.visible = true
		var closest = _get_closest_interactable()
		if closest:
			var name = closest.name
			if closest.has_method("get_interaction_text"):
				name = closest.get_interaction_text()
			ui_interaction_prompt.text = "[E] " + name


## ===== SIGNAL HANDLERS =====
func _on_weapon_equipped(weapon_name: String) -> void:
	if ui_weapon_name:
		ui_weapon_name.text = weapon_name

	print("[Player] Equipped: %s" % weapon_name)


func _on_ammo_changed(current: int, reserve: int) -> void:
	_update_ammo_ui(current, reserve)


func _on_movement_state_changed(from_state: String, to_state: String) -> void:
	print("[Player] Movement: %s → %s" % [from_state, to_state])

	# React to state changes (e.g., disable shooting while sliding)
	match to_state:
		"Slide":
			# Could disable weapon fire during slide
			pass
		"Jump":
			# Could trigger jump sound
			pass


## ===== DEBUG =====
func _unhandled_key_input(event: InputEvent) -> void:
	# Debug commands (remove in production)
	if OS.is_debug_build():
		if event.is_action_pressed("ui_page_up"):
			take_damage(10.0)
			print("[DEBUG] Took 10 damage")

		if event.is_action_pressed("ui_page_down"):
			heal(10.0)
			print("[DEBUG] Healed 10 HP")

		if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
			print("[DEBUG] Health: %.1f/%.1f" % [current_health, max_health])
			print("[DEBUG] State: %s" % get_movement_state())
			print("[DEBUG] Velocity: %s" % velocity)
