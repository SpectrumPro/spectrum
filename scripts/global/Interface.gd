# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ClientInterface extends Node
## Main script for the Spectrum Lighting Controller UI interface


## Emitted when a resolve request is required
signal resolve_requested(type: ResolveType, hint: ResolveHint, classname: String, color_hint: Color)

## Emitted when a window is added
signal window_added(window: UIWindow)

## Emitted when a window is removed
signal window_removed(window: UIWindow)

## Emitted when the UI scale factor is changed
signal scale_factor_changed(scale_factor: float)

## Emitted when the save ui on quit state is changed
signal save_ui_on_quit_changed(save_ui: bool)

## Emitted before the program is exited
signal program_closing()


## Enum for ResolveTypes
enum ResolveType {
	NONE,				## Disables resolve mode
	ANY,				## Resolves anything
	COMPONENT,			## Resolves an EngineComponent
	UIPANEL				## Resolves a UIPanel
}


## Enum for ResolveHint
enum ResolveHint {
	NONE,				## Default state
	SELECT,				## Requests to select a component
	ASSIGN,				## Requests to assign into
	STORE,				## Requests to store into
	EDIT,				## Requests to edit
	RENAME,				## Requests to rename a component
	EXECUTE,			## Requests to execute a function
	STOP,				## Requests to stop a function
	DELETE				## Requests to delete a component
}


## Enum for all WindowPopups
enum WindowPopup {
	PANEL_PICKER,		## PanelPicker class for selecting UIPanels
	PANEL_SETTINGS,		## PanelPicker class for selecting UIPanels
	MAIN_MENU,			## UI Main Menu
	SETTINGS,			## UISettings
	SAVE_LOAD,			## UISaveLoad
	COMMAND_PALETTE,	## UICommandPalette
	OBJECT_PICKER,		## UIObjectPicker
	SETTINGS_MODULE,	## Shows a SettingsModule
	WINDOW_MANAGER,		## UIWindowManager
	WINDOW_ID,			## UIWindowID
	MANIFEST_PICKER,	## UIManifestPicker
	INTERFACE_SELECTOR,	## UIInterfaceSelector
}


## Stores configuration for a WindowPopup instance
class PopupConfig:
	## Name of the node in the WindowPopups.tscn scene
	var node_name: String = ""
	
	## Name of the method used to apply the value
	var setter: String = ""
	
	## Maps each window to its associated node
	var nodes: Dictionary[Window, UIBase]
	
	## Maps each window to its setter callable
	var setter_callables: Dictionary[Window, Callable]
	
	## Maps each popups active state to the window
	var active_state: Dictionary[Window, bool]
	
	## Maps each window to its Promise
	var promises: Dictionary[Window, Promise]
	
	
	## Constructor
	func _init(p_node_name: String = "", p_setter: String = "") -> void:
		node_name = p_node_name
		setter = p_setter


## The current resolve hint, if any
var _current_resolve_hint: ResolveHint = ResolveHint.NONE

## The current resolve mode, if any
var _current_resolve_type: ResolveType = ResolveType.NONE

## The current resolve classname
var _current_resolve_classname: String = ""

## The current resolve color
var _current_resolve_color: Color = Color.TRANSPARENT

## The resolve Promise
var _resolve_promise: Promise = Promise.new()

## Colors for each resolve hint
var _resolve_hint_colors: Dictionary[ResolveHint, Color] = {
	ResolveHint.NONE:		ThemeManager.Colors.ResolveHint.None,
	ResolveHint.SELECT:		ThemeManager.Colors.ResolveHint.Select,
	ResolveHint.ASSIGN:		ThemeManager.Colors.ResolveHint.Assign,
	ResolveHint.STORE:		ThemeManager.Colors.ResolveHint.Store,
	ResolveHint.EDIT:		ThemeManager.Colors.ResolveHint.Edit,
	ResolveHint.RENAME:		ThemeManager.Colors.ResolveHint.Rename,
	ResolveHint.EXECUTE:	ThemeManager.Colors.ResolveHint.Execute,
	ResolveHint.STOP:		ThemeManager.Colors.ResolveHint.Stop,
	ResolveHint.DELETE:		ThemeManager.Colors.ResolveHint.Delete,
}


