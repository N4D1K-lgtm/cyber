# Quick Start Guide - Building Your FPS Player

This guide walks you through creating a complete FPS player controller from scratch using the systems.

---

## Part 1: Create Movement Configuration

### Step 1: Create MovementConfig Resource

1. In Godot's **FileSystem** panel, right-click in a folder (e.g., `resources/`)
2. Select **New Resource**
3. In the search box, type: `MovementConfig`
4. Select `MovementConfig` and click **Create**
5. Name it: `default_movement_config.tres`
6. **Save** (Ctrl+S)

### Step 2: Configure Movement Settings

1. Click on `default_movement_config.tres` to open it in **Inspector**
2. You'll see all the tunable parameters:

**Recommended Starting Values:**
```
Basic Movement:
  Move Speed: 5.0
  Move Acceleration: 50.0
  Move Friction: 40.0
  Move Air Control: 0.3

Sprint:
  Sprint Speed Multiplier: 1.8
  Sprint FOV Increase: 10.0
  Sprint Uses Stamina: false

Jump:
  Jump Velocity: 4.5
  Jump Coyote Time: 0.1
  Jump Buffer Time: 0.15
  Jump Fall Gravity Multiplier: 1.5

Slide:
  Slide Enabled: true
  Slide Velocity: 10.0
  Slide Duration: 0.8
  Slide Min Speed: 3.0

Crouch:
  Crouch Enabled: true
  Crouch Speed Multiplier: 0.5
```

3. **Save** the resource

---

## Part 2: Create Movement States

Movement states are **NOT** created as separate .tres files. They are **scripts** that you assign directly in the Inspector.

### Step 1: Create State Resources in Inspector

1. In your **Scene** panel, you'll add these to MovementStateMachine later
2. For now, understand that states are **built-in** - you just reference the scripts

The built-in states are:
- `scripts/movement/states/walk_state.gd`
- `scripts/movement/states/jump_state.gd`
- `scripts/movement/states/fall_state.gd`
- `scripts/movement/states/sprint_state.gd`
- `scripts/movement/states/slide_state.gd`

---

## Part 3: Build Player Scene

### Step 1: Create Player Node Structure

1. Create new scene (Scene → New Scene)
2. Add root node: **CharacterBody3D**
3. Name it: `Player`
4. Add children:

```
Player (CharacterBody3D)
├─ CollisionShape3D
├─ CameraRig (Node3D)
│  └─ Camera3D
└─ MovementStateMachine (Node)
```

