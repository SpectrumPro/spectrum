# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CueList extends Function
## A list of cues


## Emitted when the active cue is changed
signal active_cue_changed(cue: Cue)

## Emitted when a cues crossfade is finished
signal cue_crossfade_finished(cue: Cue)

## Emitted when the global fade state is changed
signal global_fade_state_changed(use_global_fade: bool)

## Emitted when the global pre_wait state is changed
signal global_pre_wait_state_changed(use_global_pre_wait: bool)

## Emitted when the global fade is changed
signal global_fade_changed(global_fade: float)

## Emitted when the global pre_wait is changed
signal global_pre_wait_changed(global_pre_wait: float)

## Emitted when the allow triggered looping state is changed
signal triggered_looping_changed(allow_triggered_looping: bool)

## Emitted when the loop mode is changed
signal loop_mode_changed(loop_mode: LoopMode)

## Emitted when a cue is added to this CueList
signal cues_added(cues: Array)

## Emitted when a cue is removed from this CueList
signal cues_removed(cues: Array)

## Emitted when a cue's position has changed
signal cue_order_changed(cue: Cue, position: int)


## Loop mode, Reset: Reset all track and go to a default state, Track: Track changes while looping the cue list
enum LoopMode {RESET, TRACK}


## All the cues in the list
var _cues: Array[Cue]

## The current active cue
var _active_cue: Cue

## Global fade state
var _use_global_fade: bool = false

## Global pre wait state
var _use_global_pre_wait: bool = false

## Global fade time
var _global_fade: float = 1

## Global pre wait
var _global_pre_wait: float = 1

## Current loop mode for the cue list
var _loop_mode: LoopMode = LoopMode.RESET

## Allow cues with trigger modes to loop back to the start when reaching the end.
var _allow_triggered_looping: bool = false


