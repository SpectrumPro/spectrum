# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

extends PanelContainer

## UI Panel for controlling a CueList

## The settings node used to choose what scenes are to be shown 
@onready var settings_node: Control = $Settings

## The current cue list
var current_cue_list: CueList

## Stores the UUID of the last CueList that was shown here when save() was called
## Stored here in case the CueList hasn't been added to the engine yet
var saved_cue_list_uuid: String = ""

## The current selected item
var current_selected_item: ListItem : set = _set_current_selected_item

## The last selected item
var last_selected_item: ListItem

## Stores the cue and its related list item in the UI
## Stored as {cue_number: ListItem}
var object_refs: Dictionary

## Stores the cue and its related list item in the UI
## Stored as {ListItem: cue_number}
var cue_refs: Dictionary

## The last index that this cue list was on
var old_index: float = 0


## Edit mode
var _edit_mode: bool = false

## Current selected Cue object
var _current_selected_cue: Cue = null

## Used to create the global cue controls
var _pre_wait: float = 0
var _fade_time: float = 0

## The fade in and hold time inputs for the global cue
var _global_cue_fade_time: SpinBox = null
var _global_cue_pre_wait_time: SpinBox = null

## Number of cues to leave visible when autoscrolling
var _scroll_extra: int = 3


## Colors for cues that have been highlighted
var _cue_highlight_color: Color = Color.ROYAL_BLUE
var _cue_default_color: Color = Color.WHITE


## The ItemListView used to display cues
@onready var cue_list_container: VBoxContainer = $VBoxContainer/List/VBoxContainer/ScrollContainer/VBoxContainer

@onready var scroll_container: ScrollContainer = $VBoxContainer/List/VBoxContainer/ScrollContainer

@onready var global_cue: ListItem = $VBoxContainer/List/VBoxContainer/GlobalCue

@onready var edit_controls: PanelContainer = $VBoxContainer/PanelContainer/HBoxContainer/EditControls

## Stores the labels that display status information about the scene
@onready var labels: Dictionary = {
	"cue_number": $VBoxContainer/Controls/HBoxContainer/InfoContainer/HBoxContainer/CueNumber,
	"cue_label": $VBoxContainer/Controls/HBoxContainer/InfoContainer/HBoxContainer/CueLabel,
	"separator": $VBoxContainer/Controls/HBoxContainer/InfoContainer/HBoxContainer/VSeparator,
	"paused": $VBoxContainer/Controls/HBoxContainer/InfoContainer/HBoxContainer/Paused,
	"playing": $VBoxContainer/Controls/HBoxContainer/InfoContainer/HBoxContainer/Playing,
	"stopped": $VBoxContainer/Controls/HBoxContainer/InfoContainer/HBoxContainer/Stopped,
}

## All the shortcut buttons in the settings panel
@onready var shortcut_buttons: Dictionary = {
	"PreviousShortcutButton": $Settings/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/PreviousShortcutButton,
	"GoShortcutButton": $Settings/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/GoShortcutButton,
	"NextShortcutButton": $Settings/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/NextShortcutButton,
	"PlayShortcutButton": $Settings/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/PlayShortcutButton,
	"PauseShortcutButton": $Settings/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/PauseShortcutButton,
	"StopShortcutButton": $Settings/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/StopShortcutButton,
}

var store_function_button_group: ButtonGroup = null
@onready var store_function_buttons: Dictionary = {
	"merge": $StoreConfirmationBox/VBoxContainer2/StoreModes/Merge,
	"erace": $StoreConfirmationBox/VBoxContainer2/StoreModes/Erace,
	"new_cue": $StoreConfirmationBox/VBoxContainer2/StoreModes/NewCue,
}

var save_mode_button_group: ButtonGroup = null
@onready var save_mode_buttons: Dictionary = {
	"modified_channels": $StoreConfirmationBox/VBoxContainer2/SaveModes/ModifiedChannels,
	"all_channels": $StoreConfirmationBox/VBoxContainer2/SaveModes/AllChannels,
	"all_none_zero": $StoreConfirmationBox/VBoxContainer2/SaveModes/AllNoneZero,
}


