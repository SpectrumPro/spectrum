## Internal actions
static var internal_actions: Dictionary[String, Callable] = {
	"clear_programmer": Programmer.clear,
	"ui_cancel": Interface.hide_all_popup_panels,
	"command_palette": handle_command_pallete_action,
	"screenshot": Interface.take_screenshot,
}

## Config
static var config: Dictionary[String, Variant] = {
	"internal_actions": internal_actions
}


## Handles the open command palette action
static func handle_command_pallete_action() -> void:
	Interface.toggle_popup_visable(UICommandPalette, InputServer)
