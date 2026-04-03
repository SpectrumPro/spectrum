# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICorePrimarySideBar extends Control
## The primary side bar for UICore


## Emitted when a tab is added
signal tab_added(p_item: TabItem)

## Emitted when a tab is deleted
signal tab_deleted(p_item: TabItem)

## Emitted when the current tab is changed
signal tab_changed(p_tab: TabItem)

## Emited when an empty tab is selected
signal empty_tab_selected(p_index: int)

## Emitted when the use scroll state is changed
signal use_scroll_changed(p_use_scroll: bool)


## Maximun number of visable tabs
@export var max_visable_tabs: int = 20

## Minuimun Height in px for tab buttons
@export var button_min_height: int = 40

## Font size for tab buttons
@export var button_font_size: int = 11

## Separation in px for tab buttons
@export var button_separation: int = 4

## Size in PX for the menu bar overlay
@export var menu_bar_default_size: int = 900


@export_group("Nodes")

## The BoxContainer for tab Buttons
@export var _tab_button_container: BoxContainer

## The Menu Button
@export var _menu_button: Button

## The container for tab Control nodes
@export var _tab_control_container: Control

## The overlay container for overlays
@export var _overlay_container: Control

## The ScrollContainer that contains the _tab_button_container
@export var _tab_button_scroll: ScrollContainer

## The Edit Button
@export var _edit_button: Button

## The UICore
@export var _ui_core: UICore


## All tab Buttons stored by tab number
var _tab_buttons: Array[Button]

## RefMap for int: TabItem
var _tabs: RefMap = RefMap.new()

## Bound callabls for empty tabs
var _empty_tab_binds: Dictionary[int, Callable]

## The current tab
var _current_tab: TabItem

## The index of the current selected empty tab
var _current_empty_tab: int

## The UIMainMenu of this window
var _main_menu: UIMainMenu

## The Button Group to asign all tab buttons to
var _button_group: ButtonGroup = ButtonGroup.new()

## Sets the use scroll state
var _use_scroll: bool = false

## The SettingsManager for this UICorePrimarySideBar
var _settings: SettingsManager = SettingsManager.new()


## Init
func _init() -> void:
	_settings.set_owner(self)
	_settings.set_inheritance_array(["UICorePrimarySideBar"])
	
	_settings.register_setting("use_scroll", Data.Type.BOOL, set_use_scroll, get_use_scroll, [use_scroll_changed])\
	.display("UICorePrimarySideBar", 1)
	
	_settings.register_custom_panel("tabs", load("res://panels/UICore/SideBar/UICorePrimarySideBarSettings.tscn"), "set_side_bar")\
	.display("UICorePrimarySideBar", 2)


## Ready
func _ready() -> void:
	_load_default_buttons()
	create_tab(UIDB.instance_panel(UIDesk), 0).set_title("Desk")
	
	_tab_button_container.add_theme_constant_override("separation", button_separation)
	_main_menu = Interface.get_window_popup(UIMainMenu, self)
	_main_menu.visibility_changed.connect(func ():
		_menu_button.set_pressed_no_signal(_main_menu.visible)
	)


## Gets the SettingsManager
func get_settings() -> SettingsManager:
	return _settings


## Creates a new tab in an empty spot
func create_tab(p_panel: UIPanel, p_index: int) -> TabItem:
	if _tabs.has_left(p_index) or p_index < 0:
		return null
	
	var item: TabItem = TabItem.new(p_index)
	
	if _tab_buttons.get(p_index):
		var button: Button = _tab_buttons[p_index]
		
		item.set_button(button)
		item.set_label(button.get_meta("label"))
		
		item._connect_bind(switch_to_tab, set_tab_panel, set_tab_index)
		button.pressed.disconnect(_empty_tab_binds[p_index])
	
	_tabs.map(p_index, item)
	item._set_index(p_index)
	
	set_tab_panel(p_panel, item)
	tab_added.emit(item)
	
	if p_index == _current_empty_tab:
		switch_to_tab(item)
	
	return item


## Sets the UIPanel on the given tab
func set_tab_panel(p_panel: UIPanel, p_tab: TabItem) -> void:
	if p_tab.get_panel():
		_tab_control_container.remove_child(p_tab.get_panel())
		p_tab.get_panel().queue_redraw()
	
	_tab_control_container.add_child(p_panel)
	p_tab._set_panel(p_panel)
	
	if p_tab == _current_tab:
		p_panel.set_visible(true)
	else:
		p_panel.set_visible(false)
	
	if not p_panel.is_node_ready():
		await p_panel.ready
	
	var menu_bar: PanelMenuBar = p_panel.detatch_menu_bar()
	
	if is_instance_valid(menu_bar):
		_overlay_container.add_child(menu_bar)
		p_panel.get_menu_bar().size.x = menu_bar_default_size
		p_panel.get_menu_bar().set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_WIDTH)
		p_panel.get_menu_bar().set_visible(false)
	else:
		print(p_panel, " does not have valid PanelMenuBar")
		print(p_panel.get_path)
		p_panel.modulate = Color.RED