## Called when a cue has its data changed, will then go and call the _highlight_cues_with_stored_fixtures method with the selected fixtures
var _reload_highlights_signal_callback: Callable = func (arg1=null, arg2=null, arg3=null) -> void:
	_highlight_cues_with_stored_fixtures(Values.get_selection_value("selected_fixtures", []))


func _ready() -> void:
	Core.functions_added.connect(_on_functions_added)
	Core.functions_removed.connect(_on_functions_removed)
	Values.connect_to_selection_value("selected_fixtures", _on_selected_fixtures_changed)
	
	global_cue.set_item_name("Global")
	_global_cue_fade_time = global_cue.add_chip(self, "_fade_time", _set_global_fade_time)
	_global_cue_pre_wait_time = global_cue.add_chip(self, "_pre_wait", _set_global_pre_wait)
	global_cue.select_requested.connect(_clear_selections)
	
	store_function_button_group = _add_to_button_group(store_function_buttons.values())
	store_function_button_group.pressed.connect(_on_store_function_changed)
	
	save_mode_button_group = _add_to_button_group(save_mode_buttons.values())
	save_mode_button_group.pressed.connect(_on_save_mode_changed)
	
	(store_function_buttons.merge as Button).button_pressed = true
	(save_mode_buttons.modified_channels as Button).button_pressed = true
	
	shortcut_buttons.PreviousShortcutButton.set_button($VBoxContainer/Controls/HBoxContainer/Previous)
	shortcut_buttons.GoShortcutButton.set_button($VBoxContainer/Controls/HBoxContainer/Go)
	shortcut_buttons.NextShortcutButton.set_button($VBoxContainer/Controls/HBoxContainer/Next)
	shortcut_buttons.PlayShortcutButton.set_button($VBoxContainer/Controls/HBoxContainer/Play)
	shortcut_buttons.PauseShortcutButton.set_button($VBoxContainer/Controls/HBoxContainer/Pause)
	shortcut_buttons.StopShortcutButton.set_button($VBoxContainer/Controls/HBoxContainer/Stop)

	
	remove_child(settings_node)
	settings_node.show()
	reload()


## Adds all the passed buttons to a new ButtonGroup
func _add_to_button_group(buttons: Array) -> ButtonGroup:
	var new_group: ButtonGroup = ButtonGroup.new()
	
	for button: BaseButton in buttons:
		button.toggle_mode = true
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.button_group = new_group
	
	return new_group


func _set_global_pre_wait(pre_wait: float) -> void:
	if current_cue_list:
		_pre_wait = pre_wait
		for cue: Cue in current_cue_list.cues.values():
			cue.set_pre_wait(pre_wait)


func _set_global_fade_time(fade_time: float) -> void:
	if current_cue_list:
		_fade_time = fade_time
		for cue: Cue in current_cue_list.cues.values():
			cue.set_fade_time(fade_time)


func _set_current_selected_item(p_current_selected_item) -> void:
	current_selected_item = p_current_selected_item
	_current_selected_cue = current_cue_list.cues[cue_refs[current_selected_item]] if current_selected_item else null
	
	var state: bool = current_selected_item == null
	
	$VBoxContainer/PanelContainer/HBoxContainer/EditControls/HBoxContainer/Delete.disabled = state
	$VBoxContainer/PanelContainer/HBoxContainer/EditControls/HBoxContainer/MoveUp.disabled = state
	$VBoxContainer/PanelContainer/HBoxContainer/EditControls/HBoxContainer/MoveDown.disabled = state
	$VBoxContainer/Controls/HBoxContainer/Go.disabled = state


func _on_functions_added(arg1=null) -> void:
	if saved_cue_list_uuid:
		_find_cue_list()


func _on_functions_removed(functions: Array) -> void:
	for function in functions:
		if function == current_cue_list:
			set_cue_list(null)


