## MovementState.gd
## Base class for movement states (walking, sprinting, sliding, etc.)
##
## NOTE: MovementConfig and MovementStateMachine must be defined before using this class
##
## HOW TO CREATE NEW MOVEMENT STATES:
## 1. Create new script extending MovementState
## 2. Override enter(), exit(), physics_update()
## 3. Call change_state() to transition to another state
## 4. Add state resource to MovementStateMachine
##
## EXAMPLE - Creating a Wall Run state:
##   class_name WallRunState extends MovementState
##   func can_enter() -> bool: return is_touching_wall()
##   func physics_update(delta): apply_wall_run_physics(delta)
##   func exit(): remove_wall_run_effects()
class_name MovementState
extends Resource

## Reference to the parent state machine
var state_machine: Node  # MovementStateMachine - can't use class_name due to circular dependency
## Reference to the character controller
var controller: CharacterBody3D
## Reference to movement config
var config: Resource  # MovementConfig

## Override - called when entering this state
func enter() -> void:
	pass

## Override - called when exiting this state
func exit() -> void:
	pass

## Override - called every physics frame while in this state
## Return the next state to transition to, or null to stay in this state
func physics_update(_delta: float) -> Resource:  # MovementState
	return null

## Override - called every frame for visual updates (not physics)
func process_update(_delta: float) -> void:
	pass

## Override - handle input events
func handle_input(_event: InputEvent) -> void:
	pass

## Override - check if this state can be entered from current state
## Used for state transition validation
func can_enter() -> bool:
	return true

## Override - get display name for debugging
func get_state_name() -> String:
	return get_class()

## Helper - change to another state
func change_state(new_state: Resource) -> Resource:  # MovementState
	return new_state

## Helper - get input direction in world space
func get_input_direction() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return (controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

## Helper - check if on floor with tolerance
func is_grounded() -> bool:
	return controller.is_on_floor()

## Helper - apply movement with acceleration/friction (with curve support)
func apply_movement(target_speed: float, acceleration: float, friction: float, delta: float) -> void:
	var direction = get_input_direction()

	if direction.length() > 0:
		# Calculate current speed ratio for curve sampling
		var current_speed = Vector2(controller.velocity.x, controller.velocity.z).length()
		var speed_ratio = clamp(current_speed / target_speed, 0.0, 1.0)

		# Apply acceleration curve if available
		var accel_multiplier = 1.0
		if config and config.move_acceleration_curve:
			accel_multiplier = config.move_acceleration_curve.sample(speed_ratio)

		# Accelerate towards target speed
		var target_velocity = direction * target_speed
		var effective_accel = acceleration * accel_multiplier
		controller.velocity.x = move_toward(controller.velocity.x, target_velocity.x, effective_accel * delta)
		controller.velocity.z = move_toward(controller.velocity.z, target_velocity.z, effective_accel * delta)
	else:
		# Calculate friction with curve
		var current_speed = Vector2(controller.velocity.x, controller.velocity.z).length()
		var speed_ratio = clamp(current_speed / target_speed, 0.0, 1.0) if target_speed > 0 else 0.0

		var friction_multiplier = 1.0
		if config and config.move_friction_curve:
			friction_multiplier = config.move_friction_curve.sample(speed_ratio)

		# Apply friction
		var effective_friction = friction * friction_multiplier
		controller.velocity.x = move_toward(controller.velocity.x, 0, effective_friction * delta)
		controller.velocity.z = move_toward(controller.velocity.z, 0, effective_friction * delta)

## Helper - apply gravity
func apply_gravity(delta: float, multiplier: float = 1.0) -> void:
	if not is_grounded():
		var gravity = config.get_gravity() if config else ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
		controller.velocity.y -= gravity * multiplier * delta
