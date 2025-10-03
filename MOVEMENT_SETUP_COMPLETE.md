# Complete Movement System Setup

This guide fixes all the issues where MovementConfig parameters don't work.

## Problem

MovementConfig has parameters like:
- Sprint FOV increase ❌ Not working
- Camera bob ❌ Not working
- Slide camera lower ❌ Not working
- Jump height ❌ Using hardcoded value
- Acceleration ❌ Feel doesn't change much

**Why?** The movement states read the config, but nothing connects them to the camera/visuals.

---

## Solution: PlayerMovementBridge

A new component that bridges MovementStateMachine → Camera/Visuals.

### What It Does:

✅ Adjusts camera FOV when sprinting
✅ Lowers camera when sliding/crouching
✅ Applies head bob based on movement
✅ Adjusts collision shape for crouch/slide
✅ Smooth transitions between states

---

## Setup Instructions

### Step 1: Add PlayerMovementBridge to Player

1. Open your Player scene
2. Select `Player` (CharacterBody3D root)
3. Add Child Node → `Node`
4. Name it: `PlayerMovementBridge`
5. Attach Script: `scripts/movement/player_movement_bridge.gd`

**Your scene should now look like:**
```
Player (CharacterBody3D)
├─ CollisionShape3D
├─ CameraRig (Node3D)
│  └─ Camera3D
├─ MovementStateMachine (Node)
└─ PlayerMovementBridge (Node)  ← NEW!
```

### Step 2: Configure PlayerMovementBridge

Select `PlayerMovementBridge` in the scene tree.

In Inspector, assign:

1. **Camera**: Drag `Camera3D` node here (or leave empty for auto-detect)
2. **Movement Sm**: Drag `MovementStateMachine` node here
3. **Camera Rig**: Drag `CameraRig` node here (for height offset)
4. **Collision Shape**: Drag `CollisionShape3D` node here (for crouch)

**Auto-detection:** If you leave these empty, the bridge will try to find them automatically.

### Step 3: Verify MovementConfig Properties

Open your MovementConfig resource (the .tres file).

**Make sure these are NOT null:**

```
Camera:
  Camera Mouse Sensitivity: 0.002 (not null!)
  Camera Pitch Limit Down: 85.0
  Camera Pitch Limit Up: 85.0
  Camera Smoothing: 0.0
  Camera Fov Speed Scale: true ← Enable for sprint FOV
  Camera Base Fov: 90.0
  Camera Max Fov Bonus: 10.0
  Camera Bob Intensity: 0.1
  Camera Bob Frequency: 10.0

Sprint:
  Sprint Speed Multiplier: 1.8
  Sprint Fov Increase: 15.0 ← This now works!
  Sprint Transition Time: 0.2

Slide:
  Slide Enabled: true
  Slide Velocity: 10.0

Crouch:
  Crouch Enabled: true
  Crouch Height Scale: 0.5 ← Used for camera lowering
```

**If any say "null":** Click the property and set a value.

### Step 4: Test

Run the game (F5) and test:

**Sprint (Shift):**
- Speed should increase noticeably
- FOV should widen
- Transition should be smooth (0.2s)

**Slide (Ctrl while moving fast):**
- Camera should drop lower
- Speed boost applied
- Collision shape shrinks

**Walk:**
- Head bob should be visible when moving
- Stops when standing still

---

## Troubleshooting

### "Sprint FOV doesn't change"

**Check:**
1. PlayerMovementBridge is added to scene?
2. Camera reference is assigned in bridge?
3. MovementConfig → Camera Fov Speed Scale = **true**?
4. MovementConfig → Sprint Fov Increase > 0?

**Fix:**
```
Open MovementConfig resource
Camera section:
  Camera Fov Speed Scale: ✓ (checked)
  Camera Base Fov: 90.0
  Sprint Fov Increase: 15.0
```

---

### "Camera doesn't lower when sliding"

**Check:**
1. PlayerMovementBridge → Camera Rig is assigned?
2. Slide state is being entered? (Check console for state transitions)

**Debug:**
Add this to player.gd `_ready()`:
```gdscript
if movement_sm:
    movement_sm.state_changed.connect(func(from, to):
        print("State: %s → %s" % [from, to])
    )
```

---

### "Head bob doesn't work"

**Check:**
1. MovementConfig → Camera Bob Intensity > 0?
2. Camera reference in bridge?
3. Moving on ground? (Bob only works when on floor)

**Good values:**
```
Camera Bob Intensity: 0.08
Camera Bob Frequency: 12.0
```

**Too much bob:**
```
Intensity: 0.03
Frequency: 8.0
```

---

### "Jump height doesn't change"

**This is working!** JumpState uses `config.jump_velocity`.

**To change jump height:**
```
Open MovementConfig
Jump section:
  Jump Velocity: 4.5 (default)
  Try: 6.0 for higher jumps
  Try: 3.0 for lower jumps
```

**Why it might not feel different:**
- Jump Fall Gravity Multiplier affects feel
- Try setting to 2.0 for more responsive jumps

---

### "Acceleration still feels the same"

**You need CURVES for dramatic feel changes!**

Numbers alone won't make it feel different:
```
Move Acceleration: 50.0 vs 60.0 ← Barely noticeable
```

But curves make it dynamic:
```
Acceleration Curve:
  (0.0, 2.0) - Fast start
  (1.0, 0.5) - Slow cap
Result: Very noticeable snappy feel!
```

**How to add:**
1. MovementConfig → Move Acceleration Curve → New Curve
2. Add point: Right-click curve → Add Point
3. Drag points to shape behavior
4. See CURVES_GUIDE.md for presets

---

## Parameter Impact Guide