func _on_selected_fixtures_changed(selected_fixtures: Array) -> void:
	$VBoxContainer/PanelContainer/HBoxContainer/Store.disabled = selected_fixtures == []
	$StoreConfirmationBox/VBoxContainer2/ActionText/NumOfFixtures.text = str(len(selected_fixtures))
	
	if _edit_mode:
		_highlight_cues_with_stored_fixtures(selected_fixtures)


## Reloads the list of cues
func reload() -> void:
	for old_item: Control in cue_list_container.get_children():
		cue_list_container.remove_child(old_item)
		old_item.queue_free()
	
	
	var old_selected_cue: Cue = _current_selected_cue
	
	_clear_selections()
	_reset_refs()

	if current_cue_list:
		var fade_times: Array = [0]
		var pre_wait_times: Array = [0]
		
		for cue_number: float in current_cue_list.index_list:
			var cue: Cue = current_cue_list.cues[cue_number]
			var new_list_item: ListItem = Interface.components.ListItem.instantiate()

			new_list_item.set_item_name(cue.name)
			new_list_item.set_name_changed_signal(cue.name_changed)
			new_list_item.set_id_tag(str(cue_number))
			
			fade_times.append(cue.fade_time)
			pre_wait_times.append(cue.pre_wait)
			
			if _edit_mode:
				new_list_item.set_name_method(cue.set_name)
				new_list_item.set_id_method(current_cue_list.set_cue_number.bind(cue))
				new_list_item.add_chip(cue, "fade_time", cue.set_fade_time, cue.fade_time_changed)
				new_list_item.add_chip(cue, "pre_wait", cue.set_pre_wait, cue.pre_wait_time_changed)
			
			_store_refs(cue_number, new_list_item)
			
			if cue == old_selected_cue:
				new_list_item.set_selected(true)
				last_selected_item = new_list_item
				current_selected_item = new_list_item
			
			if cue_number == current_cue_list.current_cue_number:
				_handle_cue_change(cue_number)
			
			if not cue.data_stored.is_connected(_reload_highlights_signal_callback): cue.data_stored.connect(_reload_highlights_signal_callback)
			if not cue.data_eraced.is_connected(_reload_highlights_signal_callback): cue.data_eraced.connect(_reload_highlights_signal_callback)
			
			new_list_item.select_requested.connect(func(arg1=null):
				_on_select_requested(new_list_item, cue_number))

			cue_list_container.add_child(new_list_item)
		
		_global_cue_fade_time.set_value_no_signal(Utils.get_most_common_value(fade_times))
		_global_cue_pre_wait_time.set_value_no_signal(Utils.get_most_common_value(pre_wait_times))
		global_cue.visible = _edit_mode
		
	_reload_labels()
	_reload_name()
	
	if _edit_mode:
		_highlight_cues_with_stored_fixtures(Values.get_selection_value("selected_fixtures", []))


func _clear_selections(arg1=null) -> void:
	last_selected_item = null
		
	if current_selected_item:
		current_selected_item.set_selected(false)
	
	current_selected_item = null

	$StoreConfirmationBox/VBoxContainer2/ActionText/CueNumber.text = "null"


func _reset_refs() -> void:
	object_refs = {}
	cue_refs = {}
	old_index = 0


func _store_refs(cue_number: float, new_list_item: ListItem) -> void:
	object_refs[cue_number] = new_list_item
	cue_refs[new_list_item] = cue_number


func _highlight_cues_with_stored_fixtures(fixtures: Array) -> void:
	for cue_number: float in object_refs.keys():
		var list_item: ListItem = object_refs[cue_number]
		var cue: Cue = current_cue_list.cues[cue_number]
		
		var new_color: Color = _cue_default_color
		
		for fixture: Fixture in fixtures:
			if fixture in cue.stored_data.keys():
				new_color = _cue_highlight_color
				break
		
		list_item.selected_color = new_color
		list_item.color = new_color


