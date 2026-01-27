# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name InterfaceConfig extends Object
## Store interface configs


## File location to store the UI Save
var ui_save_location: String = "user://"

## File name to store the UI Save
var ui_save_file: String = "ui.json"

## File location to store the UI Save
var config_save_location: String = "user://"

## File name to store the UI Save
var config_save_file: String = "interface.conf"

## Array of notice ID not to show again
var notices_dont_show_again: Array[String]

## True if the UI should be saved to disk before the program closes
var save_ui_on_quit: bool = true

## UI Scale factor
var scale_factor: float = 1


## Default items in the UICommandPalette
var command_palette_default_items: Array[CommandPaletteEntry] = [
		CommandPaletteEntry.new(
			Interface.settings(),
			"Interface",
		),
		CommandPaletteEntry.new(
			Network.settings(),
			"Network",
		),
		CommandPaletteEntry.new(
			Network.get_active_handler_by_name("Constellation").get_local_node().settings_manager, 
			"Constellation", 
		)
	]

## Default items in the UIObjectPicker
var object_picker_default_items: Dictionary[Script, ClassTreeConfig] = {
		EngineComponent: ClassTreeConfig.new(
			ClassList.get_global_class_tree(), 
			ClassList.get_inheritance_map(),
			ClassList.is_class_hidden, 
			ComponentDB.get_components_by_classname, 
			func (p_component: EngineComponent): return p_component.classname(),
			func (p_component: EngineComponent): return p_component.name(),
			ClassList.does_class_inherit,
			Core.create_component,
		),
		NetworkItem: ClassTreeConfig.new(
			NetworkClassList.get_global_class_tree(), 
			NetworkClassList.get_inheritance_map(),
			NetworkClassList.is_class_hidden, 
			Network.get_items_by_classname, 
			func (p_item: NetworkItem): return p_item.get_script().get_global_name(),
			func (p_item: NetworkItem): return p_item.get_handler_name() if p_item is NetworkHandler else p_item.get_session_name() if p_item is NetworkSession else p_item.get_node_name() if p_item is NetworkNode else "",
			NetworkClassList.does_class_inherit,
			Callable()
		)
	}


## Built in start up notics
var startup_notices: Array[StartUpNotice] = [
		StartUpNotice.new()
		.set_title("Beta Software Notice!")
		.set_title_icon("res://assets/logos/spectrum/dark_scaled/spectrum_dark-64x64.png")
		.set_version(Details.version)
		.set_bbcode_body(
			"""[ul]
			Spectrum is currently in [b]active development[/b] and is considered [b]beta software[/b].
			Features may change, bugs may exist, and stability is [b]not yet guaranteed[/b].
			It is [b]not recommended for mission-critical or production use[/b] at this stage.
			[/ul]"""
		.replace("\t", ""))
		.set_confirm_button_text("Acknowledge")
		.set_link_text("Github Issues")
		.set_link_url("https://github.com/SpectrumPro/Spectrum/issues")
		.set_notice_id("BETANOTICEV1.0.0-beta.3")
]

## ConfigFile to save and load user config
var _config_access: ConfigFile


## init
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(config_save_location)
	_config_access = ConfigFile.new()


## Loads (or creates if not already) the user config override
func load_user_config() -> Error:
	_config_access.load(get_user_config_path())
	
	var block_list: Array[String] = []
	block_list.assign(type_convert(_config_access.get_value("Interface", "notices_dont_show_again"), TYPE_ARRAY))
	notices_dont_show_again = block_list
	
	scale_factor = type_convert(_config_access.get_value("Interface", "scale_factor", scale_factor), TYPE_FLOAT)
	save_ui_on_quit = type_convert(_config_access.get_value("Interface", "save_ui_on_quit", save_ui_on_quit), TYPE_BOOL)
	
	save_user_config()
	return OK


## Saves the user config to a file
func save_user_config() -> Error:
	_config_access.set_value("Interface", "notices_dont_show_again", notices_dont_show_again)
	
	_config_access.set_value("Interface", "scale_factor", scale_factor)
	_config_access.set_value("Interface", "save_ui_on_quit", save_ui_on_quit)
	
	return _config_access.save(get_user_config_path())


## Adds the given notice to the list of don't show again
func notice_dont_show_again(p_id: String) -> void:
	if notices_dont_show_again.has(p_id):
		return
	
	notices_dont_show_again.append(p_id)


## Checks if a notice can be shown
func can_show_notice(p_id: String) -> bool:
	return notices_dont_show_again.has(p_id)


## Returns the full filepath to the user config
func get_user_config_path() -> String:
	if config_save_location.ends_with("/"):
		return config_save_location + config_save_file
	else:
		return config_save_location + "/" + config_save_file
