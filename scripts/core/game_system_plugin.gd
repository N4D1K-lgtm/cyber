## GameSystemPlugin.gd
## Base class for plugins that extend GameSystem functionality
##
## USAGE:
## 1. Extend this class to create modular system extensions
## 2. Override virtual methods to hook into system lifecycle
## 3. Access parent system via `system` property
## 4. Use this for: custom movement modes, fire modes, damage modifiers, etc.
##
## EXAMPLE:
##   class_name DoubleJumpPlugin extends GameSystemPlugin
##   func on_jump_pressed():
##       if system.state.get("jumps_remaining", 0) > 0:
##           system.jump()
class_name GameSystemPlugin
extends Resource

## Reference to the parent system this plugin is attached to
var system: Node  # GameSystem - can't use class_name here due to circular dependency

## Override - called when plugin is registered to a system
func _plugin_ready() -> void:
	pass

## Override - called when plugin is unregistered
func _plugin_shutdown() -> void:
	pass

## Override - called every frame if system is processing
func _plugin_process(_delta: float) -> void:
	pass

## Override - called every physics frame if system is processing physics
func _plugin_physics_process(_delta: float) -> void:
	pass