## Sets the tab index
func set_tab_index(p_index: int, p_tab: TabItem) -> bool:
	if p_tab.get_index() == p_index:
		return false
	
	if _tabs.has_left(p_index):
		return false
	
	if p_tab == _current_tab and p_tab.get_button():
		p_tab.get_button().set_pressed_no_signal(false)
		
	if p_index < _tab_buttons.size():
		p_tab.set_button(_tab_buttons[p_index])
		p_tab.set_label(_tab_buttons[p_index].get_meta("label"))
	
	else:
		p_tab.set_button(null)
		p_tab.set_label(null)
	
	if p_tab == _current_tab and p_tab.get_button():
		p_tab.get_button().set_pressed_no_signal(true)
	
	_tabs.erase_left(p_tab.get_index())
	_tabs.map(p_index, p_tab)
	
	p_tab._set_index(p_index)
	return true


## Changes to the given tab
func switch_to_tab(p_tab: TabItem) -> void:
	if p_tab == _current_tab:
		return
	
	if is_instance_valid(_current_tab):
		Interface.fade_and_hide(_current_tab.get_panel().get_menu_bar())
		Interface.fade_and_hide(_current_tab.get_panel())
		
		if _current_tab.get_button():
			_current_tab.get_button().set_pressed_no_signal(false)
	
	_current_tab = p_tab
	_current_empty_tab = -1
	_edit_button.set_pressed_no_signal(false)
	
	if is_instance_valid(_current_tab):
		Interface.show_and_fade(_current_tab.get_panel())
		_edit_button.set_pressed_no_signal(_current_tab.get_panel().get_edit_mode())
		
		if _current_tab.get_panel().get_edit_mode(): 
			Interface.show_and_fade(_current_tab.get_panel().get_menu_bar())
			
		if _current_tab.get_button():
			_current_tab.get_button().set_pressed_no_signal(true)
	
	tab_changed.emit(_current_tab)


## Deletes a tab
func delete_tab(p_tab: TabItem) -> void:
	if not _tabs.has_right(p_tab):
		return
	
	if p_tab == _current_tab:
		switch_to_tab(null)
	
	if p_tab.get_panel():
		_tab_control_container.remove_child(p_tab.get_panel())
		p_tab.get_panel().queue_free()
	
	if p_tab.get_button():
		_connect_empty_tab_bound(p_tab.get_button(), p_tab.get_index())
	
	p_tab._disconnect_bind()
	p_tab.set_button(null)
	p_tab.set_label(null)
	
	_tabs.erase_right(p_tab)
	tab_deleted.emit(p_tab)


## Updates the visable buttons to match the current size
func match_visable_to_size() -> void:
	if _use_scroll:
		return
	
	var container_height: int = _tab_button_scroll.size.y
	
	for i: int in range(len(_tab_buttons)):
		var button: Button = _tab_buttons[i]
		
		button.visible = (i + 1) * (button_min_height + button_separation) <= container_height


## Set the use scroll state
func set_use_scroll(p_use_scroll: bool) -> void:
	_use_scroll = p_use_scroll
	
	if _use_scroll:
		for button: Button in _tab_buttons:
			button.set_visible(true)
	else:
		match_visable_to_size()
	
	use_scroll_changed.emit(_use_scroll)


## Gets the use scroll state
func get_use_scroll() -> bool:
	return _use_scroll
 

## Gets the index of the current selected empty tab, or -1
func get_current_empty_tab() -> int:
	return _current_empty_tab


## Gets the index of the next empty tab
func get_next_empty_tab() -> int:
	var index: int = 0
	
	while _tabs.has_left(index):
		index += 1
	
	return index


## Returns all tabs
func get_tabs() -> Array[TabItem]:
	var result: Array[TabItem]
	result.assign(_tabs.get_right())
	return result


## Saves all the tabs
func serialize() -> Dictionary:
	var tabs: Dictionary[int, Dictionary] = {
	}
	
	for tab_id: int in _tabs.get_left():
		tabs[tab_id] = _tabs.left(tab_id).serialize()
	
	return {
		"tabs": tabs,
		"current": _current_tab.get_index() if _current_tab else -1
	}


