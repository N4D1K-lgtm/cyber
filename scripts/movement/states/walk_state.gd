## WalkState.gd
## Default walking/running movement state
##
## FEATURES:
## - Ground movement with acceleration/friction
## - Automatic transitions to jump/fall
## - Coyote time for jump buffering
class_name WalkState
extends MovementState

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0


func get_state_name() -> String:
	return "Walk"


func enter() -> void:
	coyote_timer = 0.0


func physics_update(delta: float) -> Resource:  # MovementState
	# Update timers
	if is_grounded():
		coyote_timer = config.jump_coyote_time
	else:
		coyote_timer -= delta
		# If we left the ground and coyote time expired, fall
		if coyote_timer <= 0:
			return change_state(state_machine.state_table.get("Fall"))

	jump_buffer_timer -= delta

	# Apply movement
	apply_movement(
		config.move_speed,
		config.move_acceleration,
		config.move_friction,
		delta
	)

	# Apply gravity
	apply_gravity(delta)

	controller.move_and_slide()

	# Check transitions
	return _check_transitions()


func handle_input(event: InputEvent) -> void:
	# Jump input
	if event.is_action_pressed("jump"):
		jump_buffer_timer = config.jump_buffer_time


func _check_transitions() -> Resource:  # MovementState
	# Jump (if coyote time allows or buffered)
	if jump_buffer_timer > 0 and coyote_timer > 0:
		jump_buffer_timer = 0
		return change_state(state_machine.state_table.get("Jump"))

	# Sprint
	if Input.is_action_pressed("sprint") and get_input_direction().length() > 0:
		if state_machine.state_table.has("Sprint"):
			return change_state(state_machine.state_table.get("Sprint"))

	# Slide
	if config.slide_enabled and Input.is_action_just_pressed("crouch"):
		var speed = Vector2(controller.velocity.x, controller.velocity.z).length()
		if speed >= config.slide_min_speed and state_machine.state_table.has("Slide"):
			return change_state(state_machine.state_table.get("Slide"))

	# Crouch
	if config.crouch_enabled and Input.is_action_pressed("crouch"):
		if state_machine.state_table.has("Crouch"):
			return change_state(state_machine.state_table.get("Crouch"))

	return null
