class_name CharacterController
extends Node

var velocity: Vector3 = Vector3.ZERO
var wish_direction: Vector3 = Vector3.ZERO

var is_grounded: bool = false
var ground_normal: Vector3  = Vector3.UP
var ground_point: Vector3 = Vector3.ZERO

var last_position: Vector3 = Vector3.ZERO

var max_ground_speed: float = 10.0
var ground_acceleration: float = 10.0
var ground_friction: float = 10.0

var max_air_speed: float = 2.0
var air_acceleration: float = 2.0
var air_friction: float = 0.0

var jump_impulse: float = 8.0

var gravity: float = 20.0
var max_fall_speed: float = 40.0

var collision_radius: float = 0.4
var collision_height: float = 1.0
var step_height: float = 0.3

var max_slope_angle: float = 45.0

var body: CharacterBody3D
var collision_shape: CollisionShape3D

func init(_body: CharacterBody3D, _collision_shape: CollisionShape3D) -> void:
	body = _body
	collision_shape = _collision_shape
	body.
	
