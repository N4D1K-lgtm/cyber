## SprintState.gd
## Sprinting state with optional stamina system
class_name SprintState
extends MovementState

var current_stamina: float
var sprint_transition_time: float = 0.0


func get_state_name() -> String:
	return "Sprint"


func enter() -> void:
	if config and config.sprint_uses_stamina:
		current_stamina = config.sprint_max_stamina

	sprint_transition_time = 0.0


func exit() -> void:
	sprint_transition_time = 0.0


func physics_update(delta: float) -> Resource:  # MovementState
	if not config:
		return change_state(state_machine.state_table.get("Walk"))

	# Update transition timer
	sprint_transition_time += delta

	# Handle stamina
	if config.sprint_uses_stamina:
		current_stamina -= config.sprint_stamina_drain * delta
		if current_stamina <= 0:
			return change_state(state_machine.state_table.get("Walk"))

	# Calculate sprint speed with transition
	var base_sprint_speed = config.move_speed * config.sprint_speed_multiplier
	var target_speed = base_sprint_speed

	# Smooth speed ramp-up
	var transition_duration = config.sprint_transition_time if "sprint_transition_time" in config else 0.2
	if sprint_transition_time < transition_duration:
		var t = sprint_transition_time / transition_duration
		target_speed = lerp(config.move_speed, base_sprint_speed, t)

	# Apply movement at sprint speed
	apply_movement(
		target_speed,
		config.move_acceleration,
		config.move_friction,
		delta
	)

	# Apply gravity
	apply_gravity(delta)

	controller.move_and_slide()

	# Check transitions
	return _check_transitions()


func _check_transitions() -> Resource:  # MovementState
	# Stop sprinting if not moving or not holding sprint
	if not Input.is_action_pressed("sprint") or get_input_direction().length() == 0:
		return change_state(state_machine.state_table.get("Walk"))

	# Jump from sprint
	if Input.is_action_just_pressed("jump") and is_grounded():
		return change_state(state_machine.state_table.get("Jump"))

	# Slide from sprint
	if config.slide_enabled and Input.is_action_just_pressed("crouch"):
		if state_machine.state_table.has("Slide"):
			return change_state(state_machine.state_table.get("Slide"))

	# Fall if left ground
	if not is_grounded():
		return change_state(state_machine.state_table.get("Fall"))

	return null
