## Config for Data
static var config: Dictionary[String, Variant] = {
	"custom_type_to_string_method": custom_type_to_string,
	"get_object_name_signal_method": get_object_name_changed_signal,
}


## Converts a custom data type to a string, with a human readable name
@warning_ignore("unused_parameter")
static func custom_type_to_string(p_variant: Variant, p_orignal_type: Data.Type) -> Variant:
	if p_variant is Object and is_instance_valid(p_variant) and p_variant.has_method("get_uname"):
		return p_variant.get_uname()
	
	## else return false to use default convertion
	return false


## Returns the signal emitted when the name of an object is changed
static func get_object_name_changed_signal(p_module: SettingsModule) -> Variant:
	var object: Variant = p_module.get_getter().call()
	
	## return Signal() if the object type is invalid, or has no name signal
	if typeof(object) != TYPE_OBJECT or not is_instance_valid(object):
		return Signal()
	
	if object.has_signal("name_changed"):
		return object.name_changed
	
	## else return false to use default 
	return false
