# Movement System Fix Checklist

## ✅ What I Fixed

### 1. PlayerMovementBridge Created
- **File:** `scripts/movement/player_movement_bridge.gd`
- **Purpose:** Connects MovementStateMachine to Camera/Visuals
- **Features:**
  - ✅ Sprint FOV increase
  - ✅ Camera lowering for slide/crouch
  - ✅ Head bob based on movement
  - ✅ Collision shape adjustment
  - ✅ Smooth transitions

### 2. MovementConfig Null Values Fixed
- **File:** `scripts/movement/movement_config.gd`
- **Added:** `_init()` function to set defaults for null camera properties
- **Now:** All camera properties have default values even on old configs

### 3. Sprint State Enhanced
- **File:** `scripts/movement/states/sprint_state.gd`
- **Added:** Smooth speed transition
- **Added:** Sprint transition time support
- **Added:** Better config null checks

### 4. Movement State Curves Support
- **File:** `scripts/movement/movement_state.gd`
- **Enhanced:** `apply_movement()` now uses acceleration/friction curves
- **Result:** Dynamic, non-linear movement feel

---

## 🎮 How to Test

### Test 1: Sprint FOV
```
1. Run game (F5)
2. Hold Shift to sprint
3. Watch FOV widen (should go from 90° → 105°+)
4. Release Shift
5. FOV should return to normal
```

**Expected:** Smooth FOV transition, speed increase obvious

**If not working:**
- Check: PlayerMovementBridge added to scene? ✓
- Check: Camera reference assigned in bridge? ✓
- Check: MovementConfig → Camera Fov Speed Scale = true? ✓

### Test 2: Slide Camera Lower
```
1. Run game
2. Sprint forward (Shift)
3. Press Ctrl to slide
4. Camera should drop noticeably
5. Stand up - camera returns
```

**Expected:** Visible camera height change

**If not working:**
- Check: Camera Rig assigned in bridge? ✓
- Check: Sliding actually happening? (Check console for state change)

### Test 3: Head Bob
```
1. Run game
2. Walk around (WASD)
3. Camera should bob slightly
4. Stop moving - bob stops
```

**Expected:** Subtle up/down bob when moving

**If not working:**
- Check: Camera Bob Intensity > 0? ✓
- Check: On ground? (Bob only works when grounded)

### Test 4: Jump Height
```
1. Run game
2. Jump (Space)
3. Note height
4. Change MovementConfig → Jump Velocity
5. Jump again - should be different
```

**Expected:** Clear height difference

**Values to try:**
- 3.0 = Low jump
- 4.5 = Normal (default)
- 7.0 = High jump

### Test 5: Acceleration Feel
```
1. Run game
2. Note how movement feels
3. Add acceleration curve in MovementConfig
4. Add points: (0.0, 2.0), (1.0, 0.5)
5. Run again - should feel snappier
```

**Expected:** Dramatic change in feel

**If not working:**
- Curves make bigger impact than raw numbers!
- Try extreme values to confirm it's working

---

## 📋 Verification Steps

### Step 1: Check Scene Structure

Your Player scene should have:
```
Player (CharacterBody3D)
├─ MovementStateMachine ✓
├─ PlayerMovementBridge ✓ ← Must be here!
├─ CollisionShape3D ✓
└─ Camera Rig/Camera3D ✓
```

**Verify in Scene Tree:**
- [ ] PlayerMovementBridge exists?
- [ ] Has script attached? (player_movement_bridge.gd)

### Step 2: Check Bridge Configuration

Select PlayerMovementBridge in scene tree.

Inspector should show:
- [ ] Camera: → Camera Rig/MainCamera (assigned)
- [ ] Movement Sm: → MovementStateMachine (assigned)
- [ ] Camera Rig: → Camera Rig (assigned)
- [ ] Collision Shape: → CollisionShape3D (assigned)

**I can see from your .tscn all of these ARE assigned! ✓**

### Step 3: Check MovementConfig

Open the MovementConfig resource (Resource_rn7t0 in your scene).

Camera section should show VALUES (not null):
- [ ] Camera Mouse Sensitivity: 0.002
- [ ] Camera Pitch Limit Down: 85.0
- [ ] Camera Pitch Limit Up: 85.0
- [ ] Camera Smoothing: 0.0
- [ ] Camera Fov Speed Scale: true ← **IMPORTANT!**
- [ ] Camera Base Fov: 90.0
- [ ] Camera Max Fov Bonus: 10.0
- [ ] Camera Bob Intensity: 0.08
- [ ] Camera Bob Frequency: 10.0

**To enable sprint FOV:**
Set `Camera Fov Speed Scale` to **true** (checked)

### Step 4: Enable Debug Output

Add to player.gd `_ready()`:
```gdscript
func _ready():
    # Existing code...

    # Debug movement states
    $MovementStateMachine.state_changed.connect(func(from, to):
        print("[Movement] %s → %s" % [from, to])
    )
```

