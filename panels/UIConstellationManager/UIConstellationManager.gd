# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIConstellationManager extends UIPanel
## UIConstellationManager to manage the Constelation Network System


## StatusLabel node for the network status
@export var status_label: Label

## Power Button for online status
@export var power_button: Button

## UIConstellationManagerNodesTab to display all nodes
@export var nodes_tab: UIConstellationManagerNodesTab

## UIConstellationManagerSessionsTab to display all sessions
@export var session_tab: UIConstellationManagerSessionsTab


## The Constellation network instance
var _constellation: Constellation

## SignalGroup for the Constellation instance
var _constellation_signals: SignalGroup = SignalGroup.new([], {
	"node_found": _add_node,
	"session_created": _add_session,
	"network_state_changed": _update_network_state
})
 
## Colors for each NetworkState
var _status_colors: Dictionary[NetworkHandler.NetworkState, Color] = {
	NetworkHandler.NetworkState.OFFLINE: 		ThemeManager.Colors.Statuses.Off,
	NetworkHandler.NetworkState.INITIALIZING:	ThemeManager.Colors.Statuses.Standby,
	NetworkHandler.NetworkState.BOUND: 			ThemeManager.Colors.Statuses.Standby,
	NetworkHandler.NetworkState.READY: 			ThemeManager.Colors.Statuses.Normal,
	NetworkHandler.NetworkState.SHUTTING_DOWN: 	ThemeManager.Colors.Statuses.Standby,
	NetworkHandler.NetworkState.ERROR: 			ThemeManager.Colors.Statuses.Error,
}


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIConstellationManager")


## Ready
func _ready() -> void:
	super._ready()
	
	_constellation = Network.get_active_handler_by_name("Constellation")
	_constellation_signals.connect_object(_constellation)
	
	_update_network_state(_constellation.get_network_state())
	
	for node: ConstellationNode in _constellation.get_known_nodes():
		if node == _constellation.get_local_node():
			continue
		
		_add_node(node)
	
	for session: ConstellationSession in _constellation.get_known_sessions():
		_add_session(session)


## Sets the NetworkState status label
func _update_network_state(p_network_state: NetworkHandler.NetworkState, p_errcode: Error = OK):
	status_label.text = NetworkHandler.NetworkState.keys()[p_network_state]
	status_label.modulate = ThemeManager.Colors.pastel(_status_colors[p_network_state])
	
	match p_network_state:
		NetworkHandler.NetworkState.OFFLINE:
			power_button.set_pressed_no_signal(false)
			
			nodes_tab.reset()
			session_tab.reset()
		
		_:
			power_button.set_pressed_no_signal(true)


## Called when a node is found
func _add_node(p_node: ConstellationNode) -> void:
	nodes_tab.add_node(p_node)


## Called when a session is created
func _add_session(p_session: ConstellationSession) -> void:
	session_tab.add_session(p_session)


## Called when the power button is pressed
func _on_power_button_toggled(p_toggled_on: bool) -> void:
	if p_toggled_on:
		_constellation.start_node()
	else: 
		_constellation.stop_node() 
