# class_name CameraRig
# extends Node3D
#
# @onready var camera: Camera3D = $Camera3D
#
# @export var mouse_sensitivity: float = 0.002
# @export var pitch_min: float = -1.5
# @export var pitch_max: float = 1.2
# @export var fov_smooth_speed: float = 10.0
# @export var base_fov: float = 90.0
# var target_fov: float = 90.0
# var fov_modifiers: Dictionary = {}
# var rotation_euler: Vector2 = Vector2.ZERO
#
# @export var shake_decay: float = 1.0
# @export var max_shake_offset: float = 0.1
# @export var max_shake_rotation: float = 0.05
# var shake_trauma: float = 0.0
# var shake_frequency: float = 20.0
#
# @export var head_bob_enabled: bool = true
# @export var bob_intensity: float = 0.05
# @export var bob_frequency: float = 10.0
# var bob_phase: float = 0.0

# func _ready() -> void:
# 	if not camera:
# 		push_warning("CameraRig: No Camera3D child")
# 		return
#
# 	camera.fov = base_fov
# 	target_fov = base_fov
#
# func _process(delta: float) -> void:
# 	if not camera:
# 		return
#
# 	# TODO:
#
# func _update_effects(delta: float) -> void:
# 	camera.position = Vector3.ZERO
# 	camera.rotation = Vector3.ZERO
#
# 	# TODO:
#
#
# func look(mouse_delta: Vector2) -> void:

