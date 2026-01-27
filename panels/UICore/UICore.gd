# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICore extends UIPanel
## CoreUI panel for specturm UIV3


## The UICorePrimarySideBar side bar
@export var _side_bar: UICorePrimarySideBar

## The startup background container 
@export var _startup_bg: PanelContainer

## The Control to contain all StartUpNotices
@export var _notice_container: Control


## All current displayed starup notices. Refmap for StartUpNotice: StartUpNoticeContainer
var _notices: RefMap = RefMap.new()


## Init
func _init() -> void:
	super._init()
	
	_set_class_name("UICore")


## Ready
func _ready() -> void:
	_settings_manager.require("side_bar_settings", _side_bar.settings())
	
	_startup_bg.show()
	
	if get_parent() is UIWindow:
		set_menu_bar_visible(false)
	
	await get_tree().create_timer(0.5).timeout
	Interface.fade_property(_startup_bg, "modulate", Color.TRANSPARENT, _startup_bg.hide, 0.3)
	
	for notice: StartUpNotice in Interface.config().startup_notices:
		add_startup_notice(notice)


## Displays a StartUpNotice
func add_startup_notice(p_notice: StartUpNotice) -> void:
	if not is_instance_valid(p_notice) or _notices.has_left(p_notice) or Interface.config().can_show_notice(p_notice.get_notice_id()):
		return
	
	var notice_container: StartUpNoticeContainer = preload("res://panels/UICore/StartUpNoticeContainer.tscn").instantiate()
	
	notice_container.set_notice(p_notice)
	notice_container.closing.connect(func (): _notices.erase_left(p_notice))
	
	_notices.map(p_notice, notice_container)
	_notice_container.add_child(notice_container)


## Saves all the tabs
func serialize() -> Dictionary:
	return super.serialize().merged({
		"tabs": _side_bar.serialize(),
	})


## Loads all the tabs
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	var tabs: Dictionary = type_convert(p_serialized_data.get("tabs", {}), TYPE_DICTIONARY)
	_side_bar.deserialize(tabs)
