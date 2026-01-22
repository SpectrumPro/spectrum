# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Cue extends DataContainer
## Data container for CueLists, a Cue doesn't do anything by itself, and needs to be part of a CueList to work


## Emitted when the QID is changed
signal qid_changed(qid: String)

## Emitted when the fade time it changed
signal fade_time_changed(new_fade_time: float)

## Emitted when the pre_wait time is changed
signal pre_wait_time_changed(pre_wait: float)

## Emitted when the trigger mode it changed
signal trigger_mode_changed(trigger_mode: TriggerMode)

## Emitted when the tracking state is changed
signal tracking_mode_changed(tracking_mode: TrackingMode)


## Enumeration for the trigger modes
enum TriggerMode { MANUAL, AFTER_LAST, WITH_LAST }

## Enum for the tracking modes
enum TrackingMode { TRACKING, RESET }


## the QID of this Cue
var _qid: String = ""

## Fade in time in seconds
var _fade_time: float = 2.0

## Pre-Wait time in seconds, how long to wait before this cue will activate, only works with TRIGGER_MODE.WITH_LAST / AFTER_LAST
var _pre_wait: float = 1

## Trigger mode
var _trigger_mode: TriggerMode = TriggerMode.MANUAL

## Tracking flag, indicates if this cue tracks changes
var _tracking_mode: TrackingMode = TrackingMode.TRACKING


## init
func _init(p_uuid: String = UUID_Util.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("Cue")
	_set_self_class("Cue")
	
	_settings_manager.register_setting("qid", Data.Type.STRING, set_qid, get_qid, [qid_changed])
	_settings_manager.register_setting("trigger_mode", Data.Type.ENUM, set_trigger_mode, get_trigger_mode, [trigger_mode_changed]).set_enum_dict(TriggerMode)
	_settings_manager.register_setting("tracking_mode", Data.Type.ENUM, set_tracking_mode, get_tracking_mode, [tracking_mode_changed]).set_enum_dict(TrackingMode)
	_settings_manager.register_control("fade_time", Data.Type.FLOAT, set_fade_time, get_fade_time, [fade_time_changed]).set_min_max(0, INF)
	_settings_manager.register_control("pre_wait", Data.Type.FLOAT, set_pre_wait, get_pre_wait, [pre_wait_time_changed]).set_min_max(0, INF)
	
	_settings_manager.register_networked_callbacks({
		"on_qid_changed": _set_qid,
		"on_fade_time_changed": _set_fade_time,
		"on_pre_wait_time_changed": _set_pre_wait,
		"on_trigger_mode_changed": _set_trigger_mode,
		"on_tracking_mode_changed": _set_tracking_mode,
	})


## Sets this Cue's QID
func set_qid(p_qid: String) -> Promise:
	return rpc("set_qid", [p_qid])


## Sets the fade time in seconds
func set_fade_time(p_fade_time: float) -> Promise:
	return rpc("set_fade_time", [p_fade_time])


## Sets the pre-wait time in seconds
func set_pre_wait(p_pre_wait: float) -> Promise:
	return rpc("set_pre_wait", [p_pre_wait])


## Sets the trigger mode
func set_trigger_mode(p_trigger_mode: TriggerMode) -> Promise:
	return rpc("set_trigger_mode", [p_trigger_mode])


## Sets the tracking mode state
func set_tracking_mode(p_tracking_mode: TrackingMode) -> Promise:
	return rpc("set_tracking_mode", [p_tracking_mode])


## Returns the QID
func get_qid() -> String:
	return _qid


## Returns the fade time in seconds
func get_fade_time() -> float:
	return _fade_time


## Returns the pre-wait time in seconds
func get_pre_wait() -> float:
	return _pre_wait


## Gets the trigger mode
func get_trigger_mode() -> TriggerMode:
	return _trigger_mode


## Gets the tracking mode
func get_tracking_mode() -> TrackingMode:
	return _tracking_mode


## Internal: Sets this Cue's QID
func _set_qid(p_qid: String) -> void:
	if p_qid == _qid:
		return
	
	_qid = p_qid
	qid_changed.emit(_qid)


## Internal: Sets the fade time in seconds
func _set_fade_time(p_fade_time: float) -> void:
	if p_fade_time == _fade_time:
		return
	
	_fade_time = p_fade_time
	fade_time_changed.emit(_fade_time)


## Internal: Sets the pre-wait time in seconds
func _set_pre_wait(p_pre_wait: float) -> void:
	if p_pre_wait == _pre_wait:
		return
	
	_pre_wait = p_pre_wait
	pre_wait_time_changed.emit(_pre_wait)


## Internal: Sets the trigger mode
func _set_trigger_mode(p_trigger_mode: TriggerMode) -> void:
	if p_trigger_mode == _trigger_mode:
		return
	
	_trigger_mode = p_trigger_mode
	trigger_mode_changed.emit(_trigger_mode)


## Internal: Sets the tracking mode state
func _set_tracking_mode(p_tracking_mode: TrackingMode) -> void:
	if p_tracking_mode == _tracking_mode:
		return
	
	_tracking_mode = p_tracking_mode
	tracking_mode_changed.emit(_tracking_mode)


## Returnes a serialized copy of this cue
func serialize() -> Dictionary:
	return super.serialize().merged({
		"qid": _qid,
		"fade_time": _fade_time,
		"pre_wait": _pre_wait,
		"trigger_mode": _trigger_mode,
		"tracking_mode": _tracking_mode,
	})


## Loads this Cue from a dictionary
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	_qid = type_convert(p_serialized_data.get("qid", _qid), TYPE_STRING)
	_fade_time = type_convert(p_serialized_data.get("fade_time", _fade_time), TYPE_FLOAT)
	_pre_wait = type_convert(p_serialized_data.get("pre_wait", _pre_wait), TYPE_FLOAT)
	_trigger_mode = type_convert(p_serialized_data.get("trigger_mode", _trigger_mode), TYPE_INT)
	_tracking_mode = type_convert(p_serialized_data.get("tracking_mode", _tracking_mode), TYPE_INT)