### High Impact (Very Noticeable)

| Parameter | What It Does | Good Range |
|-----------|-------------|------------|
| `move_speed` | Max movement speed | 3.0 - 10.0 |
| `sprint_speed_multiplier` | Sprint speed boost | 1.5 - 3.0 |
| `sprint_fov_increase` | FOV boost when sprinting | 10.0 - 25.0 |
| `jump_velocity` | Jump height | 3.0 - 8.0 |
| `slide_velocity` | Slide speed boost | 8.0 - 15.0 |
| `move_acceleration_curve` | Accel feel (CURVE!) | See CURVES_GUIDE |

### Medium Impact (Noticeable)

| Parameter | What It Does | Good Range |
|-----------|-------------|------------|
| `move_acceleration` | How fast you reach max speed | 30.0 - 100.0 |
| `move_friction` | How fast you stop | 20.0 - 60.0 |
| `move_air_control` | Control while airborne | 0.2 - 1.0 |
| `camera_bob_intensity` | Head bob amount | 0.05 - 0.15 |
| `jump_fall_gravity_multiplier` | Falling speed | 1.2 - 2.5 |

### Low Impact (Subtle)

| Parameter | What It Does | Good Range |
|-----------|-------------|------------|
| `sprint_transition_time` | Sprint ramp-up time | 0.1 - 0.5 |
| `camera_smoothing` | Camera lag | 0.0 - 0.3 |
| `jump_coyote_time` | Jump grace period | 0.05 - 0.2 |
| `jump_buffer_time` | Jump input buffer | 0.1 - 0.2 |

---

## Quick Test Values

### Fast & Responsive (Arena Shooter)
```
move_speed: 8.0
move_acceleration: 80.0
move_friction: 50.0
sprint_speed_multiplier: 1.4
sprint_fov_increase: 15.0
jump_velocity: 6.0
jump_fall_gravity_multiplier: 1.8
camera_bob_intensity: 0.05
```

### Tactical & Heavy (Realistic)
```
move_speed: 4.5
move_acceleration: 30.0
move_friction: 40.0
sprint_speed_multiplier: 1.6
sprint_fov_increase: 8.0
jump_velocity: 3.5
jump_fall_gravity_multiplier: 1.2
camera_bob_intensity: 0.12
```

### Extreme Speed (Titanfall-style)
```
move_speed: 12.0
move_acceleration: 100.0
move_friction: 15.0
sprint_speed_multiplier: 2.5
sprint_fov_increase: 25.0
jump_velocity: 7.0
slide_velocity: 15.0
camera_bob_intensity: 0.08
camera_fov_speed_scale: true
```

---

## Visual Verification

Add this debug script to Player to see what's happening:

```gdscript
# In player.gd _physics_process(delta)
func _physics_process(delta):
    # Show current values on screen
    if OS.is_debug_build():
        var state = movement_sm.get_current_state_name()
        var speed = Vector2(velocity.x, velocity.z).length()
        var fov = $"CameraRig/Camera3D".fov

        # Print every second
        if Engine.get_physics_frames() % 60 == 0:
            print("State: %s | Speed: %.1f | FOV: %.1f" % [state, speed, fov])
```

**What to look for:**
- FOV should change from 90 → 105+ when sprinting
- Speed should increase significantly in Sprint state
- Camera height changes are visible on screen

---

## Complete Working Example

**Scene Structure:**
```
Player (CharacterBody3D) ← player.gd or player_controller_v2.gd
├─ CollisionShape3D (CapsuleShape3D)
├─ CameraRig (Node3D)
│  └─ Camera3D (fov: 90)
├─ MovementStateMachine
│  movement_config: movement_config.tres
│  states: [walk, jump, fall, sprint, slide]
│  initial_state_name: "Walk"
└─ PlayerMovementBridge ← NEW!
   camera: → Camera3D
   movement_sm: → MovementStateMachine
   camera_rig: → CameraRig
   collision_shape: → CollisionShape3D
```

**MovementConfig (movement_config.tres):**
```
Move Speed: 6.0
Sprint Speed Multiplier: 2.0
Sprint Fov Increase: 15.0
Camera Fov Speed Scale: ✓
Camera Base Fov: 90.0
Camera Bob Intensity: 0.08
Camera Bob Frequency: 10.0
```

**Result:**
✅ Sprint increases speed 2x
✅ FOV widens from 90° → 105°
✅ Head bob visible when walking
✅ Slide lowers camera
✅ All parameters work!

---

## Final Checklist

Before asking "why doesn't X work":

- [ ] PlayerMovementBridge added to scene?
- [ ] Bridge has camera reference assigned?
- [ ] Bridge has movement_sm reference assigned?
- [ ] MovementConfig has NO null values in Camera section?
- [ ] Camera Fov Speed Scale is enabled (✓)?
- [ ] Sprint Fov Increase > 0?
- [ ] Tested in-game (not just in editor)?
- [ ] Checked console for state change logs?

If all checked and still not working, check:
- [ ] Using old player.gd script? (Needs update)
- [ ] Camera node path correct? (CameraRig/Camera3D)
- [ ] MovementStateMachine has config assigned?
- [ ] States array has all 5 states loaded?

---

## Next Level: Add Curves

Once basic parameters work, add curves for pro-level feel:

1. Open MovementConfig
2. Move Acceleration Curve → New Curve
3. Add points to create shape (see CURVES_GUIDE.md)
4. Test immediately - changes are instant!

**Curves make the BIGGEST difference in feel!**

Linear acceleration (no curve):
```
Meh, feels okay...
```

Curve with snappy start:
```
WOW! This feels amazing!
```

See CURVES_GUIDE.md for preset recipes.