## Stores configuration for each WindowPopup that will be instanced on each window
var _window_popup_config: Dictionary[WindowPopup, PopupConfig] = {
	WindowPopup.PANEL_PICKER:		PopupConfig.new("UIPanelPicker", ""),
	WindowPopup.PANEL_SETTINGS:		PopupConfig.new("UIPanelSettings", "set_panel"),
	WindowPopup.MAIN_MENU:			PopupConfig.new("UIMainMenu", ""),
	WindowPopup.SETTINGS:			PopupConfig.new("UISettings", ""),
	WindowPopup.SAVE_LOAD:			PopupConfig.new("UISaveLoad", ""),
	WindowPopup.COMMAND_PALETTE:	PopupConfig.new("UICommandPalette", ""),
	WindowPopup.OBJECT_PICKER:		PopupConfig.new("UIObjectPicker", ""),
	WindowPopup.SETTINGS_MODULE:	PopupConfig.new("UIPopupSettingsModule", "set_module"),
	WindowPopup.WINDOW_MANAGER:		PopupConfig.new("UIWindowManager", ""),
	WindowPopup.WINDOW_ID:			PopupConfig.new("UIWindowID", ""),
	WindowPopup.MANIFEST_PICKER:	PopupConfig.new("UIManifestPicker"),
	WindowPopup.INTERFACE_SELECTOR: PopupConfig.new("UIInterfaceSelector")
}

## All windows by UUID RefMap for UUID: Window
var _windows: RefMap = RefMap.new()

## All WindowPopup scenes per window
var _window_popups: Dictionary[Window, Control]

## The WindowPopups scene to be instanced on each window
var _window_popups_scene: PackedScene = load("uid://ds42t8h4nusm4")

## All active fade animations
var _active_fade_animations: Dictionary[Object, Dictionary]

## All open UIPopupDialog refernced by the source node
var _open_popup_dialogs: Dictionary[Node, UIPopupDialog]

## Contains all searchable items
var _palette_search_index: Dictionary[String, Dictionary]

## Config items for the ObjectPicker
var _object_picker_index: Dictionary[Script, ClassTreeConfig]

## An instance of InterfaceConfig
var _config: InterfaceConfig = null

## The settings manager for ClientInterface
var settings_manager: SettingsManager = SettingsManager.new()


## Init
func _init() -> void:
	settings_manager.set_owner(self)
	settings_manager.set_inheritance_array(["Interface"])
	
	settings_manager.register_setting("ScaleFactor", Data.Type.FLOAT, set_scale_factor, get_scale_factor, [scale_factor_changed]).set_min_max(0.2, 2)
	settings_manager.register_setting("SaveUIOnQuit", Data.Type.BOOL, set_save_ui_on_quit, get_save_ui_on_quit, [save_ui_on_quit_changed])
	
	settings_manager.register_control("HideAllPopups", Data.Type.ACTION, hide_all_popup_panels, Callable(), [])
	settings_manager.register_control("OpenMainMenu", Data.Type.ACTION, set_popup_visable.bind(WindowPopup.MAIN_MENU, self, true), Callable(), [])
	settings_manager.register_control("OpenSettings", Data.Type.ACTION, set_popup_visable.bind(WindowPopup.SETTINGS, self, true), Callable(), [])
	settings_manager.register_control("OpenSaveLoad", Data.Type.ACTION, set_popup_visable.bind(WindowPopup.SAVE_LOAD, self, true), Callable(), [])
	settings_manager.register_control("OpenWindowManager", Data.Type.ACTION, set_popup_visable.bind(WindowPopup.WINDOW_MANAGER, self, true), Callable(), [])
	settings_manager.register_control("AddWindow", Data.Type.ACTION, add_window, Callable(), [])
	settings_manager.register_control("SaveUI", Data.Type.ACTION, save_ui, Callable(), [])


