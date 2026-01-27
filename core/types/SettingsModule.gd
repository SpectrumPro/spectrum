# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsModule extends Object
## Represents a configurable module within the settings system.


## Enum for Type
enum Type {
	NONE		= 0, ## No type assigned
	SETTING		= 1, ## Represents a configurable setting
	CONTROL		= 2, ## Represents a controllable action or command
	STATUS		= 3, ## Represents a status or state indicator
}


## Enum for ActionMode
enum ActionMode {
	NONE		= 0, ## No action assigned
	SINGLE		= 1, ## One-shot action
	TOGGLE		= 2, ## Toggable action
	HOLD		= 3, ## Press and Release action
}


## ID of this SettingsModule
var _id: String = ""

## Human name of this SettingsModule
var _name: String = ""

## DataType of this SettingsModule
var _data_type: Data.Type = Data.Type.NULL

## Module Type
var _type: Type = Type.NONE

## Setter for the connected parameter
var _setter: Callable = Callable()

## Getter for the connected parameter
var _getter: Callable = Callable()

## Signal for the connected parameter
var _signals: Array[Signal] = []

## A filter for when using any data type of object
var _class_filter: Script = null

## The Enum dictionary when using DataType.ENUM
var _enum_dict: Dictionary

## The IP type when using DataType.IP
var _ip_type: IP.Type = IP.Type.TYPE_ANY

## A Callable that must return true for this SettingsModule to be editable
var _edit_condition: Callable = func () -> bool: return true

## A Callable that must return true for this SettingsMoudle to be displayed in the GUI
var _display_condition: Callable = func () -> bool: return true

## The min and max values
var _min_max: Array[Variant] = [0.0, 1.0]

## The PackedScene for DataType.CUSTOMPANEL
var _custom_panel_scene: PackedScene

## The String callable name for the custom panel scene's setter function
var _custom_panel_entry_point: String

## The sub manager SettingsManager, for Data.Type.SETTINGSMANAGER
var _sub_manager: SettingsManager

## ActionMode when usign Data.Type.ACTION
var _action_mode: ActionMode = ActionMode.NONE

## The callable for ActionMode.HOLD when the action is released
var _hold_release_callable: Callable = Callable()

## The name for the category this module should be displayed under when in a user interface
var _visual_category: String = ""

## The line this Module shoule be displayed when in a user interface
var _visual_line: int = -1

## The object that owns this SettingsManager
var _owner: WeakRef


## Init
func _init(p_id: String, p_name: String, p_data_type: Data.Type, p_type: Type, p_setter: Callable, p_getter: Callable, p_signals: Array[Signal], p_owner: Object) -> void:
	_id = p_id
	_name = p_name
	_data_type = p_data_type
	_type = p_type
	_setter = p_setter
	_getter = p_getter
	_signals = p_signals
	_owner = weakref(p_owner)


## Gets the value of this SettingsModule as a String
func get_value_string() -> String:
	match _data_type:
		Data.Type.ENUM:
			return _enum_dict.keys()[_getter.call()]
		
		Data.Type.BITFLAGS:
			return Data.flags_to_string(_getter.call(), _enum_dict)
		
		_:
			return Data.custom_type_to_string(_getter.call(), _data_type)


## Gets the signal emitted when the name of an object is changed when using Data.Type.OBJECT
func get_object_name_changed_signal() -> Signal:
	return Data.get_object_name_changed_signal(self)


## Returns the ID of this SettingsModule
func get_id() -> String:
	return _id


## Returns the human-readable name of this SettingsModule
func get_name() -> String:
	return _name


## Returns the DataType of this SettingsModule
func get_data_type() -> Data.Type:
	return _data_type


## Returns the type flags of this SettingsModule
func get_type() -> int:
	return _type


## Returns the setter Callable for the connected parameter
func get_setter() -> Callable:
	return _setter


## Returns the getter Callable for the connected parameter
func get_getter() -> Callable:
	return _getter


## Returns the Signal for the connected parameter
func get_signals() -> Array[Signal]:
	return _signals


## Returns the class filter
func get_class_filter() -> Script:
	return _class_filter


## Gets the enum dict
func get_enum_dict() -> Dictionary:
	return _enum_dict


## Returns the IP type
func get_ip_type() -> IP.Type:
	return _ip_type


## Gets the edit condition
func get_edit_condition() -> Callable:
	return _edit_condition


## Gets the displat condition
func get_display_condition() -> Callable:
	return _display_condition


## Gets the min and max values as an array
func get_min_max() -> Array[Variant]:
	return _min_max


## Gets the min value
func get_min() -> Variant:
	return _min_max[0]


## Gets the max value
func get_max() -> Variant:
	return _min_max[1]


## Gets the custom panel PackedScene
func get_custom_panel() -> PackedScene:
	return _custom_panel_scene


