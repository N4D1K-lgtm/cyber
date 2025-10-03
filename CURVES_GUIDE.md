# Movement Curves Guide - Tune Feel Without Code

Curves let you visually adjust movement behavior in the Godot editor. This creates dynamic, responsive movement that feels professional.

---

## What Are Curves?

**Curves** map an input value (X-axis) to an output multiplier (Y-axis).

```
Input (0.0 to 1.0) → Curve → Output Multiplier (0.0 to 2.0+)
```

**Example:** Acceleration Curve

- **X = 0.0** (stopped) → **Y = 1.5** (150% acceleration when starting from rest)
- **X = 0.5** (half speed) → **Y = 1.0** (100% normal acceleration)
- **X = 1.0** (max speed) → **Y = 0.3** (30% acceleration when near max speed)

**Result:** Snappy starts, smooth top speed transitions.

---

## Movement Curves in MovementConfig

### 1. Acceleration Curve (`move_acceleration_curve`)

**Controls:** How quickly you speed up based on current speed.

**X-Axis:** Current speed / Max speed (0 = stopped, 1 = at max speed)
**Y-Axis:** Acceleration multiplier

**Common Patterns:**

#### Snappy Start, Slow Cap

```
  2.0 |•___
      |    \
  1.0 |     •___
      |         •
  0.0 +----------
      0   0.5   1.0
```

- High acceleration when slow → responsive starts
- Low acceleration near max → prevents overshooting

**Create in Editor:**

1. Inspector → Move Acceleration Curve → `<empty>` → **New Curve**
2. Add point at (0.0, 2.0) - fast start
3. Add point at (0.5, 1.0) - normal mid
4. Add point at (1.0, 0.3) - slow cap

**Feels like:** Titanfall movement, instant response

---

#### Linear (Default)

```
  1.0 |________
      |
  0.5 |
      |
  0.0 +----------
      0   0.5   1.0
```

- Constant acceleration at all speeds
- Set all points to Y = 1.0

**Feels like:** Classic Quake/Source engine

---

#### Momentum-Based (Heavy)

```
  1.0 |     ___•
      |    /
  0.5 |   •
      |  /
  0.0 |•
      +----------
      0   0.5   1.0
```

- Slow to start, faster as you gain speed
- Add point at (0.0, 0.2), (0.5, 0.8), (1.0, 1.5)

**Feels like:** Heavy mech, realistic inertia

---

### 2. Friction Curve (`move_friction_curve`)

**Controls:** How quickly you slow down when not moving.

**X-Axis:** Current speed / Max speed
**Y-Axis:** Friction multiplier

**Common Patterns:**

#### Ice Skating

```
  0.2 |•___________
      |
  0.0 +----------
      0   0.5   1.0
```

- Low friction at all speeds
- Set to Y = 0.2 for sliding feel

**Feels like:** Surfing, bunny hopping

---

#### Sticky Stop

```
  3.0 |           •
      |          /
  1.0 |    ___•
      |   /
  0.5 |•
      +----------
      0   0.5   1.0
```

- Low friction at speed (coast)
- High friction when slow (quick stop)

**Feels like:** Arcade shooter, tight control

---

#### Exponential Stop

```
  2.0 |•
      | \___
  1.0 |     \___
      |         •
  0.0 +----------
      0   0.5   1.0
```

- High friction when fast (realistic drag)
- Low friction when slow (smooth to rest)

**Feels like:** Realistic, smooth deceleration

---

### 3. Movement Feel Curve (`advanced_movement_feel_curve`)

**Controls:** Global responsiveness modifier based on speed.

**X-Axis:** Current speed / Max speed
**Y-Axis:** Overall responsiveness multiplier

E 0:00:00:535   movement_state_machine.gd:126 @ _build_state_table(): Can't call non-static function 'get_state_name' in script.
  <C++ Error>   Condition "!E->value->is_static()" is true. Returning: Variant()
  <C++ Source>  modules/gdscript/gdscript.cpp:946 @ callp()
  <Stack Trace> movement_state_machine.gd:126 @ _build_state_table()
                movement_state_machine.gd:55 @_ready()
**Use Cases:**

- Make high-speed movement feel "floaty"
- Make low-speed movement feel "precise"
- Create speed-dependent turn radius

---

## Creating Curves in Godot

### Step 1: Open MovementConfig Resource

1. Select your `movement_config.tres` in FileSystem
2. Inspector opens

### Step 2: Create Curve

1. Find **Move Acceleration Curve** property
2. Click `<empty>` dropdown
3. Select **New Curve**
4. A curve editor appears below

### Step 3: Edit Curve

**Add Points:**

1. **Right-click** on the curve → **Add Point**
2. Or **Left-click** anywhere on the line

**Move Points:**

1. **Left-click and drag** a point

**Delete Points:**

1. **Right-click** on point → **Remove Point**

E 0:00:00:535   movement_state_machine.gd:126 @ _build_state_table(): Can't call non-static function 'get_state_name' in script.
  <C++ Error>   Condition "!E->value->is_static()" is true. Returning: Variant()
  <C++ Source>  modules/gdscript/gdscript.cpp:946 @ callp()
  <Stack Trace> movement_state_machine.gd:126 @ _build_state_table()
                movement_state_machine.gd:55 @_ready()
**Adjust Handles (Smooth Curves):**

1. **Right-click** on point → **Left Tangent / Right Tangent**
2. Options:
   - **Linear** - Straight line
   - **In** - Ease in
   - **Out** - Ease out
   - **InOut** - Smooth S-curve

### Step 4: Common Settings

**For sharp transitions:**

- Use **Linear** tangents
- Example: Instant accel boost at start

**For smooth transitions:**

- Use **InOut** tangents
- Example: Gradual speed ramp-up