## Ready ClientInterface
func _ready() -> void:
	_load_config(load("res://InterfaceConfig.gd").new())
	get_window().set_script(UIWindow)
	
	var popups: Control = _window_popups_scene.instantiate()
	var root: UIWindow = get_tree().root
	
	_register_window_popups(popups, root)
	root.set_window_popups.call_deferred(popups)
	root._base_panel = root.get_node("UICore")
	
	_window_popups[root] = popups
	_windows.map("main", get_window())
	
	(func () -> void:
		load_ui()
	).call_deferred()


## Notification
func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_WM_CLOSE_REQUEST:
		Interface.prompt_popup_dialog(self, "Close Main Window?")\
		.button("Cancel", false)\
		.button("Close", true, Color.RED)\
		.then(quit)


## Registers all WindowPopups into the corrisponding PopupConfig class
func _register_window_popups(p_window_popups: Control, p_window: Window) -> void:
	for window_popup: WindowPopup in _window_popup_config.keys():
		_register_popup(window_popup, p_window_popups, p_window)


## Registers a WindowPopup on the given Window
func _register_popup(p_window_popup: WindowPopup, p_window_popups: Control, p_window: Window) -> void:
	var config: PopupConfig = _window_popup_config[p_window_popup]
	var popup: UIBase = p_window_popups.get_node(config.node_name)
	var setter: Callable
	var resolve_signal: Signal = popup.get_custom_signal_or_default() if popup is UIPopup else Signal()
	var reject_signal: Signal = popup.canceled if popup is UIPopup else popup.close_request
	var promise: Promise = Promise.new()
	
	if config.setter:
		setter = Callable(popup, config.setter)
	
	if not resolve_signal.is_null():
		resolve_signal.connect(func (...p_args):
			promise.resolve(p_args)
			_hide_window_popup(p_window_popup, p_window)
		)
	
	if not reject_signal.is_null():
		reject_signal.connect(func (...p_args):
			promise.reject(p_args)
			_hide_window_popup(p_window_popup, p_window)
		)
	
	config.nodes[p_window] = popup
	config.setter_callables[p_window] = setter
	config.active_state[p_window] = false
	config.promises[p_window] = promise
	popup.hide()


## Shows the given WindowPopup
func _show_window_popup(p_popup_type: WindowPopup, p_source: Node, p_setter_arg: Variant) -> Promise:
	var window = p_source.get_window()
	var config: PopupConfig = _window_popup_config[p_popup_type]
	var popup: UIPanel = config.nodes[window]
	var promise: Promise = config.promises[window]
	
	if config.active_state[window]:
		config.promises[window].clear()
	
	if p_setter_arg:
		config.setter_callables[window].call(p_setter_arg)
	
	config.active_state[window] = true
	show_and_fade(popup)
	
	popup.move_to_front()
	popup.focus()
	
	promise.set_object_refernce(popup)
	return promise


## Hides and active window popup
func _hide_window_popup(p_popup_type: WindowPopup, p_window: Window) -> void:
	var config: PopupConfig = _window_popup_config[p_popup_type]
	
	if not config.active_state[p_window]:
		return
	
	config.active_state[p_window] = false
	fade_and_hide(config.nodes[p_window])
	config.promises[p_window].clear()


## Prompts the user to select a UIPanel
func prompt_panel_picker(p_source: Node) -> Promise:
	return _show_window_popup(WindowPopup.PANEL_PICKER, p_source, null)


## Promps the user with UIPaneSettings
func prompt_panel_settings(p_source: Node, p_panel: UIPanel) -> Promise:
	return _show_window_popup(WindowPopup.PANEL_SETTINGS, p_source, p_panel)


