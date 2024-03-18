# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name DataIOPlugin extends EngineComponent
## Engine base class for all input and output plugins

var type: String = "" ## Type of this plugin, either input or output
var file_name: String = "" ## File name for this plugins scritp, used when loading a save file

func set_type(new_type:String) -> void:
	type = new_type


func get_type() -> String:
	return type


func delete() -> void:
	return
