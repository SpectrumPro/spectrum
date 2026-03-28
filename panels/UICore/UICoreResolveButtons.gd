# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICoreResolveButtons extends Control
## Resolve buttons for UICore

## TODO

#
### Min size for the buttons
#@export var button_min_size: Vector2 = Vector2(80, 40)
#
#@export_group("Nodes")
#
### The BoxContainer to contain all the buttons 
#@export var _button_container: BoxContainer 
#
#
### All the resolve buttons
#var _resolve_buttons: Dictionary[Interface.ResolveHint, Button]
#
### Blocklist of resolve hints
#var _resolve_hint_block_list: Array[Interface.ResolveHint] = [
	#Interface.ResolveHint.NONE
#]
#
#
### Ready
#func _ready() -> void:
	#for resolve_hint: Interface.ResolveHint in Interface.ResolveHint.values():
		#if _resolve_hint_block_list.has(resolve_hint):
			#continue
		#
		#var new_button: Button = Button.new()
		#var new_panel: Panel = Panel.new()
		#
		#new_button.custom_minimum_size = button_min_size
		#new_button.text = Interface.ResolveHint.keys()[resolve_hint].capitalize()
		#new_button.toggle_mode = true
		#new_button.toggled.connect(_on_resolve_buttons_toggled.bind(resolve_hint))
		#
		#new_panel.add_theme_stylebox_override("panel", ThemeManager.StyleBoxes.ResolveBoxBGLess)
		#new_panel.modulate = Interface.get_resolve_color(resolve_hint)
		#new_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		#new_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		#
		#new_button.add_child(new_panel)
		#_button_container.add_child(new_button)
		#_resolve_buttons[resolve_hint] = new_button
#
#
### Called when one of the resolve buttons is pressed
#func _on_resolve_buttons_toggled(p_toggled_on: bool, p_resolve_hint: Interface.ResolveHint) -> void:
	#if p_toggled_on:
		#var current_hint: Interface.ResolveHint = Interface.get_current_resolve_hint()
		#
		#if _resolve_buttons.has(current_hint):
			#_resolve_buttons[current_hint].set_pressed_no_signal(false)
		#
		#Interface.enter_resolve_mode(Interface.ResolveType.ANY, p_resolve_hint, "1")
	#else:
		#Interface.exit_resolve_mode()