## Promps the user with UIPaneSettings
func prompt_object_picker(p_source: Node, p_index: Script, p_class_filter: String) -> Promise:
	var promise: Promise = _show_window_popup(WindowPopup.OBJECT_PICKER, p_source, null)
	var object_picker: UIObjectPicker = promise.get_object_refernce()
	
	object_picker.set_select_mode(UIObjectPicker.SelectMode.OBJECT)
	object_picker.set_index(p_index, p_class_filter)
	
	return promise


## Prompts the user with UIManifestPicker
func prompt_manifest_picker(p_source: Node) -> Promise:
	var promise: Promise = _show_window_popup(WindowPopup.MANIFEST_PICKER, p_source, null)
	
	return promise


## Prompts the user with UIInterfaceSelector
func prompt_interface_selector(p_source: Node) -> Promise:
	var promise: Promise = _show_window_popup(WindowPopup.INTERFACE_SELECTOR, p_source, null)
	
	return promise


## Promps the user with UIPaneSettings
func prompt_create_component(p_source: Node, p_class_filter: String) -> Promise:
	var promise: Promise = _show_window_popup(WindowPopup.OBJECT_PICKER, p_source, null)
	var object_picker: UIObjectPicker = promise.get_object_refernce()
	
	object_picker.set_select_mode(UIObjectPicker.SelectMode.CLASS)
	object_picker.set_index(EngineComponent, p_class_filter)
	
	return promise


## Promps the user with SettingsModule
func prompt_settings_module(p_source: Node, p_module: SettingsModule) -> Promise:
	return _show_window_popup(WindowPopup.SETTINGS_MODULE, p_source, p_module)


## Promps the user with a DataInput
func prompt_data_input(p_source: Node, p_data_type: Data.Type, p_default: Variant, p_label: String) -> Promise:
	var promise: Promise = _show_window_popup(WindowPopup.SETTINGS_MODULE, p_source, null)
	var module_view: UIPopupSettingsModule = promise.get_object_refernce()
	var dummy_module: SettingsModule = SettingsModule.new(p_label, p_label, p_data_type, SettingsModule.Type.SETTING, promise.resolvev, func (): return p_default, [], p_source)
	
	module_view.set_module(dummy_module)
	module_view.focus()
	return promise


## Prompts the user with a delete confirmation dialog
func prompt_delete_confirmation(p_source: Node, p_title: String = "Confirm Deletion?") -> Promise:
	return prompt_popup_dialog(p_source, p_title).preset(UIPopupDialog.Preset.DELETE, p_title).promise()


## Creates and adds a blank UIPopupDialog
func prompt_popup_dialog(p_source: Node, p_title: String = "") -> UIPopupDialog:
	if _open_popup_dialogs.has(p_source):
		var open_dialog: UIPopupDialog = _open_popup_dialogs[p_source]
		
		open_dialog.focus()
		open_dialog.move_to_front()
		open_dialog.flash()
		
		return UIPopupDialog.new().set_promise(Promise.new().auto_reject())
	
	var window_popups: Control = _window_popups[p_source.get_window()]
	var new_dialog: UIPopupDialog = UIDB.instance_popup(UIPopupDialog)
	var promise: Promise = Promise.new()
	
	new_dialog.get_custom_signal_or_default().connect(func (...p_args): 
		promise.resolve(p_args)
		fade_and_hide(new_dialog, new_dialog.queue_free)
		_open_popup_dialogs.erase(p_source)
	)
	new_dialog.canceled.connect(func (): 
		promise.reject()
		fade_and_hide(new_dialog, new_dialog.queue_free)
		_open_popup_dialogs.erase(p_source)
	)
	
	if p_title:
		new_dialog.title(p_title)
	
	promise.set_object_refernce(new_dialog)
	window_popups.add_child(new_dialog)
	
	new_dialog.set_promise(promise)
	new_dialog.focus()
	new_dialog.hide()
	
	show_and_fade(new_dialog, new_dialog.focus)
	_open_popup_dialogs[p_source] = new_dialog
	return new_dialog


