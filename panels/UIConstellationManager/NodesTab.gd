# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIConstellationManagerNodesTab extends PanelContainer
## UIConstellationManagerNodesTab


## The Table Node to show all Constellation Nods
@export var _table: Table


## Enum for each Columns
enum Columns {NAME, IP_ADDR, ROLE_FLAGS, CONNECTION_STATUS, SESSION}

## Config for each column
var _column_config: Dictionary[int, Dictionary] = {
	Columns.NAME: {"type": Data.Type.STRING},
	Columns.IP_ADDR: {"type": Data.Type.STRING},
	Columns.ROLE_FLAGS: {"type": Data.Type.BITFLAGS},
	Columns.CONNECTION_STATUS: {"type": Data.Type.ENUM},
	Columns.SESSION: {"type": Data.Type.OBJECT},
}

## The Constellation network instance
var _constellation: Constellation

## RefMap for ConstellationNode: Table.Row
var _node_rows: RefMap = RefMap.new()


## Ready
func _ready() -> void:
	_constellation = Network.get_active_handler_by_name("Constellation")
	
	for column_name: String in Columns:
		_table.add_column(column_name.capitalize(), _column_config[Columns[column_name]].type)


## Adds a ConstellationNode to the table
func add_node(p_node: ConstellationNode) -> void:
	_node_rows.map(p_node, _table.add_row({
		Columns.NAME: p_node.get_settings().get_entry("Name"),
		Columns.IP_ADDR:p_node.get_settings().get_entry("IpAddress"),
		Columns.ROLE_FLAGS: p_node.get_settings().get_entry("RoleFlags"),
		Columns.CONNECTION_STATUS: p_node.get_settings().get_entry("ConnectionState"),
		Columns.SESSION: p_node.get_settings().get_entry("Session"),
	}))


## Resets the UI, removing all nodes from the table
func reset() -> void:
	_node_rows.clear()
	_table.clear()


## Called when the Reload Button is pressed
func _on_reload_pressed() -> void:
	_constellation._send_discovery()