## Loads all the tabs
func deserialize(p_saved_data: Dictionary) -> void:
	var tabs: Dictionary = type_convert(p_saved_data.get("tabs", []), TYPE_DICTIONARY)
	var current_tab: int = type_convert(p_saved_data.get("current", 0), TYPE_INT)
	
	for tab_id: Variant in tabs:
		if not tab_id is String or not tabs[tab_id] is Dictionary:
			continue
		
		var title: String = type_convert(tabs[tab_id].get("title", ""), TYPE_STRING)
		var serialized_panel: Dictionary = type_convert(tabs[tab_id].get("panel", ""), TYPE_DICTIONARY)
		var panel_class: String = serialized_panel.get("class_name")
		
		var tab_id_int: int = int(tab_id)
		var tab_item: TabItem
		
		if _tabs.has_left(tab_id_int):
			tab_item = _tabs.left(tab_id_int)
		else:
			tab_item = create_tab(UIDB.instance_panel(panel_class), tab_id_int)
		
		tab_item.set_title(title)
		tab_item.get_panel().deserialize(serialized_panel)
	
	switch_to_tab(_tabs.left(current_tab))


## Loads the default number of buttons
func _load_default_buttons() -> void:
	for i in range(max_visable_tabs + 1):
		var new_button: Button = _create_tab_button("", i)
		
		_tab_buttons.append(new_button)
		_tab_button_container.add_child(new_button)


## Creates a tab button
func _create_tab_button(p_text: String, p_index: int) -> Button:
	var button: Button = Button.new()
	var label: Label = Label.new()
	
	label.text = p_text
	label.add_theme_font_size_override("font_size", button_font_size)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	button.set_meta("label", label)
	button.add_child(label)
	
	button.custom_minimum_size = Vector2(0, button_min_height)
	button.self_modulate = ThemeManager.Colors.UICorePrimarySideBarDisabledTabModulate
	button.toggle_mode = true
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.button_group = _button_group
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	
	_connect_empty_tab_bound(button, p_index)
	return button


## Connects the empty tab button pressed bound callable
func _connect_empty_tab_bound(p_button: Button, p_index: int) -> void:
	_empty_tab_binds[p_index] = _on_empty_tab_button_pressed.bind(p_index)
	p_button.pressed.connect(_empty_tab_binds[p_index])


## Called when an empty tab button is pressed
func _on_empty_tab_button_pressed(p_index: int) -> void:
	switch_to_tab(null)
	_current_empty_tab = p_index
	empty_tab_selected.emit(p_index)


## Called when the Edit button is toggled
func _on_edit_toggled(p_toggled_on: bool) -> void:
	if _current_tab:
		_current_tab.get_panel().set_edit_mode(p_toggled_on)
		Interface.set_visible_and_fade(_current_tab.get_panel().get_menu_bar(), p_toggled_on)


## Called when the main menu button is toggled
func _on_menu_toggled(p_toggled_on: bool) -> void:
	Interface.set_popup_visable(UIMainMenu, self, p_toggled_on)


## Called for each GUI input on the edit button
func _on_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		_ui_core.show_settings()