## Prompts the user with a custom panel popup
func prompt_panel_popup(p_source: Node, p_panel_class: Variant) -> UIPanel:
	var window_popups: Control = _window_popups[p_source.get_window()]
	var panel: UIPanel = UIDB.instance_panel(p_panel_class)
	
	if not is_instance_valid(panel):
		return null
	
	panel.close_request.connect(func ():
		fade_and_hide(panel, panel.queue_free)
	)
	
	panel.hide()
	panel.set_display_mode(UIPanel.DisplayMode.Popup)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	window_popups.add_child(panel)
	
	show_and_fade(panel)
	return panel


## Sets the visability of a WindowPopup
func set_popup_visable(p_popup_type: WindowPopup, p_source: Node, p_visible: bool) -> UIBase:
	if p_visible:
		_show_window_popup(p_popup_type, p_source, null)
	else:
		_hide_window_popup(p_popup_type, p_source.get_window())
	
	return get_window_popup(p_popup_type, p_source)


## Sets the visability of a WindowPopup
func toggle_popup_visable(p_popup_type: WindowPopup, p_source: Node) -> UIBase:
	var popup: UIBase = get_window_popup(p_popup_type, p_source)
	
	if not popup:
		return null
	
	if popup.visible:
		_hide_window_popup(p_popup_type, p_source.get_window())
	else:
		_show_window_popup(p_popup_type, p_source, null)
	
	return popup


## Hides all popup panels
func hide_all_popup_panels() -> void:
	for popup_type: WindowPopup in _window_popup_config:
		_hide_window_popup(popup_type, get_window())


## Saves the UI to the ui save file
func save_ui() -> void:
	Utils.save_json_to_file(_config.ui_save_location, _config.ui_save_file, serialize())
	_config.save_user_config()


## Loads the UI from the ui save file
func load_ui() -> void:
	deserialize(Utils.load_json_from_file(_config.ui_save_location, _config.ui_save_file))


func serialize() -> Dictionary:
	var serialize_data: Dictionary = {
		"windows": {}
	}
	
	for window_uuid: String in _windows.get_left():
		serialize_data.windows[window_uuid] = _windows.left(window_uuid).serialize()
	
	return serialize_data


## Deserializes the serialized data
func deserialize(p_serialized_data) -> void:
	var windows: Dictionary = type_convert(p_serialized_data.get("windows", {}), TYPE_DICTIONARY)
	
	for window_uuid: Variant in windows:
		if not window_uuid is String or not windows[window_uuid] is Dictionary: 
			continue
		
		var serialized_window: Dictionary = windows[window_uuid]
		
		if window_uuid == "main":
			get_window_node(self).deserialize(serialized_window)
		else:
			add_window(null).deserialize(serialized_window)


## Gets the WindowPopup for the window containing the p_source node
func get_window_popup(p_window_popup: WindowPopup, p_source: Node) -> UIBase:
	if not _window_popup_config.has(p_window_popup):
		return null
	
	var window: Window = p_source.get_window()
	var config: PopupConfig = _window_popup_config[p_window_popup]
	
	return config.nodes.get(window, null)


