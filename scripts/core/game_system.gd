## GameSystem.gd
## Base class for all game systems. Provides lifecycle hooks and plugin registration.
##
## NOTE: GameSystemPlugin must be defined before using this class
##
## USAGE:
## 1. Extend this class for any major system (MovementSystem, CombatSystem, etc.)
## 2. Override lifecycle methods: _system_ready(), _system_process(), _system_physics_process()
## 3. Register plugins via register_plugin() to extend system behavior
## 4. Emit hook signals to allow external code to react to events
##
## EXAMPLE:
##   class_name MyCustomSystem extends GameSystem
##   func _system_ready(): plugins.map(func(p): p.on_system_start())
class_name GameSystem
extends Node

## Emitted when the system is fully initialized
signal system_initialized
## Emitted when the system is about to shut down
signal system_shutdown
## Emitted every frame if enabled
signal system_tick(delta: float)
## Emitted every physics frame if enabled
signal system_physics_tick(delta: float)

## If true, system will process every frame
@export var process_enabled: bool = true
## If true, system will process every physics frame
@export var physics_process_enabled: bool = true
## Priority for execution order (higher = earlier)
@export var execution_priority: int = 0

## Registered plugins that extend this system's functionality
var plugins: Array = []  # Array[GameSystemPlugin]
## System state data - use this for shared state across plugins
var state: Dictionary = {}


func _ready() -> void:
	set_process(process_enabled)
	set_physics_process(physics_process_enabled)
	_system_ready()
	system_initialized.emit()


func _process(delta: float) -> void:
	_system_process(delta)
	system_tick.emit(delta)


func _physics_process(delta: float) -> void:
	_system_physics_process(delta)
	system_physics_tick.emit(delta)


## Override this in derived classes - called once on _ready()
func _system_ready() -> void:
	pass


## Override this in derived classes - called every frame
func _system_process(_delta: float) -> void:
	pass


## Override this in derived classes - called every physics frame
func _system_physics_process(_delta: float) -> void:
	pass


## Register a plugin to extend this system's functionality
## Plugins receive lifecycle callbacks and can modify system behavior
func register_plugin(plugin: GameSystemPlugin) -> void:
	if plugin in plugins:
		push_warning("Plugin %s already registered to %s" % [plugin, name])
		return

	plugins.append(plugin)
	plugin.system = self
	plugin._plugin_ready()
	print("[GameSystem] Registered plugin: %s to system: %s" % [plugin.get_class(), name])


## Unregister a plugin from this system
func unregister_plugin(plugin: GameSystemPlugin) -> void:
	var idx = plugins.find(plugin)
	if idx != -1:
		plugins.remove_at(idx)
		plugin._plugin_shutdown()


## Call a method on all registered plugins
## Example: call_on_plugins("on_damage_dealt", [target, amount])
func call_on_plugins(method: String, args: Array = []) -> void:
	for plugin in plugins:
		if plugin.has_method(method):
			plugin.callv(method, args)


## Get all plugins of a specific class type
func get_plugins_of_type(type: Script) -> Array:
	var result: Array = []  # Array[GameSystemPlugin]
	for plugin in plugins:
		if plugin.get_script() == type:
			result.append(plugin)
	return result


func _exit_tree() -> void:
	system_shutdown.emit()
	for plugin in plugins:
		plugin._plugin_shutdown()
