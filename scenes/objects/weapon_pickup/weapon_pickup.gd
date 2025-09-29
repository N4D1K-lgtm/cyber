# WeaponPickup.gd
extends Node3D

@export var weapon_resource: WeaponData
@export var spin_speed: float = 90.0
@export var bob_amplitude: float = 0.1
@export var bob_speed: float = 2.0

@onready var mesh_instance = $MeshInstance3D
@onready var interaction_area = $InteractionArea
@onready var outline_material = preload("res://materials/outline_material.tres")

var base_y_position: float
var time_elapsed: float = 0.0
var is_highlighted: bool = false


func _ready():
	base_y_position = position.y
	if weapon_resource:
		mesh_instance.mesh = weapon_resource.pickup_mesh

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta):
	# Spinning
	rotation.y += deg_to_rad(spin_speed) * delta

	# Bobbing
	time_elapsed += delta
	position.y = base_y_position + sin(time_elapsed * bob_speed) * bob_amplitude


func _on_body_entered(body):
	if body.is_in_group("player"):
		highlight_pickup(true)
		if body.has_method("set_nearby_pickup"):
			body.set_nearby_pickup(self)


func _on_body_exited(body):
	if body.is_in_group("player"):
		highlight_pickup(false)
		if body.has_method("clear_nearby_pickup"):
			body.clear_nearby_pickup(self)


func highlight_pickup(enabled: bool):
	is_highlighted = enabled
	if enabled:
		mesh_instance.material_overlay = outline_material
	else:
		mesh_instance.material_overlay = null


func pickup():
	queue_free()
	return weapon_resource