func _on_select_requested(new_list_item: ListItem, cue_number: float) -> void:
	if last_selected_item:
		last_selected_item.set_selected(false)

	new_list_item.set_selected(true)

	current_selected_item = new_list_item
	last_selected_item = new_list_item

	if Input.is_key_pressed(KEY_CTRL):
		current_cue_list.seek_to(cue_refs[current_selected_item])

	$StoreConfirmationBox/VBoxContainer2/ActionText/CueNumber.text = str(cue_number)


func set_cue_list(cue_list: CueList = null) -> void:
	if current_cue_list:
		_disconnect_signals()

	current_cue_list = cue_list

	if current_cue_list:
		_connect_signals()

	reload()


func _disconnect_signals() -> void:
	current_cue_list.name_changed.disconnect(_reload_name)
	current_cue_list.cues_added.disconnect(_reload_from_signal)
	current_cue_list.cues_removed.disconnect(_reload_from_signal)
	current_cue_list.cue_numbers_changed.disconnect(_reload_from_signal)
	current_cue_list.cue_changed.disconnect(_handle_cue_change)
	current_cue_list.played.disconnect(_reload_labels)
	current_cue_list.paused.disconnect(_reload_labels)


func _connect_signals() -> void:
	current_cue_list.name_changed.connect(_reload_name)
	current_cue_list.cues_added.connect(_reload_from_signal)
	current_cue_list.cues_removed.connect(_reload_from_signal)
	current_cue_list.cue_numbers_changed.connect(_reload_from_signal)	
	current_cue_list.cue_changed.connect(_handle_cue_change)
	current_cue_list.played.connect(_reload_labels)
	current_cue_list.paused.connect(_reload_labels)


func _reload_from_signal(arg1=null) -> void:
	reload()


func _find_cue_list() -> void:
	if saved_cue_list_uuid in Core.functions:
		var found_cue_list: CueList = Core.functions[saved_cue_list_uuid]
		if current_cue_list == null:
			set_cue_list(found_cue_list)


## Saves the settings to a dictionary
func save() -> Dictionary:
	
	var seralized_shortcuts: Dictionary = {}
	
	for shortcut_button_name: String in shortcut_buttons.keys():
		seralized_shortcuts[shortcut_button_name] = shortcut_buttons[shortcut_button_name].save()
	
	return {
		"cue_list": current_cue_list.uuid if current_cue_list else "",
		"seralized_shortcuts": seralized_shortcuts
	}


## Loads settings from what was returned by save()
func load(saved_data: Dictionary) -> void:
	saved_cue_list_uuid = saved_data.get("cue_list", "")
	
	var seralized_shortcuts: Variant = saved_data.get("seralized_shortcuts", null)
	
	if seralized_shortcuts is Dictionary:
		for shortcut_button_name: String in seralized_shortcuts.keys():
			if shortcut_button_name in shortcut_buttons and seralized_shortcuts[shortcut_button_name] is Dictionary:
				shortcut_buttons[shortcut_button_name].load(seralized_shortcuts[shortcut_button_name])


## Reloads the status labels
func _reload_labels() -> void:
	labels.cue_number.text = "0"
	labels.cue_number.hide()
	labels.cue_label.hide()
	labels.separator.hide()
	labels.playing.hide()
	labels.paused.hide()
	labels.stopped.hide()

	if current_cue_list:
		labels.cue_number.text = str(current_cue_list.current_cue_number)

		if current_cue_list.is_playing():
			labels.playing.show()

		if current_cue_list.current_cue_number == -1:
			labels.cue_number.hide()
			labels.cue_label.hide()
			labels.stopped.show()
		else:
			labels.paused.show()
			labels.cue_number.show()
			labels.cue_label.show()
			labels.separator.show()


func _reload_name(arg1=null) -> void:
	if current_cue_list:
		$VBoxContainer/PanelContainer/HBoxContainer/Label.text = current_cue_list.name
	else:
		$VBoxContainer/PanelContainer/HBoxContainer/Label.text = "Empty List"


