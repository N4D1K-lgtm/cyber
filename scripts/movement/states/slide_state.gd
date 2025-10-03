## SlideState.gd
## Sliding state with momentum preservation
class_name SlideState
extends MovementState

var slide_timer: float = 0.0
var slide_direction: Vector3


func get_state_name() -> String:
	return "Slide"


func can_enter() -> bool:
	var speed = Vector2(controller.velocity.x, controller.velocity.z).length()
	return speed >= config.slide_min_speed


func enter() -> void:
	slide_timer = config.slide_duration

	# Capture current movement direction
	slide_direction = Vector3(controller.velocity.x, 0, controller.velocity.z).normalized()
	if slide_direction.length() == 0:
		slide_direction = -controller.global_transform.basis.z

	# Apply initial slide boost
	controller.velocity.x = slide_direction.x * config.slide_velocity
	controller.velocity.z = slide_direction.z * config.slide_velocity


func physics_update(delta: float) -> Resource:  # MovementState
	slide_timer -= delta

	# Apply friction to slide
	var current_speed = Vector2(controller.velocity.x, controller.velocity.z).length()
	var new_speed = max(current_speed - config.slide_friction * delta, config.move_speed * 0.5)

	controller.velocity.x = slide_direction.x * new_speed
	controller.velocity.z = slide_direction.z * new_speed

	apply_gravity(delta)

	controller.move_and_slide()

	# End slide
	if slide_timer <= 0 or not is_grounded():
		if is_grounded():
			return change_state(state_machine.state_table.get("Walk"))
		else:
			return change_state(state_machine.state_table.get("Fall"))

	# Can jump out of slide
	if Input.is_action_just_pressed("jump"):
		return change_state(state_machine.state_table.get("Jump"))

	return null
