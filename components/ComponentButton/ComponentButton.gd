# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ComponentButton extends Button
## Button to select an EngineComponent


## Emitted when the object is changed
signal object_selected(object: EngineComponent)


## Classname filter to search for
@export var class_filter: Script

## Enables this button to follow global store mode
@export var enable_resolve_mode: bool = false

## Button enabled state
@export var enabled: bool = false

## Nodes group
@export_group("nodes")

## The control to act as the status label
@export var underline: Control


## The current object
var _component: EngineComponent = null

## The orignal user defined text of this button
var _orignal_text: String

## UUID of the EngineComponent to look for
var _look_for_component: String

## Signal connections for the EngineComponent
var _signal_group: SignalGroup = SignalGroup.new([
	_on_name_changed
])


## ready
func _ready() -> void:
	_orignal_text = get_text()
	set_enabled(enabled)


## Sets the select object
func set_component(p_component: EngineComponent) -> void:
	_signal_group.disconnect_object(_component)
	_component = p_component
	_signal_group.connect_object(_component)
	
	if not is_instance_valid(_component):
		set_text(_orignal_text)
		underline.set_modulate(ThemeManager.Colors.Statuses.Standby)
	
	else:
		set_text(_component.name())
		underline.set_modulate(ThemeManager.Colors.Statuses.Normal)
	
	remove_look_for()
	object_selected.emit(_component)


## Returns the object
func get_component() -> EngineComponent:
	return _component


## Returns the UUID of the component, or ""
func get_component_uuid() -> String:
	return _component.uuid() if is_instance_valid(_component) else ""


## Removes the ComponentDB request for the object
func remove_look_for() -> void:
	if _look_for_component:
		ComponentDB.remove_request(_look_for_component, _on_component_found)


## Looks for an object, or waits untill is added
func look_for(p_uuid: String) -> void:
	remove_look_for()
	_look_for_component = p_uuid
	
	if not p_uuid:
		return
	
	underline.set_modulate(ThemeManager.Colors.Statuses.Caution)
	ComponentDB.request_component(_look_for_component, _on_component_found)


## Sets the enabled state
func set_enabled(p_enabled) -> void:
	enabled = p_enabled
	
	if enabled and _component:
		underline.set_modulate(ThemeManager.Colors.Statuses.Normal)
	elif enabled and not _component:
		underline.set_modulate(ThemeManager.Colors.Statuses.Standby)
	elif enabled and not _component and _look_for_component:
		underline.set_modulate(ThemeManager.Colors.Statuses.Caution)
	elif not enabled:
		underline.set_modulate(ThemeManager.Colors.Statuses.Off)


## Called if ComponentDB find the component
func _on_component_found(p_component: EngineComponent) -> void:
	if ClassList.does_class_inherit(p_component.classname(), class_filter.get_global_name()):
		set_component(p_component)


## Called when the components name is changed
func _on_name_changed(new_name: String) -> void:
	text = new_name


## Called when the button is pressed
func _on_pressed() -> void:
	if not enabled:
		return
	
	Interface.prompt_object_picker(self, EngineComponent, class_filter.get_global_name()).then(func (p_component: EngineComponent):
		set_component(p_component)
	)