## Called when the current cue is changed
func _handle_cue_change(number: float) -> void:
	if current_cue_list:
		if old_index:
			object_refs[old_index].set_highlighted(false)

		if number in object_refs:
			object_refs[number].set_highlighted(true)
			old_index = number
		
		_ensure_cue_visible(number)
		_reload_labels()


func _ensure_cue_visible(number: float) -> void:
	var index: int = object_refs.values().find(object_refs[number]) if number != -1 else 0
	var scroll_extra_index: int = clampi(index + _scroll_extra, 0, len(object_refs) - 1)
	
	if index < _scroll_extra:
		scroll_extra_index = index
	
	scroll_container.ensure_control_visible(object_refs.values()[scroll_extra_index])


func _on_change_cue_list_pressed() -> void:
	Interface.show_object_picker(func(key: Variant, value: Variant):
		if value is CueList:
			set_cue_list(value)
	, ["Functions"])


func _on_play_pressed() -> void:
	if current_cue_list:
		current_cue_list.play()


func _on_pause_pressed() -> void:
	if current_cue_list:
		current_cue_list.pause()


func _on_stop_pressed() -> void:
	if current_cue_list:
		current_cue_list.stop()


func _on_previous_pressed() -> void:
	if current_cue_list:
		current_cue_list.go_previous()


func _on_go_pressed() -> void:
	if current_selected_item:
		current_cue_list.seek_to(cue_refs[current_selected_item])


func _on_next_pressed() -> void:
	if current_cue_list:
		current_cue_list.go_next()


func _on_v_box_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_clear_selections()

#region Store Controls

## Called when the store button in the menue bar is clicked
func _on_store_pressed() -> void:
	if current_cue_list:
		$StoreConfirmationBox.show()

## Called when the cancel button is pressed in the store menu
func _on_cancel_pressed() -> void:
	$StoreConfirmationBox.hide()


## Called when the store button is pressed in the store menu
func _on_store_confirmation_pressed() -> void:
	if current_cue_list:
		var args_needs_cue_number: bool = false
		var save_mode: int = 0
		var store_function: String = ""
		var args: Array = []
		var current_cue_number: float = cue_refs[current_selected_item] if current_selected_item else -1
		
		match save_mode_button_group.get_pressed_button():
			save_mode_buttons.modified_channels:
				save_mode = Programmer.SAVE_MODE.MODIFIED
			
			save_mode_buttons.all_channels:
				save_mode = Programmer.SAVE_MODE.ALL
			
			save_mode_buttons.all_none_zero:
				save_mode = Programmer.SAVE_MODE.ALL_NONE_ZERO
		
		
		match store_function_button_group.get_pressed_button():
			store_function_buttons.merge:
				store_function = "merge_into_cue"
				args_needs_cue_number = true
				
			store_function_buttons.erace:
				store_function = "erace_from_cue"
				args_needs_cue_number = true
				
			store_function_buttons.new_cue:
				store_function = "save_to_new_cue"
		
		args = [
			Values.get_selection_value("selected_fixtures", []), 
			current_cue_list
		]
		
		if args_needs_cue_number:
			args += [current_cue_number]
		
		args += [
			save_mode
		]
		
		Client.send_command("programmer", store_function, args)


## Called when a store function button is pressed
func _on_store_function_changed(button: Button) -> void:
	pass


## Called when a save mode button is pressed
func _on_save_mode_changed(button: Button) -> void:
	pass


#region Cue Edit Controls

## Edit Controls
func _on_edit_mode_toggled(toggled_on: bool) -> void:
	_edit_mode = toggled_on
	reload()
	edit_controls.visible = toggled_on


func _on_delete_pressed() -> void:
	if current_selected_item:
		current_cue_list.cues[cue_refs[current_selected_item]].delete()


func _on_move_up_pressed() -> void:
	current_cue_list.move_cue_up(cue_refs[current_selected_item])


func _on_move_down_pressed() -> void:
	current_cue_list.move_cue_down(cue_refs[current_selected_item])

#endregion
