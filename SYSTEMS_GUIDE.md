# Game Systems Architecture Guide

## Overview

This is a **plugin-based game systems architecture** where everything is modular, extensible, and self-documenting. Systems are designed to be game-agnostic and composed together to create specific game types (FPS, roguelike, etc.).

## Core Philosophy

1. **Everything is extensible** - Hook points at every layer
2. **Self-documenting** - All resources have tooltips and validation
3. **Data-driven** - Behavior configured via resources, not code
4. **Network-ready** - Client-server separation from the start
5. **Composition over inheritance** - Build complexity from simple pieces

---

## System Layers

### 1. Core Systems (`scripts/core/`)

#### GameSystem
Base class for all major systems. Provides lifecycle hooks and plugin registration.

**Hook Points:**
- `system_initialized` - When system starts
- `system_tick(delta)` - Every frame
- `system_physics_tick(delta)` - Every physics frame
- `system_shutdown` - When system ends

**Creating Custom Systems:**
```gdscript
class_name MyCustomSystem extends GameSystem

func _system_ready():
    print("System initialized")

func _system_physics_process(delta):
    # Your system logic
    pass
```

#### GameSystemPlugin
Extend systems without modifying core code.

**Example - Double Jump Plugin:**
```gdscript
class_name DoubleJumpPlugin extends GameSystemPlugin

var jumps_remaining: int = 2

func _plugin_ready():
    system.state["double_jump_enabled"] = true

func on_jump():
    if jumps_remaining > 0:
        jumps_remaining -= 1
        # Apply jump
```

#### StatModifier & StatContainer
Universal stat modification system - works for ANY numeric value.

**Modifier Types:**
- `ADD` - Flat bonus (e.g., +10 damage)
- `MULTIPLY` - Percentage (e.g., 1.5x damage)
- `OVERRIDE` - Replace value entirely

**Usage:**
```gdscript
var stats = StatContainer.new()
stats.set_base("damage", 50.0)

# Add +15 damage upgrade
stats.add_modifier(StatModifier.create_add("damage", 15.0, "Upgrade_1"))

# Add 50% damage multiplier
stats.add_modifier(StatModifier.create_multiply("damage", 1.5, "PowerUp"))

print(stats.get_value("damage"))  # = (50 + 15) * 1.5 = 97.5
```

---

### 2. Movement System (`scripts/movement/`)

#### MovementConfig
All movement parameters in one resource.

**Editor Setup:**
1. Create new `MovementConfig` resource
2. Tune all parameters in inspector
3. Assign to `PlayerController`

**Key Features:**
- Walk/run speeds with acceleration curves
- Sprint with optional stamina
- Jump with coyote time & buffering
- Slide mechanics
- Crouch
- Network prediction settings

#### MovementStateMachine
State machine for movement with hot-swappable states.

**Built-in States:**
- `WalkState` - Ground movement
- `JumpState` - Jumping with air control
- `FallState` - Falling/airborne
- `SprintState` - Sprinting with stamina
- `SlideState` - Momentum-based sliding

**Creating Custom States:**
```gdscript
class_name WallRunState extends MovementState

func get_state_name() -> String:
    return "WallRun"

func can_enter() -> bool:
    return _is_touching_wall()

func physics_update(delta: float) -> MovementState:
    # Apply wall run physics
    apply_movement(config.move_speed * 1.2, ...)

    # Transition when leaving wall
    if not _is_touching_wall():
        return change_state(state_machine.state_table.get("Fall"))

    return null
```

---

### 3. Weapon System (`scripts/weapons/`)

#### WeaponDataV2
Comprehensive weapon configuration with stat system.

**Editor Setup:**
1. Right-click → New Resource → `WeaponDataV2`
2. Configure basic info (name, model, icon)
3. Create and assign a `FireMode` resource
4. Set base stats (damage, fire_rate, etc.)
5. Optional: Add `StatModifier` to starting_modifiers

**Stat System:**
All weapon properties are modifiable via `StatModifier`:
- `damage`
- `fire_rate`
- `max_range`
- `bullet_spread`
- `recoil`
- `move_speed_multiplier`

#### FireMode (Strategy Pattern)
Defines HOW a weapon fires - completely swappable.

**Built-in Fire Modes:**

##### HitscanFireMode
Instant raycasts (rifles, pistols, snipers)
- Multi-pellet support (shotguns)
- Penetration
- Damage falloff over distance
- Configurable spread

##### ProjectileFireMode
Physical projectiles (rockets, grenades, arrows)
- Projectile scene spawning
- Gravity and physics
- Velocity inheritance
- Multi-projectile shots

##### ChargedFireMode
Hold to charge (lasers, railguns, bows)
- Damage scales with charge time
- Visual/audio feedback
- Auto-fire when fully charged
- Can use hitscan OR projectile on release

