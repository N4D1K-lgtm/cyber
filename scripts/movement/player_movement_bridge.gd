## PlayerMovementBridge.gd
## Connects MovementStateMachine to Camera and visual effects
##
## SETUP:
## 1. Add as child of Player (CharacterBody3D)
## 2. Assign camera reference
## 3. Assign movement_sm reference
## 4. Automatically handles FOV, camera bob, crouch height, etc.
class_name PlayerMovementBridge
extends Node

## Camera to control
@export var camera: Camera3D

## Movement state machine to monitor
@export var movement_sm: Node  # MovementStateMachine

## Camera rig for vertical offset (optional)
@export var camera_rig: Node3D

## Collision shape to adjust for crouch/slide
@export var collision_shape: CollisionShape3D

## Player reference
var player: CharacterBody3D

## Camera state
var base_camera_height: float = 0.6
var current_camera_height: float = 0.6
var base_fov: float = 90.0
var current_fov: float = 90.0

## Collision state
var base_collision_height: float = 2.0
var base_collision_radius: float = 0.5

## Bob state
var bob_time: float = 0.0


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	if not player:
		push_error("PlayerMovementBridge must be child of CharacterBody3D")
		return

	# Get camera if not assigned
	if not camera:
		camera = player.get_node_or_null("CameraRig/Camera3D")
		if not camera:
			camera = player.get_node_or_null("Camera Rig/MainCamera")

	# Get camera rig if not assigned
	if not camera_rig:
		if camera:
			camera_rig = camera.get_parent() as Node3D

	# Get collision shape if not assigned
	if not collision_shape:
		collision_shape = player.get_node_or_null("CollisionShape3D")

	# Store base values
	if camera:
		base_camera_height = camera.position.y
		current_camera_height = base_camera_height
		base_fov = camera.fov
		current_fov = base_fov

	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		base_collision_height = capsule.height
		base_collision_radius = capsule.radius
	elif collision_shape and collision_shape.shape is CylinderShape3D:
		var cylinder = collision_shape.shape as CylinderShape3D
		base_collision_height = cylinder.height
		base_collision_radius = cylinder.radius

	# Get movement state machine if not assigned
	if not movement_sm:
		movement_sm = player.get_node_or_null("MovementStateMachine")

	# Connect to state changes
	if movement_sm and movement_sm.has_signal("state_changed"):
		movement_sm.state_changed.connect(_on_state_changed)


func _physics_process(delta: float) -> void:
	if not player or not camera:
		return

	var config = _get_config()
	if not config:
		return

	# Update camera height (crouch/slide)
	_update_camera_height(delta)

	# Update camera bob
	_update_camera_bob(delta, config)

	# Update FOV based on speed
	_update_fov(delta, config)


## Get current movement config
func _get_config() -> Resource:
	if movement_sm and "movement_config" in movement_sm:
		return movement_sm.movement_config
	return null


## Update camera height for crouch/slide
func _update_camera_height(delta: float) -> void:
	var target_height = base_camera_height
	var state_name = _get_current_state()

	var config = _get_config()
	if not config:
		return

	# Lower camera when crouching or sliding
	if state_name == "Slide":
		# Slide: lower camera significantly
		target_height = base_camera_height * 0.5

	# Smooth transition
	current_camera_height = lerp(current_camera_height, target_height, delta * 10.0)
	camera.position.y = current_camera_height


## Update camera bob
func _update_camera_bob(delta: float, config: Resource) -> void:
	if not "camera_bob_intensity" in config or not "camera_bob_frequency" in config:
		return

	var bob_intensity = config.camera_bob_intensity
	var bob_frequency = config.camera_bob_frequency

	if bob_intensity <= 0:
		return

	# Only bob when on ground and moving
	if player.is_on_floor() and player.velocity.length() > 0.1:
		bob_time += delta * bob_frequency * (player.velocity.length() / 5.0)
		var bob_offset = sin(bob_time) * bob_intensity
		camera.position.y = current_camera_height + bob_offset
	else:
		bob_time = 0.0
		# Smooth return to base height
		camera.position.y = lerp(camera.position.y, current_camera_height, delta * 10.0)


## Update FOV based on speed
func _update_fov(delta: float, config: Resource) -> void:
	if not "camera_fov_speed_scale" in config:
		return

	if not config.camera_fov_speed_scale:
		# Reset to base FOV
		camera.fov = lerp(camera.fov, base_fov, delta * 5.0)
		return

	# Get base FOV from config
	if "camera_base_fov" in config:
		base_fov = config.camera_base_fov
		current_fov = base_fov

	var max_fov_bonus = 10.0
	if "camera_max_fov_bonus" in config:
		max_fov_bonus = config.camera_max_fov_bonus

	# Calculate FOV based on state
	var state_name = _get_current_state()
	var target_fov = base_fov

	if state_name == "Sprint":
		# Increase FOV when sprinting
		if "sprint_fov_increase" in config:
			target_fov = base_fov + config.sprint_fov_increase
		else:
			target_fov = base_fov + max_fov_bonus
	else:
		# Scale FOV with speed
		var current_speed = Vector2(player.velocity.x, player.velocity.z).length()
		var max_speed = config.move_speed if "move_speed" in config else 5.0

		if state_name == "Sprint" and "sprint_speed_multiplier" in config:
			max_speed *= config.sprint_speed_multiplier

		var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
		target_fov = base_fov + (speed_ratio * max_fov_bonus)

	# Smooth transition
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)


## Adjust collision shape for crouch/slide
func _update_collision_shape(state_name: String) -> void:
	if not collision_shape:
		return

	var config = _get_config()
	if not config:
		return

	var target_height = base_collision_height
	var target_radius = base_collision_radius

	if state_name == "Slide" or state_name == "Crouch":
		var scale = 0.5
		if "crouch_height_scale" in config:
			scale = config.crouch_height_scale

		target_height = base_collision_height * scale

	# Apply to shape
	if collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		capsule.height = target_height
	elif collision_shape.shape is CylinderShape3D:
		var cylinder = collision_shape.shape as CylinderShape3D
		cylinder.height = target_height


## Get current state name
func _get_current_state() -> String:
	if movement_sm and movement_sm.has_method("get_current_state_name"):
		return movement_sm.get_current_state_name()
	return "Walk"


## Called when movement state changes
func _on_state_changed(from_state: String, to_state: String) -> void:
	_update_collision_shape(to_state)

	# Reset bob on state change
	if to_state != "Walk" and to_state != "Sprint":
		bob_time = 0.0