**Curve Limits:**

- **Min Value**: Usually 0.0
- **Max Value**: Usually 2.0 (allows 200% multipliers)

---

## Preset Recipes

### Recipe 1: Counter-Strike Feel

```
Acceleration Curve:
  (0.0, 1.8) - Fast start
  (0.3, 1.0) - Normal
  (1.0, 0.5) - Slow cap

Friction Curve:
  (0.0, 0.8) - Quick initial stop
  (0.5, 1.5) - Sticky mid
  (1.0, 1.2) - Controlled high-speed
```

**Copy Values:**

```
Move Speed: 5.0
Move Acceleration: 60.0
Move Friction: 50.0
```

---

### Recipe 2: Titanfall Movement

```
Acceleration Curve:
  (0.0, 2.5) - Instant response
  (0.7, 1.2) - Maintain momentum
  (1.0, 0.8) - Smooth cap

Friction Curve:
  (0.0, 0.3) - Slide after stop
  (1.0, 0.2) - Preserve speed
```

**Copy Values:**

```
Move Speed: 7.0
Move Acceleration: 80.0
Move Friction: 20.0
Slide Enabled: true
```

---

### Recipe 3: Tactical Realism (ARMA-style)

```
Acceleration Curve:
  (0.0, 0.5) - Slow start (heavy gear)
  (0.5, 0.7) - Gradual build
  (1.0, 1.0) - Full momentum

Friction Curve:
  (0.0, 1.5) - Quick low-speed stop
  (1.0, 2.0) - Strong drag at speed
```

**Copy Values:**

```
Move Speed: 3.5
Move Acceleration: 20.0
Move Friction: 40.0
```

---

### Recipe 4: Quake Bunny Hop

```
Acceleration Curve:
  Flat at Y = 1.0 (no curve)

Friction Curve:
  (0.0, 0.1) - Almost no friction
  (1.0, 0.1) - Preserve all speed

Air Control: 1.0 (full air control)
```

**Copy Values:**

```
Move Speed: 8.0
Move Acceleration: 100.0
Move Friction: 5.0
Move Air Control: 1.0
```

---

## Testing Your Curves

### In-Game Testing

1. Run game (F5)
2. Move around and feel the response
3. Ask yourself:
   - Does it feel too "slippery"? → Increase friction
   - Too "sticky"? → Decrease friction, adjust curve
   - Slow to start? → Boost acceleration curve at low speeds
   - Hard to control at speed? → Reduce acceleration curve at high speeds

### Visual Debugging

Add this to your player script for debug visualization:

```gdscript
func _draw_debug_speed():
 var speed = Vector2(velocity.x, velocity.z).length()
 var speed_ratio = speed / movement_config.move_speed

 # Print current multipliers
 if movement_config.move_acceleration_curve:
  var accel_mult = movement_config.move_acceleration_curve.sample(speed_ratio)
  print("Accel Mult: %.2f" % accel_mult)

 if movement_config.move_friction_curve:
  var friction_mult = movement_config.move_friction_curve.sample(speed_ratio)
  print("Friction Mult: %.2f" % friction_mult)
```

---

## Advanced: Curve-Based Animation

You can also use curves for:

### Camera Shake Intensity

```gdscript
# In camera controller
var shake_curve: Curve  # Intensity over time
var shake_time: float = 0.0

func apply_shake(duration: float):
 shake_time = 0.0
 # Sample curve as time progresses
```

### Weapon Recoil Pattern

```gdscript
# In weapon controller
var recoil_curve: Curve  # Recoil strength over shots

func apply_recoil(shot_number: int):
 var t = float(shot_number) / 30.0  # 30-round mag
 var recoil_mult = recoil_curve.sample(t)
```

### Sprint FOV Transition

```gdscript
# In movement config
var sprint_fov_curve: Curve  # FOV change over sprint time

# In player
var sprint_time: float = 0.0
func update_fov():
 var fov_mult = sprint_fov_curve.sample(sprint_time / 2.0)
 camera.fov = base_fov + (fov_mult * fov_bonus)
```

---

## Troubleshooting

### Curve has no effect

- **Check:** Did you assign the curve in MovementConfig?
- **Check:** Is the curve sampled in the movement state code?
- **Fix:** Make sure curve isn't null in Inspector

### Movement feels broken

- **Check:** Are Y values reasonable? (0.0 - 2.0 range)
- **Check:** Did you accidentally set all points to Y = 0.0?
- **Fix:** Reset curve, start with flat line at Y = 1.0

### Curve editor is tiny

- **Fix:** Click and drag the bottom of Inspector to expand
- **Fix:** Right-click curve → **Edit Curve** for full editor

### Can't add points

- **Fix:** Make sure you're right-clicking ON the curve line
- **Fix:** Try left-clicking the line instead

---

## Export Curves as Resources

For reusable curve presets:

1. FileSystem → Right-click → **New Resource**
2. Search: **Curve**
3. Create and name (e.g., `snappy_acceleration.tres`)
4. Edit curve
5. Save
6. In MovementConfig, **Load** this curve resource

**Benefit:** Share curves between multiple movement configs!

---

## Summary

**Curves provide:**

- ✅ Visual tuning without code changes
- ✅ Non-linear, dynamic behavior
- ✅ Professional "game feel"
- ✅ Easy A/B testing of different feels
- ✅ Shareable presets

**Best Practice:**

1. Start with **no curves** (linear behavior)
2. Playtest and note what feels wrong
3. Add curves to fix specific issues:
   - Too floaty? → Acceleration curve
   - Can't stop? → Friction curve
   - Both? → Both curves!
4. Iterate rapidly in editor
5. Save presets for reuse

**The key:** Curves let designers tune feel without touching code!