## Gets the custom panel entry point
func get_custom_panel_entry_point() -> String:
	return _custom_panel_entry_point


## Gets the sub manager
func get_sub_manager() -> SettingsManager:
	return _sub_manager


## Gets the ActionMode
func get_action_mode() -> ActionMode:
	return _action_mode


## Gets the hold release callable
func get_hold_release_callable() -> Callable:
	return _hold_release_callable


## Gets the visual category
func get_visual_category() -> String:
	return _visual_category


## Gets the visual line
func get_visual_line() -> int:
	return _visual_line


## Gets the owner Object
func get_owner() -> Object:
	return _owner.get_ref()


## Sets the class filter
func set_class_filter(p_class_filter: Script) -> SettingsModule:
	_class_filter = p_class_filter
	return self


## Sets the enum dict
func set_enum_dict(p_enum_dict: Dictionary) -> SettingsModule:
	_enum_dict = p_enum_dict.duplicate()
	return self


## Sets the IP type
func set_ip_type(p_ip_type: IP.Type) -> SettingsModule:
	_ip_type = p_ip_type
	return self


## Sets the edit condition
func set_edit_condition(p_callable: Callable) -> SettingsModule:
	_edit_condition = p_callable
	return self


## Sets the display condition, if p_set_editable is true, set_edit_condition will also be set
func set_display_condition(p_callable: Callable, p_set_editable: bool = false) -> SettingsModule:
	_display_condition = p_callable
	
	if p_set_editable:
		set_edit_condition(p_callable)
	
	return self


## Sets the min and max values
func set_min_max(p_min: Variant, p_max: Variant) -> SettingsModule:
	_min_max = [p_min, p_max]
	return self


## Sets the custom panel scene
func set_custom_panel_scene(p_scene: PackedScene) -> SettingsModule:
	_custom_panel_scene = p_scene
	_getter = get_custom_panel
	return self


## Sets the custom panel entry point
func set_custom_panel_entry_point(p_entry_point: String) -> SettingsModule:
	_custom_panel_entry_point = p_entry_point
	return self


## Sets the sub manager
func set_sub_manager(p_sub_manager: SettingsManager) -> SettingsModule:
	_sub_manager = p_sub_manager
	_getter = get_sub_manager
	return self


## Sets the action mode
func set_action_mode(p_action_mode: ActionMode) -> SettingsModule:
	_action_mode = p_action_mode
	return self


## Sets the hold release callable
func set_hold_release_callable(p_hold_release_callable: Callable) -> SettingsModule:
	_hold_release_callable = p_hold_release_callable
	return self


## Sets the visual category
func set_visual_category(p_visual_category: String) -> SettingsModule:
	_visual_category = p_visual_category
	return self


## Sets the visual line
func set_visual_line(p_visual_line: int) -> SettingsModule:
	_visual_line = p_visual_line
	return self


## Returns true if this SettingsModule is editable
func is_editable() -> bool:
	if _type == Type.STATUS:
		return false
	elif _edit_condition.is_valid():
		return bool(_edit_condition.call())
	else:
		return true


## Returns true of this SettingsModule is displayable in a GUI
func is_displayable() -> bool:
	return bool(_display_condition.call())


## Conncts the given callable to all signals
func subscribe(p_callable: Callable) -> Callable:
	for p_signal: Signal in _signals:
		p_signal.connect(p_callable)
	
	return p_callable


## Disconnects the given callable to all signals
func unsubscribe(p_callable: Callable) -> void:
	for p_signal: Signal in _signals:
		p_signal.disconnect(p_callable)


## Connects the name changed signal to the given method
func connect_name_signal(p_callable: Callable) -> Callable:
	var name_signal: Signal = get_object_name_changed_signal()
	
	if not name_signal.is_null() and not name_signal.is_connected(p_callable):
		name_signal.connect(p_callable)
	
	return p_callable


## Disconnects the name changed signal from the given method
func disconnect_name_signal(p_callable: Callable) -> Callable:
	var name_signal: Signal = get_object_name_changed_signal()
	
	if not name_signal.is_null() and name_signal.is_connected(p_callable):
		name_signal.disconnect(p_callable)
	
	return p_callable


## Sets the category and line
func display(p_category: String, p_line: int = -1) -> SettingsModule:
	set_visual_category(p_category)
	set_visual_line(p_line)
	
	return self


## Sets action mode to ActionMode.HOLD and sets hold release callable to p_release_callable
func action_mode_hold(p_release_callable: Callable) -> SettingsModule:
	set_action_mode(ActionMode.HOLD)
	set_hold_release_callable(p_release_callable)
	
	return self


## Shorthand for set_action_mode(ActionMode.TOGGLE)
func action_mode_toggle() -> SettingsModule:
	set_action_mode(ActionMode.TOGGLE)
	
	return self
