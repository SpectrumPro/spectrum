# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CueItem extends PanelContainer
## A item to represent a cue


## Emitted when this CueItem clicked
signal clicked()

## Emitted when this CueItem is right clicked
signal right_clicked()

## Emitted when this CueItem double clicked
signal double_clicked()


## The status bar
@export var status_bar: ProgressBar

## The Label node for the cue's name
@export var name_label: Label

## The Label node for the cue's QID
@export var qid_label: Label

## The Label node for the cue's fade time
@export var fade_time_label: Label

## The Label node for the cue's pre wait time
@export var pre_wait_label: Label

## Icon for Cue.TriggerMode.MANUAL
@export var trigger_mode_manual: TextureRect

## Icon for Cue.TriggerMode.AFTER_LAST
@export var trigger_mode_after_last: TextureRect

## Icon for Cue.TriggerMode.WITH_LAST
@export var trigger_mode_with_last: TextureRect


## The cue
var _cue: Cue

## The current animating tween
var _current_tween: Tween

## Signals to connect to the Cue
var _cue_signals: SignalGroup = SignalGroup.new([], {
	"name_changed": set_cue_name,
	"qid_changed": set_qid,
	"fade_time_changed": set_fade_time,
	"pre_wait_time_changed": set_pre_wait,
	"trigger_mode_changed": set_trigger_mode
})


## Sets the cue represented by this CueItem
func set_cue(p_cue: Cue) -> void:
	_cue_signals.disconnect_object(_cue)
	_cue = p_cue
	_cue_signals.connect_object(_cue)
	
	if not is_instance_valid(_cue):
		return 
	
	set_cue_name(_cue.get_name())
	set_qid(_cue.get_qid())
	set_fade_time(_cue.get_fade_time())
	set_pre_wait(_cue.get_pre_wait())
	set_trigger_mode(_cue.get_trigger_mode())


## Pauses the tween for the status bar
func pause_status_bar() -> void:
	if is_instance_valid(_current_tween):
		_current_tween.pause()


## Plays the tween for the status bar
func play_status_bar() -> void:
	if is_instance_valid(_current_tween):
		_current_tween.play()


## Shows or hides the status bar
func set_status_bar(p_state: bool, p_time: float) -> void:
	if is_instance_valid(_current_tween):
		_current_tween.kill()
	
	if not is_inside_tree():
		return
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_method(status_bar.set_value_no_signal, status_bar.value, int(p_state), p_time)
	
	_current_tween = tween


## Functions for changing all the labels
func set_cue_name(p_name: String) -> void: 
	name_label.set_text(p_name)


## Sets the QID label
func set_qid(p_qid: String) -> void: 
	qid_label.set_text(p_qid)


## Sets the fade time label
func set_fade_time(p_fade_time: float) -> void: 
	fade_time_label.set_text(str(p_fade_time))


## Sets the pre wait label
func set_pre_wait(p_pre_wait: float) -> void: 
	pre_wait_label.set_text(str(p_pre_wait))


## Sets the trigger mode
func set_trigger_mode(p_trigger_mode: Cue.TriggerMode) -> void:
	trigger_mode_manual.hide()
	trigger_mode_after_last.hide()
	trigger_mode_with_last.hide()
	
	match p_trigger_mode:
		Cue.TriggerMode.MANUAL: 
			trigger_mode_manual.show()
		
		Cue.TriggerMode.AFTER_LAST: 
			trigger_mode_after_last.show()
		
		Cue.TriggerMode.WITH_LAST: 
			trigger_mode_with_last.show()


## Called when an input event is decected in the panel
func _on_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.is_pressed():
		p_event = p_event as InputEventMouseButton
		
		match p_event.button_index:
			MOUSE_BUTTON_LEFT:
				if p_event.is_double_click(): 
					double_clicked.emit()
				else:
					clicked.emit()
			
			MOUSE_BUTTON_RIGHT:
				right_clicked.emit()
