# WeaponController.gd
extends Node3D

@onready var weapon_pivot = $WeaponPivot
@onready var weapon_holder = $WeaponPivot/WeaponHolder
@onready var animation_player = get_parent().get_node("AnimationPlayer")

var current_weapon = null
var current_weapon_scene_path: String = ""

signal weapon_equipped(weapon_name)
signal ammo_changed(current, reserve)

func equip_weapon(weapon_pickup):
	# Clear current weapon
	if current_weapon:
		current_weapon.queue_free()
	
	# Store the scene path for dropping later
	current_weapon_scene_path = weapon_pickup.scene_file_path
	
	# Remove from world and add to holder
	weapon_pickup.get_parent().remove_child(weapon_pickup)
	weapon_holder.add_child(weapon_pickup)
	
	current_weapon = weapon_pickup
	current_weapon.setup_equipped_mode()
	
	# Play equip animation
	play_equip_animation()
	
	emit_signal("weapon_equipped", current_weapon.weapon_name)
	
	# Update ammo display if weapon tracks ammo
	if current_weapon.has_method("get_ammo_info"):
		var ammo_info = current_weapon.get_ammo_info()
		emit_signal("ammo_changed", ammo_info.current, ammo_info.reserve)

func play_equip_animation():
	var tween = create_tween()
	weapon_holder.position.y = -0.3
	tween.tween_property(weapon_holder, "position:y", 0, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func fire():
	if current_weapon and current_weapon.has_method("fire"):
		# Just call fire, handle the async internally in the weapon
		current_weapon.fire()
		play_recoil_animation()
		# Update ammo
		if current_weapon.has_method("get_ammo_info"):
			var ammo_info = current_weapon.get_ammo_info()
			emit_signal("ammo_changed", ammo_info.current, ammo_info.reserve)

func play_recoil_animation():
	var tween = create_tween()
	tween.tween_property(weapon_holder, "position:z", 0.05, 0.05)
	tween.tween_property(weapon_holder, "rotation:x", deg_to_rad(-2), 0.05)
	tween.tween_property(weapon_holder, "position:z", 0, 0.15).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(weapon_holder, "rotation:x", 0, 0.15).set_ease(Tween.EASE_OUT)

func reload():
	if current_weapon and current_weapon.has_method("reload"):
		play_reload_animation()
		current_weapon.reload()
		# Update ammo after reload
		if current_weapon.has_method("get_ammo_info"):
			await get_tree().create_timer(current_weapon.reload_time).timeout
			var ammo_info = current_weapon.get_ammo_info()
			emit_signal("ammo_changed", ammo_info.current, ammo_info.reserve)

func play_reload_animation():
	var tween = create_tween()
	tween.tween_property(weapon_holder, "rotation:z", deg_to_rad(-45), 0.3)
	tween.tween_property(weapon_holder, "rotation:z", 0, 0.3)

func update_weapon_sway(mouse_delta: Vector2):
	if not weapon_pivot:
		return
	
	var sway_amount = 0.002
	var target_rotation = Vector3(
		mouse_delta.y * sway_amount,
		-mouse_delta.x * sway_amount,
		-mouse_delta.x * sway_amount * 0.5
	)
	
	weapon_pivot.rotation = weapon_pivot.rotation.lerp(target_rotation, 0.1)

func get_current_weapon_path():
	return current_weapon_scene_path

func clear_weapon():
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null
		current_weapon_scene_path = ""
