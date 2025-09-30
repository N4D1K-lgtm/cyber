extends CharacterBody3D

@onready var MainCamera = $"Camera Rig/MainCamera"
@onready var CameraRig = $"Camera Rig"
@onready var weapon_controller = $"Camera Rig/MainCamera/WeaponController"
@onready var weapon_animator = $"Camera Rig/MainCamera/WeaponAnimator"

# UI elements
@onready var interaction_prompt = $UI/InteractionPrompt
@onready var crosshair = $UI/HUD/Crosshair
@onready var current_ammo_label = $UI/HUD/AmmoDisplay/CurrentAmmo
@onready var reserve_ammo_label = $UI/HUD/AmmoDisplay/ReserveAmmo
@onready var ammo_separator = $UI/HUD/AmmoDisplay/Separator
@onready var weapon_name_label = $UI/HUD/WeaponInfo/WeaponName
@onready var fire_mode_label = $UI/HUD/WeaponInfo/FireMode

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var CameraRotation = Vector2(0, 0)
var MouseSensitivity = 0.01
var nearby_pickup = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	
	# Setup UI
	ammo_separator.text = " / "
	
	# Connect weapon controller signals
	weapon_controller.weapon_equipped.connect(_on_weapon_equipped)
	weapon_controller.ammo_changed.connect(_on_ammo_changed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
	
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * MouseSensitivity
		CameraLook(MouseEvent)
		weapon_controller.update_weapon_sway(event.relative)
	
	# Weapon pickup with E
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E and nearby_pickup:
			pickup_weapon(nearby_pickup)
		# Drop weapon with G
		if event.keycode == KEY_G:
			drop_current_weapon()
		# Reload with R
		if event.keycode == KEY_R:
			weapon_controller.reload()
	
	# Fire weapon
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				weapon_controller.fire()

func CameraLook(Movement: Vector2):
	CameraRotation += Movement
	CameraRotation.y = clamp(CameraRotation.y, -1.5, 1.2)
	
	transform.basis = Basis()
	rotate_object_local(Vector3(0, 1, 0), -CameraRotation.x)
	
	CameraRig.transform.basis = Basis()
	CameraRig.rotate_object_local(Vector3(1, 0, 0), -CameraRotation.y)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	# Update weapon bob
	if weapon_animator:
		weapon_animator.update_bob(velocity, delta)
	
	# Auto fire for automatic weapons
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if weapon_controller.current_weapon and weapon_controller.current_weapon.is_automatic:
			weapon_controller.fire()

func set_nearby_pickup(pickup):
	nearby_pickup = pickup
	interaction_prompt.visible = true
	interaction_prompt.text = "Press [E] to pickup " + pickup.weapon_name

func clear_nearby_pickup(pickup):
	if nearby_pickup == pickup:
		nearby_pickup = null
		interaction_prompt.visible = false

func pickup_weapon(pickup):
	weapon_controller.equip_weapon(pickup)
	nearby_pickup = null
	interaction_prompt.visible = false

func drop_current_weapon():
	var weapon_path = weapon_controller.get_current_weapon_path()
	if weapon_path == "":
		return
	
	# Load and spawn the weapon as a pickup
	var weapon_scene = load(weapon_path)
	if weapon_scene:
		var pickup = weapon_scene.instantiate()
		pickup.global_position = global_position + transform.basis.z * -2 + Vector3.UP
		get_parent().add_child(pickup)
		
		weapon_controller.clear_weapon()
		print("Dropped weapon")

func _on_weapon_equipped(weapon_name):
	weapon_name_label.text = weapon_name
	# You can determine fire mode based on weapon

func _on_ammo_changed(current, reserve):
	current_ammo_label.text = str(current)
	reserve_ammo_label.text = str(reserve)
