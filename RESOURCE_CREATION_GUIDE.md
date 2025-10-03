# Resource Creation Guide - Visual Walkthrough

This guide clarifies the difference between creating `.tres` resource files vs. loading script files.

---

## Understanding Resources vs Scripts

### ❌ WRONG: Creating .tres for States

**DO NOT** do this for movement states:
```
Right-click → New Resource → MovementState → Save as "walk_state.tres"
```

**Why?** States are **scripts with logic**, not data containers. Creating a .tres gives you an empty data object with no behavior.

### ✅ CORRECT: Loading Script Files

**DO** this instead:
```
In Inspector → States array → Slot [0] → New GDScript → Load → walk_state.gd
```

**Why?** You're loading the actual script that contains the movement logic.

---

## Visual Decision Tree

```
┌─────────────────────────────────────────────┐
│  Do I need to configure VALUES/SETTINGS?    │
│  (damage, speed, fire rate, etc.)           │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
       YES                   NO
        │                     │
        ▼                     ▼
┌───────────────┐    ┌────────────────┐
│ CREATE .TRES  │    │  LOAD SCRIPT   │
│   RESOURCE    │    │    FILE        │
└───────────────┘    └────────────────┘
        │                     │
        ▼                     ▼
  Examples:              Examples:
  - MovementConfig       - MovementState scripts
  - WeaponDataV2         - FireMode scripts
  - StatModifier         - GameSystemPlugin scripts
```

---

## Concrete Examples

### Example 1: Movement Configuration

**What you're doing:** Setting speed, jump height, sprint multiplier, etc.

**Type:** `.tres` resource file

**Steps:**
```
1. FileSystem → Right-click → New Resource
2. Search: "MovementConfig"
3. Create
4. Name: "my_movement.tres"
5. Configure in Inspector
6. Save
```

**Result:** A `.tres` file containing all your settings.

---

### Example 2: Movement States

**What you're doing:** Adding walking, jumping, sprinting behavior to state machine.

**Type:** Loading script files (`.gd`)

**Steps:**
```
1. Select MovementStateMachine node
2. Inspector → States → Size = 5
3. For Slot [0]:
   - Click dropdown
   - Select "Quick Load" or "Load"
   - Navigate to: scripts/movement/states/walk_state.gd
   - Open
4. Repeat for all 5 states
```

**Result:** The state machine has script references. It will automatically create instances when it starts.

**Important:** You're loading the raw `.gd` script files, NOT creating resource instances. The MovementStateMachine automatically instantiates them at runtime.

---

### Example 3: Weapon Data

**What you're doing:** Configuring damage, fire rate, ammo, etc.

**Type:** `.tres` resource file

**Steps:**
```
1. FileSystem → Right-click → New Resource
2. Search: "WeaponDataV2"
3. Create
4. Name: "pistol.tres"
5. Configure stats in Inspector
6. Save
```

**Result:** A `.tres` file with your weapon's stats.

---

### Example 4: Fire Mode

**What you're doing:** Choosing HOW the weapon fires (hitscan, projectile, melee).

**Type:** `.tres` resource file (but nested inside weapon data)

**Steps:**
```
1. Open your weapon data resource (pistol.tres)
2. Inspector → Fire Mode → Click <empty>
3. Choose "New HitscanFireMode" (or Projectile, Charged, Melee)
4. Configure fire mode settings
5. Save weapon data
```

**Result:** The fire mode settings are embedded in the weapon `.tres` file.

**OR** (for reusable fire modes):
```
1. FileSystem → Right-click → New Resource
2. Search: "HitscanFireMode"
3. Create
4. Name: "sniper_hitscan.tres"
5. Configure (e.g., penetration, damage falloff)
6. Save
7. In weapon data, Load this .tres file for Fire Mode
```

---

### Example 5: Stat Modifier (Upgrade)

**What you're doing:** Creating a +50% damage boost upgrade.

**Type:** `.tres` resource file

**Steps:**
```
1. FileSystem → Right-click → New Resource
2. Search: "StatModifier"
3. Create
4. Name: "damage_boost_50.tres"
5. In Inspector:
   - Stat Name: "damage"
   - Modifier Type: MULTIPLY
   - Value: 1.5
6. Save
```

**Result:** A reusable upgrade that can be applied to any weapon.

---

## Quick Reference Table

