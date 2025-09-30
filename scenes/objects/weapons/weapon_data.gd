class_name WeaponData
extends Resource

@export_group("Basic Info")
@export var weapon_name: String = "Unknown Weapon"
@export var weapon_model: PackedScene 

@export_group("Pickup")
@export var should_despawn: bool = true
@export var despawn_time: float = 30.0
@export var auto_pickup: bool = false

@export_group("Combat")
@export var damage: float = 10.0
@export var fire_rate: float = 0.2 
@export var is_automatic: bool = true
@export var max_range: float = 100.0

@export_group("Ammo")
@export var magazine_size: int = 30
@export var max_reserve_ammo: int = 90
@export var reload_time: float = 2.0
@export var start_with_full_ammo: bool = true

@export_group("Accuracy")
@export var bullet_spread: float = 0.02
@export var aim_spread_multiplier: float = 0.25 

@export_group("Audio")
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
@export var empty_sound: AudioStream

@export_group("Effects")
@export var muzzle_flash_scene: PackedScene
@export var projectile_scene: PackedScene 
@export var is_hitscan: bool = true