**How to add MovementStateMachine:**
1. Right-click on `Player`
2. Add Child Node
3. Search for `Node`
4. Click **Create**
5. Name it `MovementStateMachine`
6. In Inspector, click **Attach Script**
7. Navigate to: `scripts/movement/movement_state_machine.gd`
8. Click **Load** (don't create new script!)

### Step 2: Configure CollisionShape3D

1. Select `CollisionShape3D`
2. In Inspector → **Shape**, click `<empty>`
3. Select **New CapsuleShape3D**
4. Adjust size (Height: 2.0, Radius: 0.5)

### Step 3: Configure Camera

1. Select `Camera3D`
2. Position: Y = 0.6 (eye level)
3. In Inspector, check **Current** (makes it the active camera)

---

## Part 4: Configure Movement State Machine

### Step 1: Assign Movement Config

1. Select `MovementStateMachine` node
2. In Inspector, find **Movement Config** property
3. Click `<empty>` dropdown
4. Select **Load**
5. Navigate to `default_movement_config.tres`
6. Click **Open**

### Step 2: Add State Scripts

**This is the critical part!**

The **States** array needs the state script files. The system will automatically create instances at runtime.

1. In Inspector, find **States** array property
2. Click the array to expand it
3. Change **Size** from `0` to `5`
4. You now see 5 empty slots: `[0]`, `[1]`, `[2]`, `[3]`, `[4]`

**For each slot, you'll load a script file:**

**Slot [0] - WalkState:**
1. Click `<empty>` dropdown
2. Select **Quick Load** (or **Load**)
3. Navigate to: `scripts/movement/states/walk_state.gd`
4. Click **Open**

**Slot [1] - JumpState:**
1. Click `<empty>` dropdown
2. Select **Quick Load**
3. Navigate to: `scripts/movement/states/jump_state.gd`
4. Click **Open**

**Slot [2] - FallState:**
1. Click `<empty>` dropdown
2. Select **Quick Load**
3. Navigate to: `scripts/movement/states/fall_state.gd`
4. Click **Open**

**Slot [3] - SprintState:**
1. Click `<empty>` dropdown
2. Select **Quick Load**
3. Navigate to: `scripts/movement/states/sprint_state.gd`
4. Click **Open**

**Slot [4] - SlideState:**
1. Click `<empty>` dropdown
2. Select **Quick Load**
3. Navigate to: `scripts/movement/states/slide_state.gd`
4. Click **Open**

**What you should see:** Each slot should show the script icon and filename (e.g., `walk_state.gd`)

### Step 3: Set Initial State

1. In Inspector, find **Initial State Name** property
2. Type: `Walk`

---

## Part 5: Create Player Input Script

### Step 1: Attach Script to Player

1. Select `Player` (CharacterBody3D root)
2. Click **Attach Script** button (scroll icon)
3. Path: `res://scenes/player/player_controller.gd`
4. Click **Create**

### Step 2: Write Player Script

Replace the generated script with this:

```gdscript
extends CharacterBody3D

@onready var camera_rig = $CameraRig
@onready var camera = $CameraRig/Camera3D
@onready var movement_sm = $MovementStateMachine

# Camera control
var camera_rotation: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.002


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	# Release mouse on ESC
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Recapture mouse on click
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

	# Camera look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.relative)


func rotate_camera(mouse_delta: Vector2):
	camera_rotation.x -= mouse_delta.x * mouse_sensitivity
	camera_rotation.y -= mouse_delta.y * mouse_sensitivity
	camera_rotation.y = clamp(camera_rotation.y, -1.5, 1.2)

	# Rotate player body horizontally
	rotation.y = camera_rotation.x

	# Rotate camera vertically
	camera_rig.rotation.x = camera_rotation.y


func _physics_process(_delta):
	# The movement state machine handles all movement!
	# States read Input automatically
	pass
```

**Save the script** (Ctrl+S)

---

## Part 6: Test Movement

### Step 1: Add Player to Main Scene

1. Open `scenes/main.tscn`
2. Instance your Player scene:
   - Click **Instantiate Scene** button (chain link icon)
   - Select your `Player.tscn`
   - Position it above the ground (Y = 2.0)

### Step 2: Run and Test

1. Press **F5** to run
2. You should be able to:
   - **WASD** - Walk around
   - **Mouse** - Look around
   - **Space** - Jump
   - **Shift** - Sprint
   - **Ctrl** - Crouch/Slide

**If movement doesn't work:**
- Check that MovementStateMachine has all 5 states assigned
- Check that Movement Config is assigned
- Check Console for errors

---

## Part 7: Add Weapon System

### Step 1: Create Weapon Data

1. Right-click in FileSystem → **New Resource**
2. Search: `WeaponDataV2`
3. Click **Create**
4. Name: `pistol_weapon_data.tres`
5. **Save**

### Step 2: Configure Weapon

Select `pistol_weapon_data.tres` in Inspector:

```
Identification:
  Weapon Name: "Pistol"
  Weapon Type: Pistol

Fire Mode: (click <empty>)
  → Quick Load → New Resource → Search "HitscanFireMode"
  → Create

  Hitscan Properties (in the fire mode):
    Pellet Count: 1
    Penetration Count: 0
    Use Damage Falloff: false

Base Stats:
  Base Damage: 25.0
  Base Fire Rate: 0.3
  Base Max Range: 100.0
  Base Bullet Spread: 0.02

Ammo System:
  Uses Ammo: true
  Current Ammo: 12
  Magazine Size: 12
  Reserve Ammo: 60
  Reload Time: 1.5
```

**Save the resource**

### Step 3: Add Weapon Controller to Player

Modify player scene:

```
Player (CharacterBody3D)
├─ CollisionShape3D
├─ CameraRig (Node3D)
│  ├─ Camera3D
│  │  └─ WeaponController (Node3D)  ← ADD THIS
│  │     ├─ WeaponPivot (Node3D)    ← ADD THIS
│  │     │  └─ WeaponHolder (Node3D) ← ADD THIS
│  │     └─ AudioStreamPlayer3D     ← ADD THIS
└─ MovementStateMachine (Node)
```

**Steps:**
1. Right-click on `Camera3D` → Add Child Node → **Node3D**
2. Name it `WeaponController`
3. **Attach Script**: `scripts/weapons/weapon_controller_v2.gd`
4. Add child **Node3D** to WeaponController, name it `WeaponPivot`
5. Add child **Node3D** to WeaponPivot, name it `WeaponHolder`
6. Add child **AudioStreamPlayer3D** to WeaponController

### Step 4: Configure Weapon Controller

1. Select `WeaponController`
2. In Inspector:
   - **Weapon Data**: Load → `pistol_weapon_data.tres`
   - **Is Local Player**: ✓ (checked)

### Step 5: Add Weapon Input

Edit `player_controller.gd`, add to `_input()`:

```gdscript
@onready var weapon_controller = $CameraRig/Camera3D/WeaponController

func _input(event):
	# ... existing camera code ...

	# Weapon controls
	if event.is_action_pressed("primary_action"):
		weapon_controller.handle_fire_pressed()

	if event.is_action_released("primary_action"):
		weapon_controller.handle_fire_released()

	if event.is_action_pressed("reload"):
		weapon_controller.handle_reload_pressed()
```

### Step 6: Test Weapons

1. Press **F5**
2. **Left Click** - Fire weapon
3. **R** - Reload
4. Watch console for hit detection

---

## Part 8: Add UI (Optional)

Create a simple HUD to see ammo:

1. Add **Control** node to Player
2. Name it `UI`
3. Set **Layout** → Full Rect
4. Add **Label** child, name it `AmmoLabel`
5. Position it bottom-right

**Update player script:**

```gdscript
@onready var ammo_label = $UI/AmmoLabel

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon_controller.ammo_changed.connect(_on_ammo_changed)

func _on_ammo_changed(current, reserve):
	ammo_label.text = "%d / %d" % [current, reserve]
```

---

## Common Issues & Solutions

### "States array is empty" or "Can't call non-static function"
- You forgot to add state scripts to the States array in MovementStateMachine
- Each state should be a `.gd` script file (the system creates instances automatically)
- Use **Quick Load** or **Load** to select the script files from `scripts/movement/states/`

### "Movement doesn't work"
- Check Input Map in Project Settings has: move_up, move_down, move_left, move_right, jump, sprint, crouch
- Check MovementConfig is assigned
- Check Initial State Name is "Walk"

### "Weapon doesn't fire"
- Check WeaponData has FireMode assigned
- Check Input Map has "primary_action" (Left Mouse Button)
- Check weapon_controller reference in player script

### "Can't find class MovementState"
- This is normal - they use duck typing
- As long as no red errors in editor, it works

### "How do I create a state resource?"
- You DON'T create .tres files for states
- You load the .gd script files directly in the States array

---

## Next Steps

Now that you have a working player:

1. **Add more weapons** - Create new WeaponDataV2 resources
2. **Create different fire modes** - Try ProjectileFireMode, ChargedFireMode
3. **Add upgrades** - Use StatModifier resources
4. **Customize movement** - Tune MovementConfig values
5. **Add custom states** - Create WallRunState, DashState, etc.

See **SYSTEMS_GUIDE.md** for advanced usage and extension points.
