# Player Script Migration Guide

## Old vs New Player Controller

### What Changed?

| Feature | Old (`player.gd`) | New (`player_controller_v2.gd`) |
|---------|-------------------|----------------------------------|
| **Movement** | Hardcoded in `_physics_process()` | MovementStateMachine handles all |
| **Camera** | Basic rotation only | Curves, smoothing, FOV scaling, bob, tilt |
| **Weapons** | Direct fire calls | Proper input handling with charge support |
| **Health** | Not implemented | Full health/damage system |
| **Interaction** | Weapon pickup only | Generic interactable system |
| **UI Updates** | Manual string updates | Signal-based with null checks |
| **Tunability** | Constants in code | All parameters in MovementConfig |
| **Curves** | None | Acceleration, friction, feel curves |

---

## Migration Steps

### Step 1: Update Your Player Scene

**Old Node Structure:**
```
Player (CharacterBody3D)
├─ Camera Rig (Node3D)
│  └─ MainCamera (Camera3D)
│     ├─ WeaponController
│     └─ WeaponAnimator
├─ CollisionShape3D
└─ UI
```

**New Node Structure:**
```
Player (CharacterBody3D)
├─ CameraRig (Node3D)
│  └─ Camera3D
│     └─ WeaponController (Node3D)  ← Uses weapon_controller_v2.gd
│        ├─ WeaponPivot (Node3D)
│        │  └─ WeaponHolder (Node3D)
│        └─ AudioStreamPlayer3D
├─ CollisionShape3D
├─ MovementStateMachine (Node)  ← NEW! Handles all movement
└─ UI  ← Optional, supports same labels
```

**Key Changes:**
- Rename `Camera Rig` → `CameraRig` (no space)
- Rename `MainCamera` → `Camera3D`
- Add `MovementStateMachine` node
- Remove `WeaponAnimator` (functionality moved to WeaponController)

---

### Step 2: Replace Player Script

**Old Script Attachment:**
```
Player → Attach Script → player.gd
```

**New Script Attachment:**
```
Player → Attach Script → player_controller_v2.gd
```

**Or** copy the new script content and replace your old one.

---

### Step 3: Configure MovementStateMachine

See **QUICKSTART.md** for detailed steps:

1. Create MovementConfig resource
2. Assign to MovementStateMachine
3. Add 5 movement states to States array
4. Set Initial State Name to "Walk"

---

### Step 4: Update Weapon Controller

**Old:**
```gdscript
weapon_controller.fire()  # Direct call
weapon_controller.reload()  # Direct call
```

**New:**
```gdscript
weapon_controller.handle_fire_pressed()    # On press
weapon_controller.handle_fire_released()   # On release
weapon_controller.handle_reload_pressed()  # Reload
```

**Why:** Supports charged weapons and proper input states.

---

### Step 5: Add Curves (Optional but Recommended)

1. Open your `MovementConfig` resource
2. Create acceleration curve:
   - **Move Acceleration Curve** → New Curve
   - Add point (0.0, 1.5) for snappy start
   - Add point (1.0, 0.5) for smooth cap
3. Create friction curve:
   - **Move Friction Curve** → New Curve
   - Add point (0.0, 1.0)
   - Add point (1.0, 1.2) for sticky stop

See **CURVES_GUIDE.md** for presets and recipes.

---

## Feature Comparison

### Camera System

**Old:**
```gdscript
var MouseSensitivity = 0.01  # Hardcoded
CameraRotation.y = clamp(CameraRotation.y, -1.5, 1.2)  # Hardcoded limits
```

**New:**
```gdscript
# All in MovementConfig resource:
camera_mouse_sensitivity: 0.002
camera_pitch_limit_down: 85.0
camera_pitch_limit_up: 85.0
camera_smoothing: 0.0  # NEW!
camera_fov_speed_scale: false  # NEW!
camera_bob_intensity: 0.1  # NEW!
```

**Benefits:**
- ✅ Tune in editor without recompiling
- ✅ Smooth camera option
- ✅ FOV changes with speed (sprint effect)
- ✅ Head bob with configurable intensity
- ✅ Movement tilt

---

### Movement System

**Old:**
```gdscript
const SPEED = 5.0  # Hardcoded
const JUMP_VELOCITY = 4.5  # Hardcoded

# Basic physics in _physics_process
if direction:
    velocity.x = direction.x * SPEED
    velocity.z = direction.z * SPEED
```

**New:**
```gdscript
# MovementStateMachine handles everything!
# States: Walk, Jump, Fall, Sprint, Slide

# Configuration in MovementConfig:
move_speed: 5.0
move_acceleration: 50.0  # NEW! Smooth acceleration
move_friction: 40.0  # NEW! Smooth deceleration
move_air_control: 0.3  # NEW! Air movement

# Curves for dynamic feel:
move_acceleration_curve: Curve  # NEW!
move_friction_curve: Curve  # NEW!

# Sprint system:
sprint_speed_multiplier: 1.8
sprint_fov_increase: 10.0
sprint_uses_stamina: false

# Slide system:
slide_enabled: true
slide_velocity: 10.0
slide_duration: 0.8
```

**Benefits:**
- ✅ Professional movement states
- ✅ Smooth acceleration/deceleration
- ✅ Air control
- ✅ Sprint with FOV change
- ✅ Slide mechanic
- ✅ Coyote time & jump buffering
- ✅ Curves for custom feel

---

### Weapon System

**Old:**
```gdscript
# Firing
if event.button_index == MOUSE_BUTTON_LEFT:
    if event.pressed:
        weapon_controller.fire()

# Auto-fire
if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
    if weapon_controller.current_weapon.is_automatic:
        weapon_controller.fire()
```