## TabItem Class
class TabItem extends RefCounted:
	
	## Emitted when the title is changed
	signal title_changed(title: String)
	
	## Emitted when the panel is changed
	signal panel_changed(panel: UIPanel)
	
	## Emitted when the panel is changed
	signal request_panel_changed(panel: UIPanel)
	
	## Emitted when the index is changed
	signal index_changed(p_index: int)
	
	## Emitted when a move is requested
	signal request_index_change(p_index: int)
	
	
	## The title
	var _title: String = ""
	
	## The button
	var _button: Button
	
	## The label
	var _label: Label
	
	## The UIPanel
	var _panel: UIPanel
	
	## The current index
	var _index: int
	
	## The bound Callable used to switch the tab
	var _bound_switch_callable: Callable = Callable()
	
	## The bound callable use to change the UIPanel
	var _bound_change_panel_callabe: Callable = Callable()
	
	## The bound callable used to set the tab index
	var _bound_set_index_callable: Callable = Callable()
	
	## SettingsManager for this TabItem
	var _settings: SettingsManager = SettingsManager.new()
	
	
	## Init
	func _init(p_index: int, p_button: Button = null, p_label: Label = null) -> void:
		_button = p_button
		_label = p_label
		_index = p_index
		
		_settings.set_owner(self)
		_settings.set_inheritance_array(["TabItem"])
		_settings.register_setting("title", Data.Type.STRING, set_title, get_title, [title_changed])
		_settings.register_setting("panel", Data.Type.PACKEDSCENE, set_panel, get_panel, [panel_changed]).set_sub_type(Data.Sub.Type.PACKEDSCENE_UIPANEL)
		_settings.register_setting("index", Data.Type.INT, set_index, get_index, [index_changed]).set_min_max(0, 65535)
	
	
	## Gets the SettingsManager
	func get_settings() -> SettingsManager:
		return _settings
	
	
	## Sets the title
	func set_title(p_title: String) -> void:
		_title = p_title
		
		if is_instance_valid(_label):
			_label.set_text(p_title)
			
		title_changed.emit(p_title)
	
	
	## Sets the panel
	func set_panel(p_panel: UIPanel) -> void:
		request_panel_changed.emit(p_panel)
	
	
	## Sets the index of this tab
	func set_index(p_index: int) -> bool:
		if _bound_set_index_callable.is_valid():
			return _bound_set_index_callable.call(p_index)
		else:
			return false
		#request_index_change.emit(p_index)
	
	
	## Sets the button
	func set_button(p_button: Button) -> void:
		if is_instance_valid(_button):
			_button.set_self_modulate(ThemeManager.Colors.UICorePrimarySideBarDisabledTabModulate)
			_button.gui_input.disconnect(_on_button_gui_input)
			
			if _bound_switch_callable.is_valid() and _button.pressed.is_connected(_bound_switch_callable):
				_button.pressed.disconnect(_bound_switch_callable)
		
		_button = p_button
		
		if is_instance_valid(_button):
			_button.set_self_modulate(ThemeManager.Colors.UICorePrimarySideBarTabModulate)
			_button.gui_input.connect(_on_button_gui_input)
			
			if _bound_switch_callable.is_valid() and not _button.pressed.is_connected(_bound_switch_callable):
				_button.pressed.connect(_bound_switch_callable)
	
	
	## Sets the label
	func set_label(p_label: Label) -> void:
		if is_instance_valid(_label):
			_label.set_text("")
		
		_label = p_label
		
		if is_instance_valid(_label):
			_label.set_text(_title)
	
	
	## Gets the title
	func get_title() -> String:
		return _title
	
	
	## Gets the UIPanel
	func get_panel() -> UIPanel:
		return _panel
	
	
	## Gets the index
	func get_index() -> int:
		return _index
	
	
	## Gets the button
	func get_button() -> Button:
		return _button
	
	
	## Gets the Label
	func get_label() -> Label:
		return _label
	
	
	## Returns a serialized version of this TabItem
	func serialize() -> Dictionary:
		return {
			"title": get_title(),
			"panel": get_panel().serialize() if get_panel() else {},
		}
	
	
	## Sets the index
	func _set_index(p_index: int) -> void:
		_index = p_index
		index_changed.emit(p_index)
	
	
	## Sets the panel
	func _set_panel(p_panel: UIPanel) -> void:
		_panel = p_panel
		panel_changed.emit(_panel)
	
	
	## Connects a version of the callable with self bound
	func _connect_bind(p_switch_callable: Callable, p_panel_callable: Callable, p_index_calllable: Callable) -> void:
		_bound_switch_callable = p_switch_callable.bind(self)
		_bound_change_panel_callabe = p_panel_callable.bind(self)
		_bound_set_index_callable = p_index_calllable.bind(self)
		
		request_panel_changed.connect(_bound_change_panel_callabe)
		request_index_change.connect(_bound_set_index_callable)
		if _button:
			_button.pressed.connect(_bound_switch_callable)
	
	
	## Disconnects the buttons bound callable
	func _disconnect_bind() -> void:
		if _button and _bound_switch_callable and _button.pressed.is_connected(_bound_switch_callable):
			_button.pressed.disconnect(_bound_switch_callable)
		
		if _bound_change_panel_callabe and request_panel_changed.is_connected(_bound_change_panel_callabe):
			request_panel_changed.disconnect(_bound_change_panel_callabe)
		
		if _bound_set_index_callable and request_index_change.is_connected(_bound_set_index_callable):
			request_index_change.disconnect(_bound_set_index_callable)
	
	
	## Called for each GUI input on the button
	func _on_button_gui_input(p_event: InputEvent) -> void:
		if p_event is InputEventMouseButton and p_event.is_pressed():
			p_event = p_event as InputEventMouseButton
			
			match p_event.button_index:
				MOUSE_BUTTON_RIGHT:
					Popups.show_settings_manager(_button, _settings)