## init
func _init(p_uuid: String = UUID_Util.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("CueList")
	_set_self_class("CueList")
	
	_settings_manager.register_setting("allow_triggered_looping", Data.Type.BOOL, set_allow_triggered_looping, get_allow_triggered_looping, [triggered_looping_changed])
	_settings_manager.register_setting("use_global_fade", Data.Type.BOOL, set_global_fade_state, get_global_fade_state, [global_fade_state_changed])
	_settings_manager.register_setting("use_global_pre_wait", Data.Type.BOOL, set_global_pre_wait_state, get_global_pre_wait_state, [global_pre_wait_state_changed])
	_settings_manager.register_setting("loop_mode", Data.Type.ENUM, set_loop_mode, get_loop_mode, [loop_mode_changed]).set_enum_dict(LoopMode)
	
	_settings_manager.register_control("go_previous", Data.Type.ACTION, go_previous)
	_settings_manager.register_control("go_next", Data.Type.ACTION, go_next)
	_settings_manager.register_control("global_fade_speed", Data.Type.FLOAT, set_global_fade_speed, get_global_fade_speed, [global_fade_changed]).set_min_max(0, INF)
	_settings_manager.register_control("global_pre_wait_speed", Data.Type.FLOAT, set_global_pre_wait_speed, get_global_pre_wait_speed, [global_pre_wait_changed]).set_min_max(0, INF)
	
	_settings_manager.register_networked_callbacks({
		"on_active_cue_changed": _on_active_cue_changed,
		"on_global_fade_state_changed": _set_global_fade_state,
		"on_global_pre_wait_state_changed": set_global_pre_wait_state,
		"on_global_fade_changed": _set_global_fade_speed,
		"on_global_pre_wait_changed": _set_global_pre_wait_speed,
		"on_triggered_looping_changed": _set_allow_triggered_looping,
		"on_loop_mode_changed": _set_loop_mode,
		"on_cues_added": _add_cues,
		"on_cues_removed": _remove_cues,
		"on_cue_order_changed": _set_cue_position,
	})
	
	_settings_manager.set_callback_allow_deserialize("on_cues_added")


## Server: Adds a cue to the list
func add_cue(cue: Cue) -> Promise:
	return rpc("add_cue", [cue])


## Server: Removes a cue from the list
func remove_cue(cue: Cue) -> Promise:
	return rpc("remove_cue", [cue])


## Returns an ordored list of cues
func get_cues() -> Array[Cue]:
	return _cues.duplicate()


## Sets whether triggered cues can loop back to the start
func set_allow_triggered_looping(p_allow_triggered_looping: bool) -> Promise:
	return rpc("set_allow_triggered_looping", [p_allow_triggered_looping])


## Sets the loop mode
func set_loop_mode(p_loop_mode: LoopMode) -> Promise:
	return rpc("set_loop_mode", [p_loop_mode])


## Server: Sets the position of a cue in the list
func set_cue_position(cue: Cue, position: int) -> Promise:
	return rpc("set_cue_position", [cue, position])


## Server: Sets the global fade state
func set_global_fade_state(use_global_fade: bool) -> Promise:
	return rpc("set_global_fade_state", [use_global_fade])


## Server: Sets the global pre wait state
func set_global_pre_wait_state(use_global_pre_wait: bool) -> Promise:
	return rpc("set_global_pre_wait_state", [use_global_pre_wait])


## Server: Sets the global fade speed
func set_global_fade_speed(global_fade_speed: float) -> Promise:
	return rpc("set_global_fade_speed", [global_fade_speed])


## Server: Sets the global pre wait speed
func set_global_pre_wait_speed(global_pre_wait_speed: float) -> Promise:
	return rpc("set_global_pre_wait_speed", [global_pre_wait_speed])


## Gets the current loop mode
func get_loop_mode() -> LoopMode:
	return _loop_mode


## Gets the position of a cue
func get_cue_position(p_cue: Cue) -> int:
	return _cues.find(p_cue)


## Gets whether triggered cues can loop back to the start
func get_allow_triggered_looping() -> bool:
	return _allow_triggered_looping


## Gets the global fade state
func get_global_fade_state() -> bool:
	return _use_global_fade


## Gets the global pre wait state
func get_global_pre_wait_state() -> bool:
	return _use_global_pre_wait


## Gets the global fade speed
func get_global_fade_speed() -> float:
	return _global_fade


## Gets the global pre wait speed
func get_global_pre_wait_speed() -> float:
	return _global_pre_wait


## Gets the active cue, or null
func get_active_cue() -> Cue:
	return _active_cue


## Server: Seeks to the next cue in the list
func go_next() -> Promise:
	return rpc("go_next", [])


## Server: Seeks to the previous cue in the list
func go_previous() -> Promise:
	return rpc("go_previous", [])


## Server: Seeks to a cue
func seek_to(cue: Cue) -> Promise:
	return rpc("seek_to", [cue])


## Called when this CueList is to be deleted
func delete() -> void:
	for cue: Cue in _cues.duplicate():
		cue.delete()
	
	super.delete()


## Saves this cue list to a Dictionary
func serialize() -> Dictionary:
	return super.serialize().merged({
		"use_global_fade": _use_global_fade,
		"use_global_pre_wait": _use_global_pre_wait,
		"global_fade": _global_fade,
		"global_pre_wait": _global_pre_wait,
		"allow_triggered_looping": _allow_triggered_looping,
		"loop_mode": _loop_mode,
		"cues": Utils.seralise_component_array(_cues)
	})


## Loads this cue list from a Dictionary
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	_use_global_fade = type_convert(p_serialized_data.get("use_global_fade", _use_global_fade), TYPE_BOOL)
	_use_global_pre_wait = type_convert(p_serialized_data.get("use_global_pre_wait", _use_global_pre_wait), TYPE_BOOL)
	_global_fade = type_convert(p_serialized_data.get("global_fade", _global_fade), TYPE_FLOAT)
	_global_pre_wait = type_convert(p_serialized_data.get("global_pre_wait", _global_pre_wait), TYPE_FLOAT)
	_allow_triggered_looping = type_convert(p_serialized_data.get("allow_triggered_looping", _allow_triggered_looping), TYPE_BOOL)
	_loop_mode = type_convert(p_serialized_data.get("loop_mode", _loop_mode), TYPE_INT)
	
	_add_cues(Utils.deseralise_component_array(type_convert(p_serialized_data.get("cues", []), TYPE_ARRAY)))
	
	var active_cue: EngineComponent = ComponentDB.get_component(type_convert(p_serialized_data.get("active_cue_uuid", ""), TYPE_STRING))
	
	if _cues.has(active_cue):
		_active_cue = active_cue


## Adds a cue to the list
func _add_cue(p_cue: Cue, p_no_signal: bool = false) -> bool:
	if p_cue in _cues:
		return false
	
	_cues.append(p_cue)
	p_cue.delete_requested.connect(_remove_cue.bind(p_cue))
	ComponentDB.register_component(p_cue)
	
	p_cue._set_cue_list(self)
	p_cue._set_position(get_cue_position(p_cue))
	
	if not p_no_signal:
		cues_added.emit([p_cue])
	
	return true


## Adds mutiple cues
func _add_cues(p_cues: Array) -> void:
	var just_added_cues: Array[Cue]

	for cue: Variant in p_cues:
		if cue is Cue and _add_cue(cue, true):
			just_added_cues.append(cue)
	
	if just_added_cues:
		cues_added.emit(just_added_cues)


## Removes a cue from the list
func _remove_cue(p_cue: Cue, p_no_signal: bool = false) -> bool:
	if p_cue not in _cues:
		return false
	 
	_cues.erase(p_cue)
	Network.deregister_network_object(p_cue.settings())

	if not p_no_signal:
		cues_removed.emit([p_cue])

	return true

## Removes mutiple cues
func _remove_cues(p_cues: Array) -> void:
	var just_removed_cues: Array[Cue]

	for cue: Variant in p_cues:
		if cue is Cue and _remove_cue(cue, true):
			just_removed_cues.append(cue)
	
	if just_removed_cues:
		cues_removed.emit(just_removed_cues)


## Internal: Sets the position of a cue in the list
func _set_cue_position(p_cue: Cue, p_position: int) -> void:
	if p_cue not in _cues or p_position > len(_cues):
		return
	
	var old_index: int = _cues.find(p_cue)
	_cues.remove_at(old_index)
	_cues.insert(p_position, p_cue)
	
	for index: int in range(0, _cues.size()):
		_cues[index]._set_position(index)
	
	cue_order_changed.emit(p_cue, p_position)


## Internal: Sets whether triggered cues can loop back to the start
func _set_allow_triggered_looping(p_allow_triggered_looping: bool) -> void:
	if p_allow_triggered_looping == _allow_triggered_looping:
		return

	_allow_triggered_looping = p_allow_triggered_looping
	triggered_looping_changed.emit(_allow_triggered_looping)


## Internal Sets the loop mode
func _set_loop_mode(p_loop_mode: LoopMode) -> void:
	if _loop_mode == p_loop_mode:
		return

	_loop_mode = p_loop_mode
	loop_mode_changed.emit(_loop_mode)


## Internal: Sets the global fade state
func _set_global_fade_state(use_global_fade: bool) -> void:
	if _use_global_fade == use_global_fade:
		return
	
	_use_global_fade = use_global_fade
	global_fade_state_changed.emit(_use_global_fade)


## Internal: Sets the global pre wait state
func _set_global_pre_wait_state(use_global_pre_wait: bool) -> void:
	if _use_global_pre_wait == use_global_pre_wait:
		return
	
	_use_global_pre_wait = use_global_pre_wait
	global_pre_wait_state_changed.emit(_use_global_pre_wait)


## Internal: Sets the global fade speed
func _set_global_fade_speed(global_fade_speed: float) -> void:
	if _global_fade == global_fade_speed:
		return
	
	_global_fade = global_fade_speed
	global_fade_changed.emit(_global_fade)


## Internal: Sets the global pre wait speed
func _set_global_pre_wait_speed(global_pre_wait_speed: float) -> void:
	if _global_pre_wait == global_pre_wait_speed:
		return
	
	_global_pre_wait = global_pre_wait_speed
	global_pre_wait_changed.emit(_global_pre_wait)


## Internal: Called when the active cue is changed on the server
func _on_active_cue_changed(p_cue: Cue) -> void:
	_active_cue = p_cue
	active_cue_changed.emit(_active_cue)
