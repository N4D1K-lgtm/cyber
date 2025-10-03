## MovementConfig.gd
## Configuration resource for player movement - all values tunable in editor
##
## EDITOR SETUP:
## 1. Create new MovementConfig resource (Right-click in FileSystem → New Resource → MovementConfig)
## 2. Assign to PlayerController's @export var movement_config: MovementConfig
## 3. Tune values in Inspector to feel
## 4. Can create multiple configs for different character types (heavy, agile, etc.)
##
## EXTENDING:
## - Add new movement modes by creating MovementState scripts
## - Add modifiers via StatModifier for temporary speed boosts, etc.
## - Hook into signals for custom behavior (dash, wall-run, etc.)
@tool
class_name MovementConfig
extends Resource

## ===== BASIC MOVEMENT =====
@export_group("Basic Movement", "move_")
## Maximum movement speed in m/s
@export_range(0.1, 50.0, 0.1, "or_greater", "suffix:m/s") var move_speed: float = 5.0
## How quickly the player accelerates to max speed
@export_range(0.1, 100.0, 0.1, "or_greater", "suffix:m/s²") var move_acceleration: float = 50.0
## How quickly the player decelerates to stop
@export_range(0.1, 100.0, 0.1, "or_greater", "suffix:m/s²") var move_friction: float = 40.0
## How much control the player has in the air (0 = none, 1 = full ground control)
@export_range(0.0, 1.0, 0.01) var move_air_control: float = 0.3

## Acceleration curve (0-1 input → 0-1 acceleration multiplier)
## X-axis: normalized speed (0 = stopped, 1 = max speed)
## Y-axis: acceleration multiplier
@export var move_acceleration_curve: Curve

## Friction curve (0-1 speed → 0-1 friction multiplier)
@export var move_friction_curve: Curve

## ===== SPRINT =====
@export_group("Sprint", "sprint_")
## Sprint speed multiplier (e.g., 1.5 = 150% of normal speed)
@export_range(1.0, 3.0, 0.05) var sprint_speed_multiplier: float = 1.8
## FOV change when sprinting (degrees added to base FOV)
@export_range(0.0, 30.0, 0.5, "suffix:°") var sprint_fov_increase: float = 10.0
## Time to transition to sprint speed
@export_range(0.0, 2.0, 0.05, "suffix:s") var sprint_transition_time: float = 0.2
## If true, uses stamina system
@export var sprint_uses_stamina: bool = false
## Maximum stamina
@export_range(0.0, 1000.0, 10.0) var sprint_max_stamina: float = 100.0
## Stamina drain per second while sprinting
@export_range(0.0, 100.0, 1.0, "suffix:/s") var sprint_stamina_drain: float = 20.0
## Stamina regen per second while not sprinting
@export_range(0.0, 100.0, 1.0, "suffix:/s") var sprint_stamina_regen: float = 10.0

## ===== JUMP =====
@export_group("Jump", "jump_")
## Jump velocity (higher = jumps higher)
@export_range(0.1, 30.0, 0.1, "suffix:m/s") var jump_velocity: float = 4.5
## Time window after leaving ground where jump is still allowed (coyote time)
@export_range(0.0, 0.5, 0.01, "suffix:s") var jump_coyote_time: float = 0.1
## Time window before landing where jump input is buffered
@export_range(0.0, 0.5, 0.01, "suffix:s") var jump_buffer_time: float = 0.15
## Multiplier for gravity when falling (makes jumps feel more responsive)
@export_range(1.0, 5.0, 0.1) var jump_fall_gravity_multiplier: float = 1.5
## Allow bunny hopping (jumping immediately on land to maintain speed)
@export var jump_allow_bunny_hop: bool = false
## Speed boost when bunny hopping successfully
@export_range(0.0, 2.0, 0.05) var jump_bunny_hop_multiplier: float = 1.1

## ===== SLIDE =====
@export_group("Slide", "slide_")
## Enable sliding mechanic
@export var slide_enabled: bool = true
## Initial slide velocity boost
@export_range(0.0, 50.0, 0.5, "suffix:m/s") var slide_velocity: float = 10.0
## How long the slide lasts
@export_range(0.1, 5.0, 0.1, "suffix:s") var slide_duration: float = 0.8
## Cooldown before can slide again
@export_range(0.0, 5.0, 0.1, "suffix:s") var slide_cooldown: float = 1.0
## Minimum speed required to initiate slide
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var slide_min_speed: float = 3.0
## Deceleration during slide
@export_range(0.0, 50.0, 0.5, "suffix:m/s²") var slide_friction: float = 5.0

