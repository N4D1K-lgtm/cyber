## MovementStateMachine.gd
## State machine for player movement - handles state transitions and lifecycle
##
## NOTE: MovementState and MovementConfig must be defined before using this class
##
## EDITOR SETUP:
## 1. Add this as a child node to your CharacterBody3D
## 2. Assign movement_config resource
## 3. Create MovementState resources and add to states array
## 4. Set initial_state to your default state (usually "Walk")
##
## CREATING CUSTOM STATES:
## See MovementState.gd for instructions on creating new states
##
## HOOK POINTS:
## - state_changed signal: Called on every state transition
## - Register plugins to add behavior without modifying core states
class_name MovementStateMachine
extends Node

## Emitted when state changes
signal state_changed(from_state: String, to_state: String)

## Movement configuration resource
@export var movement_config: Resource  # MovementConfig

## Available movement states (add custom states here!)
@export var states: Array = []  # Array of MovementState

## Name of the initial state to start in
@export var initial_state_name: String = "Walk"

## Current active state
var current_state: Resource  # MovementState
## Reference to the character controller
var controller: CharacterBody3D
## State lookup table
var state_table: Dictionary = {}

## For debugging - track state history
var state_history: Array[String] = []
var max_history_size: int = 10


func _ready() -> void:
	controller = get_parent() as CharacterBody3D
	if not controller:
		push_error("MovementStateMachine must be child of CharacterBody3D")
		return

	if not movement_config:
		push_warning("No MovementConfig assigned to MovementStateMachine")

	# Instantiate states if they are scripts
	var instantiated_states: Array = []
	for state in states:
		if state is GDScript:
			# It's a script, create an instance
			var instance = state.new()
			instantiated_states.append(instance)
		else:
			# It's already an instance
			instantiated_states.append(state)
	states = instantiated_states

	# Build state lookup table
	_build_state_table()

	# Initialize states
	for state in states:
		state.state_machine = self
		state.controller = controller
		state.config = movement_config

	# Enter initial state
	_change_state_by_name(initial_state_name)


func _physics_process(delta: float) -> void:
	if not current_state:
		return

	# Update current state and check for transitions
	var next_state = current_state.physics_update(delta)
	if next_state and next_state != current_state:
		_change_state(next_state)


func _process(delta: float) -> void:
	if current_state:
		current_state.process_update(delta)


func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


## Change to a specific state instance
func _change_state(new_state: Resource) -> void:  # MovementState
	if new_state == current_state:
		return

	if not new_state.can_enter():
		return

	var old_state_name = current_state.get_state_name() if current_state else "None"

	# Exit current state
	if current_state:
		current_state.exit()

	# Enter new state
	current_state = new_state
	current_state.enter()

	var new_state_name = current_state.get_state_name()

	# Emit signals and track history
	state_changed.emit(old_state_name, new_state_name)
	_add_to_history(new_state_name)

	print("[MovementStateMachine] State: %s → %s" % [old_state_name, new_state_name])


## Change state by name (string lookup)
func _change_state_by_name(state_name: String) -> void:
	if state_table.has(state_name):
		_change_state(state_table[state_name])
	else:
		push_error("State not found: %s" % state_name)


## Build lookup table for states
func _build_state_table() -> void:
	state_table.clear()
	for state in states:
		var state_name = state.get_state_name()
		state_table[state_name] = state


## Get current state name
func get_current_state_name() -> String:
	return current_state.get_state_name() if current_state else "None"


## Force change to a state by name (for external systems)
func force_state(state_name: String) -> bool:
	if state_table.has(state_name):
		_change_state(state_table[state_name])
		return true
	return false


## Check if currently in a specific state
func is_in_state(state_name: String) -> bool:
	return get_current_state_name() == state_name


## Add to state history for debugging
func _add_to_history(state_name: String) -> void:
	state_history.append(state_name)
	if state_history.size() > max_history_size:
		state_history.remove_at(0)


## Get state history as string
func get_state_history() -> String:
	return " → ".join(state_history)