##### MeleeFireMode
Melee attacks (swords, hammers)
- Area damage in arc
- Combo system with damage scaling
- Knockback
- Multi-target hits

**Creating Custom Fire Modes:**
```gdscript
class_name BurstFireMode extends FireMode

@export var burst_count: int = 3
@export var burst_delay: float = 0.1

func fire(weapon_controller, weapon_data):
    for i in burst_count:
        _fire_single_shot(weapon_controller, weapon_data)
        await weapon_controller.get_tree().create_timer(burst_delay).timeout
    fire_executed.emit()
```

#### WeaponControllerV2
Handles weapon instance, animations, and input.

**Node Setup:**
```
Camera3D
└─ WeaponControllerV2
   ├─ WeaponPivot (Node3D)
   │  └─ WeaponHolder (Node3D)
   │     └─ MuzzlePoint (Marker3D)
   └─ AudioStreamPlayer3D
```

**Usage from Player:**
```gdscript
# In player script
@onready var weapon_controller = $"Camera/WeaponController"

func _input(event):
    if event.is_action_pressed("fire"):
        weapon_controller.handle_fire_pressed()
    if event.is_action_released("fire"):
        weapon_controller.handle_fire_released()
    if event.is_action_pressed("reload"):
        weapon_controller.handle_reload_pressed()
```

---

## Example Weapon Configurations

### Assault Rifle
```
WeaponDataV2:
  weapon_name: "AR-15"
  weapon_type: "Rifle"
  fire_mode: HitscanFireMode
    pellet_count: 1
  is_automatic: true
  base_damage: 25.0
  base_fire_rate: 0.1
  base_bullet_spread: 0.02
  magazine_size: 30
  max_reserve_ammo: 300
```

### Shotgun
```
WeaponDataV2:
  weapon_name: "Combat Shotgun"
  weapon_type: "Shotgun"
  fire_mode: HitscanFireMode
    pellet_count: 8
  is_automatic: false
  base_damage: 15.0
  base_fire_rate: 0.8
  base_bullet_spread: 0.15
  magazine_size: 8
```

### Rocket Launcher
```
WeaponDataV2:
  weapon_name: "RPG"
  weapon_type: "Explosive"
  fire_mode: ProjectileFireMode
    projectile_scene: "res://projectiles/rocket.tscn"
    projectile_speed: 50.0
    gravity_scale: 0.5
  is_automatic: false
  base_damage: 200.0
  base_fire_rate: 2.0
  magazine_size: 1
```

### Laser Rifle
```
WeaponDataV2:
  weapon_name: "Plasma Rifle"
  weapon_type: "Energy"
  fire_mode: ChargedFireMode
    min_charge_time: 0.5
    max_charge_time: 3.0
    min_charge_damage_multiplier: 0.5
    max_charge_damage_multiplier: 3.0
    uses_hitscan: true
  is_automatic: false
  base_damage: 50.0
  uses_ammo: true
  magazine_size: 50
```

### Sword
```
WeaponDataV2:
  weapon_name: "Katana"
  weapon_type: "Melee"
  fire_mode: MeleeFireMode
    attack_range: 2.5
    attack_arc_angle: 90.0
    enable_combos: true
    combo_damage_multipliers: [1.0, 1.3, 1.6, 2.2]
  is_automatic: false
  base_damage: 50.0
  base_fire_rate: 0.5
  uses_ammo: false
```

---

## Roguelike Integration

### Creating Upgrades

Upgrades are just `StatModifier` resources applied at runtime:

```gdscript
# scripts/roguelike/upgrade_manager.gd
class_name UpgradeManager

func apply_upgrade(weapon: WeaponDataV2, upgrade_id: String):
    match upgrade_id:
        "damage_boost_1":
            weapon.add_modifier(
                StatModifier.create_multiply("damage", 1.25, "UpgradeTier1")
            )
        "fire_rate_boost_1":
            weapon.add_modifier(
                StatModifier.create_multiply("fire_rate", 0.8, "UpgradeTier1")
            )
        "piercing_rounds":
            # Change fire mode to add penetration
            if weapon.fire_mode is HitscanFireMode:
                weapon.fire_mode.penetration_count = 2
```

### Temporary Powerups

```gdscript
# Apply 2x damage for 10 seconds
var powerup = StatModifier.create_multiply("damage", 2.0, "Powerup")
powerup.duration = 10.0
weapon.add_modifier(powerup)

# Update in _process to remove when expired
weapon.update(delta)
```

### Weapon Evolution System

