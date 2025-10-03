# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a 3D first-person shooter game prototype built with Godot 4.5 using GDScript.

**Engine:** Godot 4.5 (Forward Plus renderer)
**Physics:** Jolt Physics engine
**Main Scene:** scenes/main.tscn

## Running and Testing

- **Open project in Godot:** Open the `project.godot` file in Godot Engine 4.5
- **Run the game:** Press F5 in Godot Editor or use the "Play" button
- **Run current scene:** Press F6 to test the currently open scene
- **Debug mode:** F7 opens the project in debug mode

The project has no separate build/test commands - all development happens through the Godot Editor.

## Architectural Patterns and Best Practices

### Design Patterns to Use

**Strategy Pattern** - Use for interchangeable behaviors:
- Weapon firing modes (hitscan vs projectile)
- Movement states (walking, sprinting, sliding)
- AI behaviors
- Input handling schemes

**Observer Pattern (Signals)** - Decouple components:
- Use Godot signals for event-driven communication
- Avoid tight coupling between systems
- Components should emit signals, not call methods directly on other systems

**Component Pattern** - Favor composition over inheritance:
- Split functionality into focused, reusable components
- Attach components to nodes rather than creating deep inheritance hierarchies
- Example: SeparateHealthComponent, DamageComponent, MovementComponent

**State Pattern** - For complex state machines:
- Use explicit State classes/scripts for each state
- Each state handles its own transitions, input, and physics
- Avoid large switch statements or if-else chains

**Factory Pattern** - For object creation:
- Centralized weapon/item spawning
- Pool management for projectiles and effects
- Level/entity instantiation

**Command Pattern** - For actions and input:
- Encapsulate actions as command objects
- Enables input rebinding, replays, undo systems
- Queue and defer actions

### Code Organization Principles

**Single Responsibility** - Each script should have one clear purpose:
- Don't mix rendering, physics, input, and game logic in one script
- Split large controllers into focused components

**Dependency Injection** - Pass dependencies explicitly:
- Avoid using `get_node()` calls scattered throughout code
- Use `@export` variables and `@onready` for dependencies
- Make dependencies clear and testable

**Interface Segregation** - Use duck typing effectively:
- Check for methods with `has_method()` instead of type checking
- Keep interfaces minimal (what the client needs, not what you have)
- Example: `if target.has_method("take_damage"): target.take_damage(amount)`

**Resource-Driven Design** - Use Godot Resources for data:
- Separate data (Resources) from behavior (Scripts)
- Create typed Resource classes for game data (WeaponData, EnemyData, etc.)
- Enable easy iteration and modding

### System Architecture Guidelines

**Event Bus Pattern** - For global communication:
- Create an autoload singleton for game-wide events
- Avoid direct dependencies between distant systems
- Use typed signals for type safety

**Service Locator** - For accessing game systems:
- Use autoload singletons sparingly
- Prefer dependency injection where possible
- Document global dependencies clearly

**Data-Oriented Design** - Optimize for cache and performance:
- Group related data together
- Minimize node tree traversal
- Use typed arrays and avoid dynamic typing in hot paths

### Input System Best Practices

Input actions are defined in `project.godot`:
- Movement: WASD (move_up, move_down, move_left, move_right)
- Interact: E (interact)
- Fire: Left Mouse Button (fire)
- Reload: R (reload)

**Input Handling Strategy:**
- Centralize input reading in one place
- Convert inputs to commands/actions
- Pass actions to systems, not raw input events

### Scene and Node Structure

**Prefer Composition:**
- Build complex behaviors from simple, reusable components
- Avoid deep inheritance hierarchies
- Use node attachment for features (area triggers, collision shapes)

**Scene Organization:**
- `scenes/player/` - Player-related scenes
- `scenes/objects/weapons/` - Weapon system
- `scenes/objects/` - Interactive objects
- `scenes/mechs/` - Character models

**Resource Organization:**
- `materials/` - Materials and shaders
- `scripts/` - Shared scripts and utilities
- Keep data resources (.tres) near the scenes that use them

### Performance Considerations

- Use object pools for frequently spawned objects (projectiles, effects)
- Minimize `get_node()` calls in `_process()` and `_physics_process()`
- Cache references with `@onready`
- Use physics layers and masks efficiently
- Disable processing when objects are off-screen or inactive

### Common Godot Patterns

**Physics Layers:**
- Layer 1: World geometry
- Layer 2: Player
- Layer 8: Pickups/Interactables
- Use collision masks to define what collides with what

**Signal-Based Communication:**
- Parent systems connect to child signals
- Siblings communicate through parent or event bus
- Never have children directly reference siblings

**Resource Loading:**
- Preload assets used at startup: `const SCENE = preload("res://...")`
- Load assets on-demand: `var scene = load("res://...")`
- Use ResourceLoader for async loading

### Testing and Debugging

- Press ESC to release mouse capture for debugging
- Use `print_debug()` for stack traces
- Remote scene tree debugging via editor
- Use Godot's profiler for performance analysis