## Fades a property of an object and handles animation cleanup
func fade_property(p_object: Object, p_property: String, p_to: Variant, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	kill_fade(p_object, p_property)
	var tween: Tween = get_tree().create_tween()
	
	tween.tween_property(p_object, p_property, p_to, p_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func ():
		if is_instance_valid(p_object):
			_active_fade_animations[p_object].erase(p_property)
		else:
			_active_fade_animations.erase(null)
		
		if p_callback.is_valid():
			p_callback.call()
	)
	
	_active_fade_animations.get_or_add(p_object, {})[p_property] = tween


## Kills a running fade
func kill_fade(p_object: Object, p_property: String) -> void:
	if _active_fade_animations.get(p_object, {}).has(p_property):
		_active_fade_animations[p_object][p_property].kill()
		_active_fade_animations[p_object].erase(p_property)


## Checks if a property is currently fading
func is_fading(p_control: Control, p_property: String) -> bool:
	return _active_fade_animations.get(p_control, {}).has(p_property)


## Shows and fades in a control
func show_and_fade(p_control: Control, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	if p_control.visible and not is_fading(p_control, "modulate"):
		return
	
	p_control.modulate = Color.TRANSPARENT
	fade_property(p_control, "modulate", Color.WHITE, p_callback, p_time)
	p_control.show()


## Fades and hides a control
func fade_and_hide(p_control: Control, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	if not p_control.visible and not is_fading(p_control, "modulate"):
		return
	
	p_control.modulate = Color.WHITE
	fade_property(p_control, "modulate", Color.TRANSPARENT, func ():
		if is_instance_valid(p_control):
			p_control.hide()
			p_control.modulate = Color.WHITE
		
		if p_callback.is_valid():
			p_callback.call()
	, p_time)


## Sets the visibility of a control node with a fade time
func set_visible_and_fade(p_control: Control, p_visible: bool, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	if p_visible:
		show_and_fade(p_control, p_callback, p_time)
	else:
		fade_and_hide(p_control, p_callback, p_time)


## Stops any current fade and shows the given control node
func show(p_control: Control) -> void:
	kill_fade(p_control, "modulate")
	p_control.modulate = Color.WHITE
	p_control.show()


## Stops any current fade and shows the given control node
func hide(p_control: Control) -> void:
	kill_fade(p_control, "modulate")
	p_control.modulate = Color.WHITE
	p_control.hide()


## Adds a new window
func add_window(p_base_panel: Script = UICore) -> UIWindow:
	var new_window: UIWindow = UIWindow.new()
	var uuid: String = UUID_Util.v4()
	var popups: Control = _window_popups_scene.instantiate()
	
	_register_window_popups(popups, new_window)
	_window_popups[new_window] = popups
	_windows.map(uuid, new_window)
	
	new_window.set_initial_position(Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_KEYBOARD_FOCUS)
	add_child(new_window)
	
	(func () -> void:
		new_window.set_name("New Window")
		new_window.set_window_popups(popups)
		new_window.set_base_panel(UIDB.instance_panel(p_base_panel))
		new_window.set_window_title(new_window.name)
	).call_deferred()
	
	window_added.emit(new_window)
	return new_window


## Removes the given window
func remove_window(p_window: UIWindow) -> bool:
	if not _windows.has_right(p_window) or p_window.is_window_root():
		return false
	
	_windows.erase_right(p_window)
	p_window.queue_free()
	
	remove_child(p_window)
	window_removed.emit(p_window)
	
	return true


## Hides the given window
func close_window(p_window: UIWindow) -> bool:
	if not _windows.has_right(p_window) or p_window.is_window_root():
		return false
	
	p_window.hide()
	return true


## Hides the given window
func show_window(p_window: UIWindow) -> bool:
	if not _windows.has_right(p_window) or p_window.is_window_root():
		return false
	
	p_window.show()
	return true


## Shows the WindowID on all the given windows. or all windows
func show_window_id(p_on_windows: Array[UIWindow] = []) -> void:
	if not p_on_windows:
		p_on_windows = get_all_windows()
	
	for window: UIWindow in p_on_windows:
		_show_window_popup(WindowPopup.WINDOW_ID, window, null)


## Shows the WindowID on all the given windows. or all windows
func hide_window_id(p_on_windows: Array[UIWindow] = []) -> void:
	if not p_on_windows:
		p_on_windows = get_all_windows()
	
	for window: UIWindow in p_on_windows:
		_hide_window_popup(WindowPopup.WINDOW_ID, window)


## Gets all windows
func get_all_windows() -> Array[UIWindow]:
	var result: Array[UIWindow] = []
	result.assign(_windows.get_right())
	
	return result


## Gets the Window node the p_source node is in
func get_window_node(p_source: Node) -> UIWindow:
	var window: Window = p_source.get_window()
	
	while not _windows.has_right(window):
		window = window.get_window()
	
	return window


## Adds an entry to the command palette
func add_command_palette_entry(p_entry: CommandPaletteEntry) -> void:
	for module: SettingsModule in p_entry.get_settings_manager().get_modules().values():
		_palette_search_index.get_or_add(p_entry.get_class_name(), {})[module.get_id()] = module


## Gets the current ResolveHint
func get_current_resolve_hint() -> ResolveHint:
	return _current_resolve_hint


## Gets the current ResolveType
func get_current_resolve_type() -> ResolveType:
	return _current_resolve_type


## Gets the current resolve classname
func get_current_resolve_classname() -> String:
	return _current_resolve_classname


## Gets the current resolve color
func get_current_resolve_color() -> Color:
	return _current_resolve_color


## Gets the color for a resolve hint
func get_resolve_color(p_resolve_hint: ResolveHint) -> Color:
	return _resolve_hint_colors[p_resolve_hint]


## Enables the ResolveMode
func enter_resolve_mode(p_resolve_type: ResolveType, p_resolve_hint: ResolveHint, p_classname: String) -> Promise:
	_current_resolve_type = p_resolve_type
	_current_resolve_hint = p_resolve_hint
	_current_resolve_classname = p_classname
	_current_resolve_color = get_resolve_color(_current_resolve_hint)
	
	resolve_requested.emit(_current_resolve_type, _current_resolve_hint, _current_resolve_classname, _current_resolve_color)
	return _resolve_promise


## Exits resolve mode
func exit_resolve_mode() -> bool:
	if _current_resolve_type == ResolveType.NONE:
		return false
	
	_current_resolve_type = ResolveType.NONE
	_current_resolve_hint = ResolveHint.NONE
	_current_resolve_classname = "p_classname"
	_current_resolve_color = Color.TRANSPARENT
	
	resolve_requested.emit(_current_resolve_type, _current_resolve_hint, _current_resolve_classname, _current_resolve_color)
	return true


## Takes a screenshot of all screens
func take_screenshot() -> void:
	for window: UIWindow in _windows.get_right():
		var file_name: String = "user://" + str(Time.get_datetime_string_from_system())
		
		window.get_viewport().get_texture().get_image().save_png(file_name)
		print("Screenshot saved as: ", file_name)


## Returns the SettingsManager object for ClientInterface
func settings() -> SettingsManager:
	return settings_manager


## Returns the InterfaceConfig object
func config() -> InterfaceConfig:
	return _config


## Quits the program
func quit() -> void:
	program_closing.emit()
	
	if get_save_ui_on_quit():
		save_ui()
	
	get_tree().quit()


## Sets the UI Scale factor
func set_scale_factor(p_scale_factor: float) -> void:
	_config.scale_factor = p_scale_factor
	
	for window: UIWindow in _windows.get_right():
		window.content_scale_factor = p_scale_factor
	
	scale_factor_changed.emit(p_scale_factor)


## Sets the save ui on quit state
func set_save_ui_on_quit(p_save_ui: bool) -> void:
	_config.save_ui_on_quit = p_save_ui
	
	save_ui_on_quit_changed.emit(p_save_ui)

 
## Gets the UI scale factor
func get_scale_factor() -> float:
	return _config.scale_factor


## Gets the save UI on quit option
func get_save_ui_on_quit() -> bool:
	return _config.save_ui_on_quit


## Loads the local config file
func _load_config(p_config: InterfaceConfig) -> void:
	if is_instance_valid(_config):
		return
	
	_config = p_config
	_config.load_user_config()
	
	for entry: CommandPaletteEntry in p_config.command_palette_default_items:
		add_command_palette_entry(entry)
	
	for script: Script in p_config.object_picker_default_items:
		_object_picker_index[script] = p_config.object_picker_default_items[script]
	
	await get_tree().process_frame 
	
	set_scale_factor(_config.scale_factor)