```gdscript
class_name WeaponEvolution

var evolution_level: int = 0
var required_kills: int = 10

func on_kill():
    required_kills -= 1
    if required_kills <= 0:
        evolve()

func evolve():
    evolution_level += 1

    # Each evolution adds modifiers
    weapon.add_modifier(
        StatModifier.create_multiply("damage", 1.15, "Evolution_%d" % evolution_level)
    )

    # At level 3, change fire mode
    if evolution_level == 3:
        var old_mode = weapon.fire_mode
        weapon.fire_mode = ProjectileFireMode.new()
        # Copy properties from old mode...
```

---

## Multiplayer Considerations

### Client-Server Separation

**Client (Input Layer):**
- Reads input
- Sends commands to server via RPC
- Predicts movement/shooting for responsiveness
- Renders visuals

**Server (Authority):**
- Validates all input
- Executes game logic
- Sends state updates to clients
- Prevents cheating

### Network Setup (Future)

```gdscript
# In WeaponControllerV2
func fire() -> bool:
    if is_local_player:
        if enable_prediction:
            _execute_fire()  # Client prediction

        # Send to server
        if is_multiplayer_authority():
            _execute_fire()
        else:
            rpc_id(1, "_rpc_fire")  # Send to server
    return true

@rpc("any_peer", "call_remote", "reliable")
func _rpc_fire():
    if is_multiplayer_authority():
        _execute_fire()
        # Broadcast to all clients
        rpc("_rpc_fire_confirmed")
```

---

## Extending the System

### Adding New Movement Modes

1. Create new `MovementState` script
2. Override `enter()`, `exit()`, `physics_update()`
3. Add to `MovementStateMachine.states` array
4. States auto-register by name

### Adding New Fire Modes

1. Extend `FireMode`
2. Override `fire()` method
3. Create resource and assign to weapon

### Adding New Stats

Stats are completely dynamic:

```gdscript
# Add a new stat
weapon.stats.set_base("explosion_radius", 5.0)

# Modify it
weapon.add_modifier(
    StatModifier.create_add("explosion_radius", 2.0)
)

# Use it
var radius = weapon.get_stat("explosion_radius")  # 7.0
```

---

## Best Practices

1. **Always use resources** for configuration (not hardcoded values)
2. **Use signals** for communication between systems
3. **Add @export hints** with ranges and tooltips
4. **Validate in editor** with `@tool` and `_validate_property()`
5. **Document hook points** with comments
6. **Use StatModifier** for ALL numeric changes
7. **Separate data from logic** (Resources vs Scripts)

---

## Quick Start Checklist

### Setting Up Player Movement
- [ ] Create `MovementConfig` resource
- [ ] Add `MovementStateMachine` to CharacterBody3D
- [ ] Assign config to state machine
- [ ] Add movement states to states array
- [ ] Set initial_state_name to "Walk"

### Setting Up Weapons
- [ ] Create `WeaponDataV2` resource
- [ ] Create appropriate `FireMode` resource
- [ ] Assign fire mode to weapon data
- [ ] Add `WeaponControllerV2` to Camera3D
- [ ] Create node hierarchy (WeaponPivot/WeaponHolder/MuzzlePoint)
- [ ] Assign weapon_data to controller
- [ ] Connect input in player script

### Adding Upgrades
- [ ] Create `UpgradeManager` script
- [ ] Create `StatModifier` resources for each upgrade
- [ ] Apply modifiers at runtime via `weapon.add_modifier()`
- [ ] Update weapon every frame with `weapon.update(delta)`

---

## Troubleshooting

### "FireMode.fire() must be overridden"
You assigned the base `FireMode` class instead of a subclass (HitscanFireMode, etc.)

### Weapon not firing
1. Check weapon_data is assigned
2. Check fire_mode is assigned to weapon_data
3. Check ammo (if uses_ammo is true)
4. Check cooldown timer

### Movement state not transitioning
1. Check state is in states array
2. Check state name matches in state_table
3. Check can_enter() returns true
4. Check transition logic in physics_update()

### Stats not applying
1. Call `weapon.stats.set_base()` to initialize
2. Check modifier stat_name matches exactly
3. Check priority order (higher = applies later)
4. Call `weapon.update(delta)` for temporary modifiers

---

## File Structure

```
scripts/
├── core/
│   ├── game_system.gd
│   ├── game_system_plugin.gd
│   ├── stat_modifier.gd
│   └── stat_container.gd
├── movement/
│   ├── movement_config.gd
│   ├── movement_state.gd
│   ├── movement_state_machine.gd
│   └── states/
│       ├── walk_state.gd
│       ├── jump_state.gd
│       ├── fall_state.gd
│       ├── sprint_state.gd
│       └── slide_state.gd
└── weapons/
    ├── fire_mode.gd
    ├── weapon_data_v2.gd
    ├── weapon_controller_v2.gd
    └── fire_modes/
        ├── hitscan_fire_mode.gd
        ├── projectile_fire_mode.gd
        ├── charged_fire_mode.gd
        └── melee_fire_mode.gd
```
