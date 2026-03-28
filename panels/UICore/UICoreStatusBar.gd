# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICoreStatusBar extends PanelContainer
## Core UI script for the main status bar


@export_group("Nodes")

## The VersionLabel
@export var _version_label: Label

## The UICoreResolveButtons node
@export var _resolve_button_container: UICoreResolveButtons


## Ready
func _ready() -> void:
	_version_label.set_text(Details.version)


## Called when the quick action button is toggled
func _on_action_button_toggled(toggled_on: bool) -> void:
	Interface.set_visible_and_fade(_resolve_button_container, toggled_on)
