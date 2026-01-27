# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Data extends Object
## Class to manage custom data types


## Enum for Type
enum Type {
	NULL,				## Represents no value (null / None)
	STRING,				## A standard text string
	BOOL,				## A true/false boolean value
	INT,				## A 64-bit integer number
	FLOAT,				## A floating-point number
	ARRAY,				## A dynamic array of values
	DICTIONARY,			## A key/value map (hash table)
	VECTOR2,			## A 2D vector (x, y) with floats
	VECTOR2I,			## A 2D vector (x, y) with integers
	RECT2,				## A 2D rectangle defined by position and size (floats)
	RECT2I,				## A 2D rectangle defined by position and size (integers)
	VECTOR3,			## A 3D vector (x, y, z) with floats
	VECTOR3I,			## A 3D vector (x, y, z) with integers
	VECTOR4,			## A 4D vector (x, y, z, w) with floats
	VECTOR4I,			## A 4D vector (x, y, z, w) with integers
	COLOR,				## A color with red, green, blue, and alpha channels
	OBJECT,				## A reference to any Godot Object (Node, Resource, etc.)
	CALLABLE,			## A callable function reference
	SIGNAL,				## A signal reference (connectable event)
	ENUM,				## An enumerator
	BITFLAGS,			## Bit Flags
	NAME,				## A symbolic name or identifier 
	IP,					## An IP address
	CID,				## An EngineComponent ID
	NETWORKSESSION,		## A NetworkSession
	NETWORKNODE,		## A NetworkNode
	NETWORKHANDLER,		## A NetworkHandler
	ENGINECOMPONENT,	## An EngineComponent
	FIXTUREMANIFEST,	## An EngineComponent
	UIPANEL,			## A UI Panel
	INPUTEVENT,			## An InputEvent
	CUSTOMPANEL,		## A custom UIPanel
	SETTINGSMANAGER,	## A SettingsManager
	ACTION,				## An Action that can be triggred
}


## Map custom Type to Godot Variant.Type
static var custom_type_map: Dictionary[Type, Variant.Type] = {
	Type.NULL: 				TYPE_NIL,
	Type.STRING:			TYPE_STRING,
	Type.BOOL: 				TYPE_BOOL,
	Type.INT: 				TYPE_INT,
	Type.FLOAT:				TYPE_FLOAT,
	Type.ARRAY: 			TYPE_ARRAY,
	Type.DICTIONARY: 		TYPE_DICTIONARY,
	Type.VECTOR2: 			TYPE_VECTOR2,
	Type.VECTOR2I: 			TYPE_VECTOR2,
	Type.RECT2: 			TYPE_RECT2,
	Type.RECT2I: 			TYPE_RECT2,
	Type.VECTOR3: 			TYPE_VECTOR3,
	Type.VECTOR3I: 			TYPE_VECTOR3,
	Type.VECTOR4: 			TYPE_VECTOR4,
	Type.VECTOR4I: 			TYPE_VECTOR4,
	Type.COLOR:				TYPE_COLOR,
	Type.OBJECT: 			TYPE_OBJECT,
	Type.CALLABLE: 			TYPE_CALLABLE,
	Type.SIGNAL: 			TYPE_SIGNAL,
	Type.ENUM: 				TYPE_INT,
	Type.BITFLAGS: 			TYPE_INT,
	Type.NAME: 				TYPE_STRING,
	Type.IP:				TYPE_STRING,
	Type.NETWORKSESSION: 	TYPE_OBJECT,
	Type.NETWORKNODE: 		TYPE_OBJECT,
	Type.NETWORKHANDLER: 	TYPE_OBJECT,
	Type.ENGINECOMPONENT: 	TYPE_OBJECT,
	Type.FIXTUREMANIFEST: 	TYPE_OBJECT,
	Type.UIPANEL:			TYPE_OBJECT,
	Type.CUSTOMPANEL:		TYPE_OBJECT,
	Type.SETTINGSMANAGER:	TYPE_OBJECT,
	Type.ACTION:			TYPE_NIL,
}


## Returns true if the 2 given types have a matching Variant.Type base
static func do_types_match_base(p_type_one: Type, p_type_two: Type) -> bool:
	var type_one_base: Variant.Type = custom_type_map[p_type_one]
	var type_two_base: Variant.Type = custom_type_map[p_type_two]
	
	return type_one_base == type_two_base


## Converts any bitmask enum into a readable string like "FLAG1+FLAG2"
static func flags_to_string(p_flags: int, p_enum: Dictionary) -> String:
	var names: Array[String] = []
	
	for name in p_enum.keys():
		var value: int = p_enum[name]
		
		if value != 0 and (p_flags & value) != 0:
			names.append(name)
	
	return "+".join(names)


## Converts custom data types
static func data_type_convert(p_variant: Variant, p_type: Type) -> Variant:
	return type_convert(p_variant, custom_type_map[p_type])


## Converts a custom data type to a string, with a human readable name
static func custom_type_to_string(p_variant: Variant, p_origin_type: Type) -> String:
	match p_origin_type:
		Type.NETWORKSESSION:
			return (p_variant as NetworkSession).get_session_name() if p_variant else ""
		
		Type.NETWORKNODE:
			return (p_variant as NetworkNode).get_node_name() if p_variant else ""
		
		Type.NETWORKHANDLER:
			return (p_variant as NetworkHandler).get_handler_name() if p_variant else ""
		
		Type.ENGINECOMPONENT:
			return (p_variant as EngineComponent).get_name() if p_variant else ""
		
		Type.INPUTEVENT:
			return (p_variant as InputEvent).as_text() if p_variant else ""
		
		_:
			return type_convert(p_variant, TYPE_STRING)


## Returns the signal emitted when the name of an object is changed
static func get_object_name_changed_signal(p_module: SettingsModule) -> Signal:
	var object: Variant = p_module.get_getter().call()
	
	if not typeof(object) == TYPE_OBJECT and not is_instance_valid(object):
		return Signal()
	
	match p_module.get_data_type():
		Type.ENGINECOMPONENT:
			return object.name_changed
		
		Type.NETWORKNODE:
			return object.node_name_changed
		
		_:
			return Signal()

	