**New:**
```gdscript
# Firing (handles charged, burst, everything)
if event.is_action_pressed("primary_action"):
    weapon_controller.handle_fire_pressed()

if event.is_action_released("primary_action"):
    weapon_controller.handle_fire_released()

# Auto-fire handled in WeaponController automatically
```

**Benefits:**
- ✅ Supports charged weapons (hold to charge)
- ✅ Cleaner input handling
- ✅ Auto-fire managed internally
- ✅ Proper press/release tracking

---

### Health System

**Old:**
```gdscript
# Not implemented
```

**New:**
```gdscript
# Full health system:
max_health: 100.0
invulnerable: false

# Methods:
take_damage(amount: float, source: Node3D)
heal(amount: float)
die()

# Signals:
signal health_changed(current, max)
signal died

# UI auto-updates
```

**Benefits:**
- ✅ Ready for combat
- ✅ Damage/heal tracking
- ✅ Death handling
- ✅ UI integration

---

### Interaction System

**Old:**
```gdscript
# Only weapon pickups
var nearby_pickup = null

func set_nearby_pickup(pickup):
    nearby_pickup = pickup
```

**New:**
```gdscript
# Generic interactable system
var nearby_interactables: Array = []

# Any object can be interactable:
add_nearby_interactable(interactable)
remove_nearby_interactable(interactable)

# Signals:
signal entered_interaction_zone(interactable)
signal exited_interaction_zone(interactable)

# Auto-finds closest, shows UI
```

**Benefits:**
- ✅ Works with any object
- ✅ Multiple interactables tracked
- ✅ Automatic closest selection
- ✅ Extensible

---

## Code You Can Remove

If you're migrating, you can **delete** all of this from your old script:

### Remove Movement Code
```gdscript
# DELETE - MovementStateMachine handles this
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _physics_process(delta):
    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed("ui_accept"):
        velocity.y = JUMP_VELOCITY

    var input_dir := Input.get_vector(...)
    # ... all the movement code
```

### Remove Manual Weapon Fire
```gdscript
# DELETE - Weapon controller handles auto-fire
if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
    if weapon_controller.current_weapon.is_automatic:
        weapon_controller.fire()
```

### Remove Weapon Animator Calls
```gdscript
# DELETE - No longer needed
if weapon_animator:
    weapon_animator.update_bob(velocity, delta)
```

---

## New Features You Get For Free

### 1. Movement States

```gdscript
# Get current state
var state = get_movement_state()  # "Walk", "Jump", "Sprint", etc.

# React to state changes
func _on_movement_state_changed(from, to):
    if to == "Slide":
        # Disable firing during slide
        pass
```

### 2. Camera Effects

```gdscript
# Head bob - automatic based on movement
# FOV scaling - automatic based on speed
# Camera tilt - automatic based on strafe direction
# Camera smoothing - configurable in MovementConfig
```

### 3. Interaction System

```gdscript
# Any object with interact() method works:
class_name Door extends Node3D

func interact(player):
    print("Door opened by: %s" % player.name)

# Player automatically detects and shows UI
```

### 4. Health/Damage

```gdscript
# From enemy:
player.take_damage(25.0, self)

# From health pickup:
player.heal(50.0)

# Listen for death:
player.died.connect(_on_player_died)
```

### 5. Debug Commands

```gdscript
# In debug builds, press:
# - Page Up: Take 10 damage
# - Page Down: Heal 10 HP
# - F3: Print debug info (health, state, velocity)
```

---

## Backward Compatibility

If you have existing code that calls the old methods:

**Old weapon pickup:**
```gdscript
# Still works!
player.pickup_weapon(weapon_pickup_node)
```

**Old weapon drop:**
```gdscript
# No longer exists - use:
player.equip_weapon(null)  # Clear weapon
```

**Old movement:**
```gdscript
# No longer in player script - handled by MovementStateMachine
# You can force states:
player.movement_sm.force_state("Jump")
```

---

## Testing Checklist

After migration, test:

- [ ] Movement (WASD)
- [ ] Camera look (Mouse)
- [ ] Jump (Space)
- [ ] Sprint (Shift)
- [ ] Slide (Ctrl while moving fast)
- [ ] Weapon fire (Left Click)
- [ ] Weapon reload (R)
- [ ] Interaction (E)
- [ ] Take damage (Page Up in debug)
- [ ] Heal (Page Down in debug)
- [ ] Movement feels good (adjust curves if not)
- [ ] Camera feels smooth (adjust sensitivity/smoothing)
- [ ] UI updates correctly (ammo, weapon name, health)

---

## Quick Comparison: Lines of Code

| Metric | Old | New |
|--------|-----|-----|
| Player script LOC | 142 | 350 |
| Movement code | In player | Separate state machine |
| Tunable parameters | 2 constants | 50+ in MovementConfig |
| Curves | 0 | 3+ |
| Systems | Hardcoded | Modular |
| Extensibility | Modify script | Add states/plugins |

**More lines, but:**
- ✅ Most is comments and documentation
- ✅ Cleaner separation of concerns
- ✅ Infinitely more flexible
- ✅ Tunable without code changes
- ✅ Multiplayer-ready architecture

---

## Need Help?

1. **Movement not working?** → Check QUICKSTART.md
2. **Want to tune feel?** → See CURVES_GUIDE.md
3. **Need custom states?** → See SYSTEMS_GUIDE.md
4. **Curves confusing?** → Start without them, add later

The new system is more complex but gives you professional-grade control over player feel!
