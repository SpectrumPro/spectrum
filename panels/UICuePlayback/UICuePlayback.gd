# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICuePlayback extends UIPanel
## Ui panel for playing back cuelists


## The VBoxContainer that hold all the cues
@export var cue_container: VBoxContainer

## The ScrollContainer that contains cue_container
@export var scroll_container: ScrollContainer

## The ComponentButton
@export var component_button: ComponentButton

## The FunctionPlaybackControls
@export var function_playback_controls: FunctionPlaybackControls

## The Go button
@export var go_button: Button

## All the buttons that need to be disabled / enabled when there is no cue list
@export var control_buttons: Array[Button]


## The cue list
var _cue_list: CueList

## Contains all the CueItems, keyed by the cue uuid
var _cues: RefMap = RefMap.new()

## The current active CueItem
var _active_cue: CueItem

## The current selected CueItem
var _selected_cue: CueItem

## Signals to connect to the CueList
var _signal_connections: SignalGroup = SignalGroup.new([], {
	"active_state_changed": _on_active_state_changed,
	"transport_state_changed": _on_transport_state_changed,
	"active_cue_changed": _set_active_cue,
	"cues_added": _add_cues,
	"cues_removed": _remove_cues,
	"cue_order_changed": _move_cue,
	"delete_requested": _on_delete_requested,
})


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UICuePlayback")


## Sets the cuelist to control
func set_cue_list(p_cue_list: CueList) -> void:
	_signal_connections.disconnect_object(_cue_list)
	_cue_list = p_cue_list
	
	function_playback_controls.set_function(_cue_list)
	_signal_connections.connect_object(_cue_list)
	
	var is_valid: bool = is_instance_valid(p_cue_list)
	set_button_array_enabled(control_buttons, not is_valid)
	
	_remove_cues(_cues.get_left())
	_set_selected_cue(null)
	_set_active_cue(null)
	
	if not is_valid:
		return
	
	_add_cues(_cue_list.get_cues())
	_set_active_cue(_cue_list.get_active_cue(), 0.0)


## Called when cues are added
func _add_cues(p_cues: Array) -> void:
	for cue: Cue in p_cues:
		if _cues.has_left(cue):
			continue
		
		var cue_item: CueItem = preload("uid://owx4rxrtg50d").instantiate()
		cue_item.set_cue(cue)
		
		cue_container.add_child(cue_item)
		cue_container.move_child(cue_item, _cue_list.get_cue_position(cue))
		
		cue_item.clicked.connect(_on_cue_item_clicked.bind(cue_item))
		cue_item.right_clicked.connect(_on_cue_item_right_clicked.bind(cue_item))
		cue_item.double_clicked.connect(_on_cue_item_double_clicked.bind(cue_item))
		
		_cues.map(cue, cue_item)


## Called when cues are removed
func _remove_cues(p_cues: Array) -> void:
	for cue: Cue in p_cues:
		if not _cues.has_left(cue):
			continue
		
		var cue_item: CueItem = _cues.left(cue)
		
		cue_item.queue_free()
		_cues.erase_left(cue)


## Called when the active cue is changed
func _set_active_cue(p_cue: Cue, p_speed_override: float = -1.0) -> void:
	if is_instance_valid(_active_cue):
		_active_cue.set_status_bar(false, 0.0)
	
	if not _cues.has_left(p_cue):
		_active_cue = null
		return
	
	_active_cue = _cues.left(p_cue)
	_active_cue.set_status_bar(true, p_cue.get_fade_time() if p_speed_override == -1.0 else p_speed_override)
	Interface.fade_property(scroll_container, "scroll_vertical", _active_cue.position.y - _active_cue.size.y, Callable(), ThemeManager.Constants.Times.InterfaceFadeFast)


## Sets the given cue selected
func _set_selected_cue(p_cue: Cue) -> void:
	if is_instance_valid(_selected_cue):
		_selected_cue.set_selected(false)
		go_button.set_disabled(true)
	
	if not _cues.has_left(p_cue):
		_selected_cue = null
		return
	
	_selected_cue = _cues.left(p_cue)
	_selected_cue.set_selected(true)
	
	go_button.set_disabled(false)


## Called when a cue is moved in the list
func _move_cue(p_cue: Cue, p_position: int) -> void:
	if not _cues.has_left(p_cue):
		return
	
	var cue_item: CueItem = _cues.left(p_cue)
	cue_container.move_child(cue_item, p_position)


## Called when the CueList's ActiveState is changed
func _on_active_state_changed(p_active_state: Function.ActiveState) -> void:
	match p_active_state:
		Function.ActiveState.DISABLED when is_instance_valid(_active_cue):
			_active_cue.set_status_bar(false, 0.0)


## Called when the CueList's TransportState is changed
func _on_transport_state_changed(p_transport_state: Function.TransportState) -> void:
	match p_transport_state:
		Function.TransportState.PAUSED when _active_cue:
			_active_cue.pause_status_bar()
		
		Function.TransportState.FORWARDS when _active_cue:
			_active_cue.play_status_bar()
		
		Function.TransportState.BACKWARDS when _active_cue:
			_active_cue.play_status_bar()


## Called when the cuelist is to be deleted
func _on_delete_requested() -> void:
	set_cue_list(null)


## Called when a CueItem is clicked
func _on_cue_item_clicked(p_cue_item: CueItem) -> void:
	_set_selected_cue(_cues.right(p_cue_item))


## Called when a CueItem is right clicked
func _on_cue_item_right_clicked(p_cue_item: CueItem) -> void:
	Interface.prompt_component_settings(self, _cues.right(p_cue_item))


## Called when a CueItem is double clicked
func _on_cue_item_double_clicked(p_cue_item: CueItem) -> void:
	_cue_list.seek_to(_cues.right(p_cue_item))


## Called when the Go Previous button is pressed
func _on_previous_pressed() -> void: 
	_cue_list.go_previous()


## Called when the Go Next button is pressed
func _on_next_pressed() -> void: 
	_cue_list.go_next()


## Called when the Go button is presse
func _on_go_to_pressed() -> void:
	_cue_list.seek_to(_cues.right(_selected_cue))


## Called when the Play / Pause button is pressed
func _on_play_pause_pressed() -> void: 
	_cue_list.toggle()


## Called when the Stop button is pressed
func _on_stop_pressed() -> void: 
	_cue_list.off()


## Saves this into a dict
func serialize() -> Dictionary:
	return super.serialize().merged({
		"cue_list": component_button.get_component_uuid()
	})


## Loads this from a dict
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	component_button.look_for(type_convert(p_serialized_data.get("cue_list", ""), TYPE_STRING))


## Called for each GUI input on the CueContainer
func _on_cue_container_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.is_pressed():
		p_event = p_event as InputEventMouseButton
		
		match p_event.get_button_index():
			MOUSE_BUTTON_LEFT:
				_set_selected_cue(null)
				pass
