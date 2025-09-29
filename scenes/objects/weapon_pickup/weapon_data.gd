# WeaponData.gd
class_name WeaponData
extends Resource

@export var weapon_name: String = "Unknown Weapon"
@export var pickup_mesh: Mesh
@export var equipped_mesh: Mesh

# Firing properties
@export var damage: float = 10.0
@export var fire_rate: float = 0.2  # Time between shots
@export var magazine_size: int = 30
@export var reload_time: float = 2.0
@export var bullet_spread: float = 0.02
@export var projectile_speed: float = 50.0

# Ammo
@export var current_ammo: int = 30
@export var reserve_ammo: int = 90
@export var max_reserve_ammo: int = 120

# Audio/Visual
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
@export var muzzle_flash_scene: PackedScene

# Optional special properties
@export var is_automatic: bool = true
@export var has_burst_fire: bool = false
@export var burst_count: int = 3