## ===== CROUCH =====
@export_group("Crouch", "crouch_")
## Enable crouching
@export var crouch_enabled: bool = true
## Crouch speed multiplier
@export_range(0.1, 1.0, 0.05) var crouch_speed_multiplier: float = 0.5
## How much to scale the collision shape when crouched
@export_range(0.1, 1.0, 0.05) var crouch_height_scale: float = 0.5
## Time to transition to crouch
@export_range(0.0, 1.0, 0.05, "suffix:s") var crouch_transition_time: float = 0.2

## ===== CAMERA =====
@export_group("Camera", "camera_")
## Mouse sensitivity
@export_range(0.001, 0.1, 0.001) var camera_mouse_sensitivity: float = 0.002
## Vertical look limits (degrees)
@export_range(0.0, 89.0, 1.0, "suffix:°") var camera_pitch_limit_down: float = 85.0
@export_range(0.0, 89.0, 1.0, "suffix:°") var camera_pitch_limit_up: float = 85.0
## Camera smoothing (0 = instant, higher = smoother)
@export_range(0.0, 1.0, 0.01) var camera_smoothing: float = 0.0
## FOV changes with speed (for sprint effect)
@export var camera_fov_speed_scale: bool = false
## Base FOV
@export_range(60.0, 120.0, 1.0, "suffix:°") var camera_base_fov: float = 90.0
## Additional FOV at max speed
@export_range(0.0, 30.0, 1.0, "suffix:°") var camera_max_fov_bonus: float = 10.0

## Head bob intensity
@export_range(0.0, 1.0, 0.01) var camera_bob_intensity: float = 0.1
## Head bob frequency
@export_range(0.0, 20.0, 0.1) var camera_bob_frequency: float = 10.0

## ===== ADVANCED =====
@export_group("Advanced", "advanced_")
## Slope angle limit for walking (degrees)
@export_range(0.0, 89.0, 1.0, "suffix:°") var advanced_max_slope_angle: float = 45.0
## Step height for automatically climbing stairs
@export_range(0.0, 2.0, 0.05, "suffix:m") var advanced_step_height: float = 0.3
## Snap distance to keep player grounded on slopes
@export_range(0.0, 2.0, 0.05, "suffix:m") var advanced_floor_snap_length: float = 0.5
## Use custom gravity (if 0, uses project default)
@export var advanced_custom_gravity: float = 0.0

## Movement feel curve (speed → responsiveness)
## Make movement feel "heavy" at low speeds, "light" at high speeds
@export var advanced_movement_feel_curve: Curve

## ===== NETWORK =====
@export_group("Network", "net_")
## Enable client-side prediction
@export var net_enable_prediction: bool = true
## Enable server reconciliation
@export var net_enable_reconciliation: bool = true
## Number of states to keep for reconciliation
@export_range(10, 120, 1) var net_state_buffer_size: int = 60


## Validate configuration in editor
func _validate_property(property: Dictionary) -> void:
	# Hide stamina settings if not using stamina
	if property.name.begins_with("sprint_stamina") or property.name == "sprint_max_stamina":
		if not sprint_uses_stamina:
			property.usage = PROPERTY_USAGE_NO_EDITOR

	# Hide slide settings if slide disabled
	if property.name.begins_with("slide_") and property.name != "slide_enabled":
		if not slide_enabled:
			property.usage = PROPERTY_USAGE_NO_EDITOR

	# Hide crouch settings if crouch disabled
	if property.name.begins_with("crouch_") and property.name != "crouch_enabled":
		if not crouch_enabled:
			property.usage = PROPERTY_USAGE_NO_EDITOR


## Initialize default values if properties are null (for existing resources)
func _init() -> void:
	# Set defaults for camera properties if they're null
	if camera_mouse_sensitivity == null:
		camera_mouse_sensitivity = 0.002
	if camera_pitch_limit_down == null:
		camera_pitch_limit_down = 85.0
	if camera_pitch_limit_up == null:
		camera_pitch_limit_up = 85.0
	if camera_smoothing == null:
		camera_smoothing = 0.0
	if camera_fov_speed_scale == null:
		camera_fov_speed_scale = false
	if camera_base_fov == null:
		camera_base_fov = 90.0
	if camera_max_fov_bonus == null:
		camera_max_fov_bonus = 10.0
	if camera_bob_intensity == null:
		camera_bob_intensity = 0.08
	if camera_bob_frequency == null:
		camera_bob_frequency = 10.0


## Get effective gravity (custom or project default)
func get_gravity() -> float:
	if advanced_custom_gravity != 0.0:
		return advanced_custom_gravity
	return ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
