## FallState.gd
## Falling/airborne state
class_name FallState
extends MovementState


func get_state_name() -> String:
	return "Fall"


func physics_update(delta: float) -> Resource:  # MovementState
	# Air movement
	var air_accel = config.move_acceleration * config.move_air_control
	var air_friction = config.move_friction * config.move_air_control

	apply_movement(
		config.move_speed,
		air_accel,
		air_friction,
		delta
	)

	# Enhanced fall gravity
	apply_gravity(delta, config.jump_fall_gravity_multiplier)

	controller.move_and_slide()

	# Land
	if is_grounded():
		return change_state(state_machine.state_table.get("Walk"))

	return null
