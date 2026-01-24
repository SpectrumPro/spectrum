# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name EngineComponentDB extends Node
## Stores all the current components in the engine


## Emitted when a component is added to this engine
signal component_added(component: EngineComponent)

## Emitted when a component is deleted from this engine
signal component_removed(component: EngineComponent)


## Stores all the components in this DB
var _components: Dictionary = {}

## Stores all components by there class name
var _components_by_classname: Dictionary = {}

## Stores all the class callback signals
var _class_callbacks: Dictionary = {}

## Stores all the components that were just added or removed for a given class name. Allowing to emit the class callback all at once
var _just_changed_components: Dictionary = {}

## Is true when _emit_class_callbacks is to be called at the end of this frame
var _emit_class_callbacks_queued: bool = false

## Stores all the requests for components
var _component_requests: Dictionary = {}


## Ready
func _ready() -> void:
	Core.resetting.connect(func () -> void:
		_just_changed_components = {}
		_emit_class_callbacks_queued = false
	)


## Adds a component to the DB, returns false if it already exists
func register_component(p_component: EngineComponent) -> bool:
	if p_component.uuid() in _components:
		return false
	
	_components[p_component.uuid()] = p_component
	
	for classname: String in p_component.get_class_tree():
		if not classname in _components_by_classname:
			_components_by_classname[classname] = []
		_components_by_classname[classname].append(p_component)
	
	if p_component.uuid() in _component_requests:
		for callback: Callable in _component_requests[p_component.uuid()].duplicate():
			if callback.is_valid(): 
				callback.call(p_component)
		_component_requests.erase(p_component.uuid())
	
	_check_class_callbacks(p_component)
	p_component.delete_requested.connect(deregister_component.bind(p_component), CONNECT_ONE_SHOT)
	
	Network.register_network_object(p_component.uuid(), p_component.settings())
	component_added.emit(p_component)
	return true


## Removes a component to the DB, returns false if it never existed
func deregister_component(p_component: EngineComponent) -> bool:
	if not p_component.uuid() in _components:
		return false
	
	for classname: String in p_component.get_class_tree():
		_components_by_classname[classname].erase(p_component)
	
	_check_class_callbacks(p_component, true)
	
	Network.deregister_network_object(p_component.settings())
	_components.erase(p_component.uuid())
	
	component_removed.emit(p_component)
	return true


## Gets all the loaded components by classname
func get_components_by_classname(classname: String) -> Array:
	return _components_by_classname.get(classname, []).duplicate()


## Gets a component by a uuid
func get_component(uuid: String) -> EngineComponent:
	return _components.get(uuid)


## Checks if the given component exists in ComponentDB
func has_component(p_component: EngineComponent) -> bool:
	return _components.has(p_component.uuid())


## Use this method if you need to call a function once a component is added to the engine. This will only be called once
func request_component(p_uuid: String, p_callback: Callable) -> void:
	if not p_uuid:
		return
	
	if p_uuid in _components:
		p_callback.call(_components[p_uuid])
		
	else:
		if not p_uuid in _component_requests:
			_component_requests[p_uuid] = []
		
		_component_requests[p_uuid].append(p_callback)


## Removes a request
func remove_request(uuid: String, callback: Callable) -> void:
	if uuid in _component_requests and callback in _component_requests[uuid]:
		_component_requests[uuid].erase(callback)
		
		if not _component_requests[uuid]:
			_component_requests.erase(uuid)


## Adds a request to callback when a component is added that matches the classname, this will be called every time 
func request_class_callback(classname: String, callback: Callable) -> void:
	if not _class_callbacks.has(classname): 
		_class_callbacks[classname] = []
	
	_class_callbacks[classname].append(callback)


## Removes a request for a class callback
func remove_class_callback(classname: String, callback: Callable) -> void:
	if _class_callbacks.has(classname):
		_class_callbacks[classname].erase(callback)


## Checks if there are any class callbacks for this component
func _check_class_callbacks(component: EngineComponent, remove: bool = false) -> void:
	for classname: String in component.get_class_tree():
		if classname in _class_callbacks:
			if not _just_changed_components.has(classname): 
				_just_changed_components[classname] = {
					"added": [],
					"removed": []
				}
			
			if remove:
				_just_changed_components[classname].removed.append(component)
			else:
				_just_changed_components[classname].added.append(component)
			
			if not _emit_class_callbacks_queued:
				_emit_class_callbacks.call_deferred()
			_emit_class_callbacks_queued = true


## Emitts all the class callbacks, this function should be called using call_defered() allowing to emit all components at once, instead of one by one
func _emit_class_callbacks() -> void:
	if _just_changed_components:
		for classname: String in _just_changed_components:
			for callback: Callable in _class_callbacks[classname].duplicate():
				if callback.is_valid():
					callback.callv(_just_changed_components[classname].values())
				else:
					_class_callbacks[classname].erase(callback)
	
	_just_changed_components = {}
	_emit_class_callbacks_queued = false
