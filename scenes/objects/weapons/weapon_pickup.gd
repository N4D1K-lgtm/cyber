class_name WeaponPickup
extends RigidBody3D

## Handles weapon in pickup state
## When equipped, the weapon scene itself handles combat

@export var weapon_data: WeaponData
@export var current_ammo: int = -1  # -1 means use default from weapon_data
@export var reserve_ammo: int = -1  # -1 means use default from weapon_data

# Expose weapon_name as a property for easy access
var weapon_name: String:
	get:
		return weapon_data.weapon_name if weapon_data else "Unknown Weapon"

# Pickup animation
@export_group("Pickup Animation")
@export var spin_speed: float = 90.0
@export var bob_amplitude: float = 0.2
@export var bob_speed: float = 2.0

# Despawn settings
@export_group("Despawn Settings")
@export var despawn_warning_time: float = 5.0  # When to start flashing
@export var despawn_flash_curve: Curve  # Controls flash speed over time
@export var despawn_min_frequency: float = 1.0  # Slowest flash rate
@export var despawn_max_frequency: float = 3.0  # Fastest flash rate

# Internal state
var despawn_timer: float = 0.0
var base_y_position: float
var time_elapsed: float = 0.0
var player_nearby: Node = null

@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh_container: Node3D = $VisualContainer if has_node("VisualContainer") else null
@onready var outline_material = preload("res://materials/outline_material.tres") if ResourceLoader.exists("res://materials/outline_material.tres") else null

signal picked_up(by_player: Node)

func _ready():
	# Setup as pickup
	freeze = true  # RigidBody3D property - no physics until dropped
	collision_layer = 8  # Pickup layer
	collision_mask = 1  # Only collide with world
	
	base_y_position = position.y
	
	# Initialize ammo from weapon data if not overridden
	if weapon_data:
		if current_ammo == -1:
			current_ammo = weapon_data.magazine_size if weapon_data.start_with_full_ammo else weapon_data.magazine_size / 2
		if reserve_ammo == -1:
			reserve_ammo = weapon_data.max_reserve_ammo if weapon_data.start_with_full_ammo else weapon_data.max_reserve_ammo / 2
		
		# Setup despawn timer
		if weapon_data.should_despawn:
			despawn_timer = weapon_data.despawn_time
	
	# Setup interaction area if it exists
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = 2  # Player layer

func _process(delta):
	# Pickup animations
	if mesh_container:
		mesh_container.rotate_y(deg_to_rad(spin_speed) * delta)
	
	time_elapsed += delta * bob_speed
	position.y = base_y_position + sin(time_elapsed) * bob_amplitude
	
	# Despawn timer
	if weapon_data and weapon_data.should_despawn and despawn_timer > 0:
		despawn_timer -= delta
		
		# Flash when about to despawn
		if despawn_timer < despawn_warning_time:
			var flash_frequency: float
			
			if despawn_flash_curve:
				# Use curve to control flash rate (0 = about to despawn, 1 = just started warning)
				var t = despawn_timer / despawn_warning_time
				var curve_value = despawn_flash_curve.sample(t)
				flash_frequency = lerp(despawn_max_frequency, despawn_min_frequency, curve_value)
			else:
				# Fallback: linear interpolation
				var t = despawn_timer / despawn_warning_time
				flash_frequency = lerp(despawn_max_frequency, despawn_min_frequency, t)
			
			var flash_visible = sin(Time.get_ticks_msec() * 0.001 * flash_frequency * TAU) > 0
			if mesh_container:
				mesh_container.visible = flash_visible
		
		if despawn_timer <= 0:
			queue_free()

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	
	player_nearby = body
	
	if weapon_data and weapon_data.auto_pickup:
		attempt_pickup(body)
	else:
		highlight(true)
		if body.has_method("set_nearby_pickup"):
			body.set_nearby_pickup(self)

func _on_body_exited(body: Node3D):
	if body == player_nearby:
		player_nearby = null
		highlight(false)
		if body.has_method("clear_nearby_pickup"):
			body.clear_nearby_pickup(self)

func highlight(enabled: bool):
	if not mesh_container:
		return
	
	# Try to apply outline shader if we have one
	if outline_material:
		for child in mesh_container.get_children():
			_apply_outline_recursive(child, enabled)
	else:
		# Fallback: use emission or other visual indicator
		for child in mesh_container.get_children():
			_apply_emission_recursive(child, enabled)

func _apply_outline_recursive(node: Node, enabled: bool):
	"""Recursively apply outline material to all MeshInstances"""
	if node is MeshInstance3D:
		if enabled:
			node.material_overlay = outline_material
		else:
			node.material_overlay = null
	
	for child in node.get_children():
		_apply_outline_recursive(child, enabled)

func _apply_emission_recursive(node: Node, enabled: bool):
	"""Fallback: modify emission on existing materials"""
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count()):
			var mat = node.get_surface_override_material(i)
			if mat is StandardMaterial3D:
				mat.emission_enabled = enabled
				if enabled:
					mat.emission = Color(1.0, 0.8, 0.0)
					mat.emission_energy = 0.5
	
	for child in node.get_children():
		_apply_emission_recursive(child, enabled)

func attempt_pickup(player: Node) -> bool:
	"""Try to pick up this weapon"""
	if not player.has_method("pickup_weapon"):
		return false
	
	if player.pickup_weapon(self):
		picked_up.emit(player)
		queue_free()
		return true
	
	return false

func get_weapon_name() -> String:
	"""Get the weapon's display name"""
	return weapon_data.weapon_name if weapon_data else "Unknown Weapon"

func get_weapon_info() -> Dictionary:
	"""Return info about this weapon for the player's inventory"""
	return {
		"data": weapon_data,
		"current_ammo": current_ammo,
		"reserve_ammo": reserve_ammo,
		"name": get_weapon_name()
	}

func drop(drop_force: Vector3 = Vector3.ZERO):
	"""Called when this pickup is dropped by a player"""
	freeze = false  # Enable physics
	collision_layer = 8  # Pickup layer
	collision_mask = 1 | 16  # World and ground
	
	# Reset despawn timer
	if weapon_data and weapon_data.should_despawn:
		despawn_timer = weapon_data.despawn_time
	
	# Apply drop force
	if drop_force != Vector3.ZERO:
		apply_impulse(drop_force)