| What You Need | File Type | How to Create |
|---------------|-----------|---------------|
| **Movement Config** | `.tres` | Right-click → New Resource → MovementConfig |
| **Movement States** | Load `.gd` scripts | Inspector array → Load script files |
| **Weapon Data** | `.tres` | Right-click → New Resource → WeaponDataV2 |
| **Fire Mode** | `.tres` (nested or separate) | In weapon Inspector OR New Resource |
| **Stat Modifier** | `.tres` | Right-click → New Resource → StatModifier |
| **Custom State** | `.gd` script | Create new script extending MovementState |
| **Custom Fire Mode** | `.gd` script | Create new script extending FireMode |
| **Custom Plugin** | `.gd` script | Create new script extending GameSystemPlugin |

---

## Inspector Tips

### Loading a Script in an Array

When you see this in Inspector:
```
States (Array):
  Size: 0
  ▼ [0]: <empty>
```

**To add a script:**
1. Click `<empty>` dropdown
2. You'll see options:
   - Quick Load ← **Use this!**
   - Load
   - New Script (ignore this)
3. Select **"Quick Load"** or **"Load"**
4. Navigate to the `.gd` file
5. Click **Open**

**Result:** The slot shows a script icon and filename (e.g., `walk_state.gd`)

**Note:** You're loading the script class itself. The system will create an instance automatically when needed.

### Loading a Resource in a Property

When you see this in Inspector:
```
Movement Config: <empty>
```

**To add a resource:**
1. Click `<empty>` dropdown
2. Select **Load**
3. Navigate to your `.tres` file
4. Click **Open**

**OR** create inline:
1. Click `<empty>` dropdown
2. Select **New MovementConfig** (or whatever type)
3. Configure right there in Inspector
4. Changes are saved with the scene

---

## Common Mistakes

### ❌ Mistake 1: Creating .tres for States

```
ERROR: Right-clicking in FileSystem → New Resource → WalkState
```

**Why it's wrong:** You get an empty data container, not the walking logic.

**Fix:** Load the script file `walk_state.gd` in the MovementStateMachine's States array.

---

### ❌ Mistake 2: Trying to Attach Scripts to Resources

```
ERROR: Opening pistol.tres → Attach Script
```

**Why it's wrong:** Resources are data files, not scene nodes. You can't attach scripts to them.

**Fix:** Configure the resource's properties in Inspector instead.

---

### ❌ Mistake 3: Not Saving Resources After Changes

```
ERROR: Changing damage from 25 to 50, closing Inspector, changes lost
```

**Why it's wrong:** Resource changes don't auto-save.

**Fix:** Press Ctrl+S after modifying any `.tres` resource.

---

### ❌ Mistake 4: Creating New Fire Mode Script

```
ERROR: In WeaponData → Fire Mode → "New Script"
```

**Why it's wrong:** Fire mode scripts already exist. You just need to create a resource using them.

**Fix:** Use "New HitscanFireMode" to create a resource instance, not a new script.

---

## When to Create Your Own Scripts

**Create a new `.gd` script when:**

✅ Adding completely new behavior:
- New movement state (WallRunState, GrappleState)
- New fire mode (BeamFireMode, ShotgunFireMode)
- New plugin (DoubleJumpPlugin, AutoAimPlugin)

**Steps:**
1. Right-click in FileSystem → New Script
2. Extend appropriate base class:
   - `extends MovementState`
   - `extends FireMode`
   - `extends GameSystemPlugin`
3. Implement required methods
4. Save in appropriate folder
5. Load it in Inspector just like built-in scripts

**Don't create new script when:**
- ❌ You just want different stats (use .tres resources)
- ❌ Tweaking existing behavior (modify existing script)
- ❌ Adding upgrades (use StatModifier resources)

---

## Summary

**Rule of Thumb:**

```
If it's DATA → Create .tres resource file
If it's CODE → Load .gd script file
If it's NEW CODE → Write new .gd script, then load it
```

**In Practice:**

- **I want a faster weapon** → Modify `.tres` weapon data (change fire_rate value)
- **I want a shotgun** → Create new `.tres` weapon data with HitscanFireMode (pellet_count = 8)
- **I want wall running** → Write new `WallRunState.gd`, load it in MovementStateMachine
- **I want a laser beam** → Write new `BeamFireMode.gd`, create `.tres` using it, assign to weapon
- **I want +50% damage upgrade** → Create `.tres` StatModifier, apply at runtime

---

## Still Confused?

Ask yourself:

**"Am I changing numbers/settings, or am I changing how something works?"**

- **Numbers/settings** → `.tres` resource
- **How it works** → Load or create `.gd` script

**"Does this thing already exist in the scripts folder?"**

- **Yes** → Load the existing `.gd` script
- **No** → Create new `.gd` script extending the base class

**"Can I do this without writing code?"**

- **Yes** → You need a `.tres` resource
- **No** → You need a `.gd` script
