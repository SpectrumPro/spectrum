# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name EngineComponent extends RefCounted
## Base class for an engine components, contains functions for storing metadata, and uuid's


## Emitted when an item is added or edited from user_meta
signal user_meta_changed(key: String, value: Variant)

## Emitted when an item is deleted from user_meta
signal user_meta_deleted(key: String)

## Emitted when the name of this object has changed
signal name_changed(new_name: String)

## Emitted when the CID is changed
signal cid_changed(cid: int)

## Emited when this object is about to be deleted
signal delete_requested(from: Object)


## The name of this object
var _name: String = "Unnamed EngineComponent"

## Uuid of the current component, do not modify at runtime unless you know what you are doing, things will break
var _uuid: String = ""

## The class_name of this component this should always be set by the object that extends EngineComponent
var _class_name: String

## Stores all the classes this component inherits from
var _class_tree: Array[String]

## Infomation that can be stored by other scripts / clients, this data will get saved to disk and send to all clients
var _user_meta: Dictionary

## ComponentID
var _cid: int = -1

## The SettingsManager
var _settings: SettingsManager = SettingsManager.new()


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	_uuid = p_uuid
	
	_settings.set_owner(self)
	_settings.set_inheritance_array(_class_tree)
	_settings.set_delete_signal(delete_requested)
	
	_settings.register_setting("name", Data.Type.STRING, set_name, get_name, [name_changed])
	
	#_settings.register_setting("CID", Data.Type.CID, CIDManager.set_component_id.bind(self), cid, [cid_changed])\
	#.display("EngineComponent", 1)
	
	_settings.register_networked_callbacks({
		"on_name_changed": _set_name,
		"on_delete_requested": delete,
		"on_user_meta_changed": _set_user_meta,
		"on_user_meta_deleted": _delete_user_meta
	})
	
	print_verbose("I am: ", get_name(), " | ", get_uuid())


## Seralizes an array of EngineComponents
static func seralise_component_array(array: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]
	
	for component: Variant in array:
		if component is EngineComponent:
			result.append(component.serialize())
	
	return result


## Deseralizes an array of seralized EngineComponents
static func deseralise_component_array(array: Array) -> Array[EngineComponent]:
	var result: Array[EngineComponent]
	
	for seralized_component: Variant in array:
		if seralized_component is Dictionary and seralized_component.has("class_name"):
			var component: EngineComponent = ClassList.get_class_script(seralized_component.class_name).new()
	
			component.deserialize(seralized_component)
			result.append(component)
	
	return result


## Gets the uuid
func get_uuid() -> String:
	return _uuid


## Gets the name
func get_name() -> String:
	return _name


## Gets the name
func get_uname() -> String:
	return _name


## Gets the classname of this EngineComponent
func get_class_name() -> String:
	return _class_name


## Gets the classname of this EngineComponent
func get_base_class() -> String:
	return _class_tree[-1]


## Gets the class tree
func get_class_tree() -> Array[String]:
	return _class_tree.duplicate()


## Gets the settings manager
func get_settings() -> SettingsManager:
	return _settings


## Gets the CID
func get_cid() -> int:
	return _cid


## Sets the name of this component
func set_name(new_name) -> Promise: 
	return rpc("set_name", [new_name])


## Sets the name of this EngineComponent
func set_uname(p_name: String, p_no_signal: bool = false) -> void:
	rpc("set_name", [p_name])


## Sets user_meta from the given value
func set_user_meta(key: String, value: Variant): 
	rpc("set_user_meta", [key, value])


## Delets an item from user meta, returning true if item was found and deleted, and false if not
func delete_user_meta(key: String) -> void: 
	rpc("delete_user_meta", [key])


## Returns the value from user meta at the given key, if the key is not found, default is returned
func get_user_meta(key: String, default = null) -> Variant: 
	return _user_meta.get(key, default)


## Returns all user meta
func get_all_user_meta() -> Dictionary:
	return _user_meta


## Calls a method on the remote object.
func rpc(p_method_name: String, p_args: Array = []) -> Promise:
	return Network.send_command(_uuid, p_method_name, p_args)


## Always call this function when you want to delete this component. 
func delete_rpc() -> void: 
	rpc("delete")


## Deletes this component localy, with out contacting the server. Usefull when handling server side delete requests
func delete() -> void:
	delete_requested.emit(self)
	print(_uuid, " Has had a delete request send. Currently has:", str(get_reference_count()), " refernces")


## Returns serialized version of this component
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return {
		"name": _name,
		"user_meta": get_all_user_meta(),
	}.merged({}
	if p_flags & Data.SerializationFlags.NO_UUID else {
		"uuid": _uuid
	})


## Loades this object from a serialized version
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	_set_name(type_convert(p_serialized_data.get("name", _name), TYPE_STRING), true)
	
	if not p_flags & Data.SerializationFlags.NO_UUID:
		_uuid = p_serialized_data.get("uuid", UUID.v4())
	
	_user_meta = type_convert(p_serialized_data.get("user_meta", _user_meta), TYPE_DICTIONARY)
	
	#var cid: int = type_convert(p_serialized_data.get("cid", -1), TYPE_INT)
	#if CIDManager.set_component_id_local(cid, self, true):
		#_cid = cid


## Internal: Sets the name of this component
func _set_name(p_name: String, p_no_signal: bool = false) -> void:
	_name = p_name
	
	if not p_no_signal:
		name_changed.emit(_name)


## Sets the self class name
func _set_class_name(p_class_name: String) -> void:
	_class_tree.append(p_class_name)
	_class_name = p_class_name


## Internal: Sets user meta
func _set_user_meta(p_key: String, p_value: Variant) -> void:
	_user_meta[p_key] = p_value
	user_meta_changed.emit(p_key, p_value)


## Internal: Deletes user meta
func _delete_user_meta(p_key: String) -> void:
	if _user_meta.erase(p_key):
		user_meta_deleted.emit(p_key)


## Debug function to tell if this component is freed from memory
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print("\"", self._name, "\" Is being freed, uuid: ", self._uuid)
