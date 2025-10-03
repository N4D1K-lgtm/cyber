## JumpState.gd
## Jumping state with configurable jump height and gravity
class_name JumpState
extends MovementState


func get_state_name() -> String:
	return "Jump"


func enter() -> void:
	controller.velocity.y = config.jump_velocity


func physics_update(delta: float) -> Resource:  # MovementState
	# Air movement with reduced control
	var air_accel = config.move_acceleration * config.move_air_control
	var air_friction = config.move_friction * config.move_air_control

	apply_movement(
		config.move_speed,
		air_accel,
		air_friction,
		delta
	)

	# Apply gravity (enhanced when falling)
	var gravity_mult = config.jump_fall_gravity_multiplier if controller.velocity.y < 0 else 1.0
	apply_gravity(delta, gravity_mult)

	controller.move_and_slide()

	# Transition to fall when moving downward
	if controller.velocity.y < 0:
		return change_state(state_machine.state_table.get("Fall"))

	return null