Add to player.gd `_physics_process()`:
```gdscript
func _physics_process(delta):
    # Existing code...

    # Debug FOV every second
    if Engine.get_physics_frames() % 60 == 0:
        var camera = $"Camera Rig/MainCamera"
        var speed = Vector2(velocity.x, velocity.z).length()
        print("Speed: %.1f | FOV: %.1f" % [speed, camera.fov])
```

**Run game and watch console:**
- Should see state transitions
- Should see FOV changing when sprinting

---

## 🔧 Tuning Guide

### For Snappy, Responsive Feel:

```
MovementConfig:
  move_speed: 8.0
  move_acceleration: 80.0
  move_friction: 50.0
  sprint_speed_multiplier: 2.0
  sprint_fov_increase: 20.0
  camera_fov_speed_scale: true

Curves:
  Acceleration Curve: (0.0, 2.0), (1.0, 0.5)
  Friction Curve: (0.0, 1.5), (1.0, 1.0)
```

### For Smooth, Realistic Feel:

```
MovementConfig:
  move_speed: 5.0
  move_acceleration: 40.0
  move_friction: 35.0
  sprint_speed_multiplier: 1.6
  sprint_fov_increase: 12.0
  camera_bob_intensity: 0.12

Curves:
  Acceleration Curve: (0.0, 0.5), (1.0, 1.2)
  Friction Curve: (0.0, 1.0), (1.0, 1.8)
```

### For Extreme Speed (Testing):

```
MovementConfig:
  move_speed: 15.0
  move_acceleration: 100.0
  sprint_speed_multiplier: 3.0
  sprint_fov_increase: 30.0
  slide_velocity: 20.0
  camera_fov_speed_scale: true
```

**This should be VERY obvious if working!**

---

## 🐛 Still Not Working?

### Sprint FOV Not Changing

**Most Common Issue:** `camera_fov_speed_scale` is false

**Fix:**
1. Open MovementConfig resource
2. Find Camera section
3. `Camera Fov Speed Scale` → Click checkbox to **enable**
4. Save resource
5. Test again

**Alternative:** Set `sprint_fov_increase` to a huge value (30.0) to make it obvious

---

### Parameters Don't Affect Anything

**Issue:** Using raw numbers without curves

**Why:** Small number changes (50.0 → 60.0 acceleration) are barely noticeable

**Fix:** Add curves!
1. MovementConfig → Move Acceleration Curve → New Curve
2. Add point at (0.0, 2.0) - high start accel
3. Add point at (1.0, 0.5) - low end accel
4. Test - should feel VERY different

---

### Camera Doesn't Lower in Slide

**Issue:** Slide state not being entered

**Debug:**
1. Add state change logging (see Step 4 above)
2. Try to slide
3. Check console - does it say "Walk → Slide"?

**If NO:**
- Check: Moving fast enough? (Need speed > `slide_min_speed`)
- Check: Slide enabled in config? (`slide_enabled = true`)
- Check: Actually pressing Ctrl?

**If YES but camera doesn't lower:**
- Check: Camera Rig assigned in bridge?
- Check: Bridge script is player_movement_bridge.gd?

---

### Head Bob Not Visible

**Too Subtle:**
Try extreme value: `camera_bob_intensity: 0.3`

**Still nothing:**
- Check: Moving on ground?
- Check: Camera reference in bridge?
- Check: Frequency > 0?

---

## 📊 Expected Values in Console

When debug output enabled, you should see:

```
[Movement] Walk → Sprint
Speed: 5.2 | FOV: 90.0
Speed: 7.8 | FOV: 92.3
Speed: 10.4 | FOV: 95.6
Speed: 14.2 | FOV: 102.1  ← Sprint FOV increase working!
Speed: 18.6 | FOV: 105.0  ← Max FOV reached
[Movement] Sprint → Walk
Speed: 15.2 | FOV: 103.2  ← Returning to normal
Speed: 10.1 | FOV: 96.4
Speed: 5.3 | FOV: 91.2
Speed: 0.0 | FOV: 90.0    ← Back to base
```

**If your console doesn't show FOV changing:** Camera effects not working

---

## ✅ Success Criteria

You'll know everything works when:

- [ ] Sprint visibly increases speed
- [ ] FOV widens when sprinting (90° → 105°+)
- [ ] Camera bobs when walking
- [ ] Camera lowers when sliding
- [ ] Jump height changes when you adjust config
- [ ] Acceleration feels different with curves
- [ ] Console shows state transitions
- [ ] Console shows FOV changing

**All of these should work after following this guide!**

---

## 📖 Reference Documents

- **MOVEMENT_SETUP_COMPLETE.md** - Full setup instructions
- **CURVES_GUIDE.md** - How to use curves for feel
- **QUICKSTART.md** - Basic player setup
- **SYSTEMS_GUIDE.md** - Architecture overview

---

## 🚀 Next Steps

Once basic parameters work:

1. **Add curves** for pro-level feel
2. **Tune values** to your liking
3. **Save presets** as separate MovementConfig resources
4. **Add custom states** (wall-run, dash, etc.)
5. **Create weapon integrations** (slower when carrying heavy weapon)

The system is now fully dynamic and tunable!
