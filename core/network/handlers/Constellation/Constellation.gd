# Copyright (c) 2025 Liam Sherwin, All rights reserved.
# This file is part of the Constellation Network Engine, licensed under the GPL v3.

class_name Constellation extends NetworkHandler
## NetworkHandler for the Constellation Network Engine


## Emited when the IP or interface name is changed
signal ip_and_interface_changed(ipaddr: IPAddr)


## The Multicast group
const MCAST_GROUP: String = "239.38.23.1"

## UDP bind port
const UDP_MCAST_PORT: int = 3823

## Time in seconds for discovery
const DISCO_TIMEOUT: int = 10

## Wait time in seconds before session discovery deems a given sessionID to no longer exist, and continue with auto create
const SESSION_DISCO_WAIT_TIME: int = 2

## Max time to wait in second for the next chunk of a multipart message to be recieved
const MULTI_PART_MAX_WAIT: int = 10

## MessageType
const MessageType: ConstaNetHeadder.Type = ConstaNetHeadder.Type

## NetworkRole
const RoleFlags: ConstaNetHeadder.RoleFlags = ConstaNetHeadder.RoleFlags

## ConstaNetGoodbye reason for going offline
const GOODBYE_REASON_GOING_OFFLINE: String = "Node Going Offline"


## The primary TCP server to use
var _tcp_socket: TCPServer = TCPServer.new()

## The primary UDP server to use
var _udp_socket: PacketPeerUDP = PacketPeerUDP.new()

## The current TCP port
var _tcp_port: int = 0

## The current UDP port
var _udp_port: int = 0

## PacketPeerUDP to transmit to multicast
var _mcast_tx: PacketPeerUDP = PacketPeerUDP.new()

## PacketPeerUDP to recive from multicast
var _mcast_rx: PacketPeerUDP = PacketPeerUDP.new()

## Array containing each connected StreamPeerTCP
var _connected_tcp_peers: Array[StreamPeerTCP]

## Stores RX data buffers for each connected StreamPeerTCP
var _tcp_buffers: Dictionary[StreamPeerTCP, PackedByteArray]

## Network Role
var _role_flags: int = RoleFlags.EXECUTOR

## The ConstellationNode for the local node
var _local_node: ConstellationNode

## All known network session
var _known_sessions: Dictionary[String, ConstellationSession]

## All Unknown sessions
var _unknown_sessions: Dictionary[String, ConstellationSession]

## Timer for node discovery
var _disco_timer: Timer = Timer.new()

## Timer for session auto create
var _session_timer: Timer = Timer.new()

## Stores all known devices by thier NodeID
var _known_nodes: Dictionary[String, ConstellationNode] = {}

## Stores all unknown nodes yet to be found on the network
var _unknown_nodes: Dictionary[String, ConstellationNode]

## Stores all multi part messages being recieved
var _active_multi_parts: Dictionary[String, IncommingMultiPart]


## Init
func _init() -> void:
	ConstellationNode._network = self
	ConstellationSession._network = self
	
	set_process(false)
	ConstellationConfig.load_config("res://ConstellaitionConfig.gd")
	ConstellationConfig.load_user_config()
	
	_local_node = ConstellationNode.create_local_node()
	_local_node._set_node_ip(ConstellationConfig.bind_address)
	_local_node._set_node_name(ConstellationConfig.node_name)
	_local_node._set_node_id(ConstellationConfig.node_id)
	
	_local_node.node_name_changed.connect(_on_local_node_name_changed)
	_local_node.session_changed.connect(_on_local_node_session_changed)
	
	_disco_timer.set_autostart(false)
	_disco_timer.set_one_shot(false)
	_disco_timer.set_wait_time(DISCO_TIMEOUT)
	_disco_timer.timeout.connect(_on_disco_timeout)
	
	_session_timer.set_autostart(false)
	_session_timer.set_one_shot(true)
	_session_timer.set_wait_time(SESSION_DISCO_WAIT_TIME)
	_session_timer.timeout.connect(_on_session_timer_timeout)
	
	add_child(_local_node)
	add_child(_disco_timer)
	add_child(_session_timer)
	
	_handler_name = "Constellation"
	settings_manager.register_setting("Session", Data.Type.NETWORKSESSION, _local_node.set_session, _local_node.get_session, [_local_node.session_changed]).set_class_filter(ConstellationSession)
	
	var cli_args: PackedStringArray = OS.get_cmdline_args()
	if cli_args.has("--ctl-node-name"):
		_local_node._set_node_name(str(cli_args[cli_args.find("--ctl-node-name") + 1]))
	
	if cli_args.has("--ctl-address"):
		ConstellationConfig.bind_address = str(cli_args[cli_args.find("--ctl-address") + 1])
	
	if cli_args.has("--ctl-interface"):
		ConstellationConfig.bind_interface = str(cli_args[cli_args.find("--ctl-interface") + 1])
	
	if cli_args.has("--ctl-controler"):
		_role_flags = RoleFlags.CONTROLLER
		_local_node._set_role_flags(_role_flags)
	
	if cli_args.has("--ctl-executor"):
		_role_flags = RoleFlags.EXECUTOR
		_local_node._set_role_flags(_role_flags)
	
	if cli_args.has("--ctl-random-id"):
		_local_node._set_node_id(UUID_Util.v4())
	
	(func ():
		node_found.emit(_local_node)
	).call_deferred()


## Polls the socket
func _process(delta: float) -> void:
	while _udp_socket.get_available_packet_count() > 0:
		_handle_packet(_udp_socket.get_packet())
	
	while _mcast_rx.get_available_packet_count() > 0:
		_handle_packet(_mcast_rx.get_packet())
	
	while _tcp_socket.is_connection_available():
		_handle_incoming_tcp_connection()
	
	for peer: StreamPeerTCP in _connected_tcp_peers.duplicate():
		_process_stream_peer(peer)
	
	for multi_part: IncommingMultiPart in _active_multi_parts.values():
		_process_multi_part(multi_part)


## Handles notification
func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_WM_CLOSE_REQUEST:
		ConstellationConfig.save_user_config()


## Starts the node
func start_node() -> Error:
	if _network_state != NetworkState.OFFLINE:
		return ERR_ALREADY_EXISTS
	
	_log("Starting Node")
	stop_node(true)
	_set_network_state(NetworkState.INITIALIZING)
	
	_known_nodes[get_node_id()] = _local_node
	_local_node._set_node_ip(ConstellationConfig.bind_address)
	_bind_network()
	
	if _network_state != NetworkState.BOUND:
		_log("Error staring network")
		return FAILED
	
	_set_network_state(NetworkState.READY)
	_begin_discovery()
	
	return OK


## Stops the node
func stop_node(p_internal_only: bool = false) -> Error:
	if not p_internal_only:
		_log("Stopping Down")
		_send_goodbye(GOODBYE_REASON_GOING_OFFLINE)
	
	_set_network_state(NetworkState.SHUTTING_DOWN)
	_close_network()
	
	for node: ConstellationNode in _known_nodes.values():
		node.close()
	
	for session: ConstellationSession in _known_sessions.values():
		session.close()
	
	_local_node._set_session_no_join(null)
	
	_known_nodes.clear()
	_known_sessions.clear()
	_unknown_nodes.clear()
	_unknown_sessions.clear()
	
	_disco_timer.stop()
	_session_timer.stop()
	
	_set_network_state(NetworkState.OFFLINE)
	return OK


## Sends a command to the session, using p_node_filter as the NodeFilter
func send_command(p_command: Variant, p_node_filter: NetworkSession.NodeFilter = NetworkSession.NodeFilter.MASTER, p_nodes: Array[NetworkNode] = []) -> Error:
	if not _local_node.get_session():
		return ERR_UNAVAILABLE
	
	return _local_node.get_session().send_command(p_command, p_node_filter, p_nodes)


## Creates and joins a new session
func create_session(p_name: String) -> NetworkSession:
	if not p_name or _network_state != NetworkState.READY:
		return null
	
	var session: ConstellationSession = ConstellationSession.new()
	
	session._set_name(p_name)
	session._set_session_master(_local_node)
	session._add_node(_local_node)
	
	_known_sessions[session.get_session_id()] = session
	session.request_delete.connect(_on_session_delete_request.bind(session), CONNECT_ONE_SHOT)
	session_created.emit(session)
	
	_send_session_anouncement(session)
	return session


## Joins a pre-existing session on the network
func join_session(p_session: NetworkSession) -> bool:
	if not p_session or p_session == _local_node.get_session():
		leave_session()
		return false
	
	if _local_node.get_session():
		leave_session()
	
	for node: ConstellationNode in p_session.get_nodes():
		node.connect_tcp()
	
	var message: ConstaNetSessionJoin = ConstaNetSessionJoin.new()
	
	message.origin_id = get_node_id()
	message.session_id = p_session.get_session_id()
	message.set_request(true)
	
	_local_node._set_session(p_session)
	_send_message_mcast(message)
	
	return true


## Leaves a session 
func leave_session() -> bool:
	if not _local_node.get_session():
		return false
	
	var message: ConstaNetSessionLeave = ConstaNetSessionLeave.new()
	var session: ConstellationSession = _local_node.get_session()
	_local_node._leave_session()
	
	message.origin_id = get_node_id()
	message.session_id = session.get_session_id()
	message.set_request(true)
	
	_send_message_mcast(message)
	
	for node: ConstellationNode in session.get_nodes():
		node.disconnect_tcp()
	
	return true


## Sets the IP and interface name from an IPAddr object
func set_ip_and_interface(p_ipaddr: IPAddr) -> void:
	if not p_ipaddr.is_valid():
		return
	
	ConstellationConfig.bind_address = p_ipaddr.get_address()
	ConstellationConfig.bind_interface = p_ipaddr.get_interface()
	
	ip_and_interface_changed.emit(get_ip_and_interface())
	ConstellationConfig.save_user_config()


## Returns the IP and interface name as a IPAddr object
func get_ip_and_interface() -> IPAddr:
	return IPAddr.new(IP.Type.TYPE_ANY, ConstellationConfig.bind_address, ConstellationConfig.bind_interface)


## Returns a list of all known nodes
func get_known_nodes() -> Array[NetworkNode]:
	var return_value: Array[NetworkNode]
	return_value.assign(_known_nodes.values())
	
	return return_value


## Returns all unknown NetworkNodes
func get_unknown_nodes() -> Array[NetworkNode]:
	var return_value: Array[NetworkNode]
	return_value.assign(_unknown_nodes.values())
	
	return return_value


## Returns all known NetworkSessions
func get_known_sessions() -> Array[NetworkSession]:
	var return_value: Array[NetworkSession]
	return_value.assign(_known_sessions.values())
	
	return return_value


## Returns all unknown NetworkSessions
func get_unknown_sessions() -> Array[NetworkSession]:
	var return_value: Array[NetworkSession]
	return_value.assign(_unknown_sessions.values())
	
	return return_value


## Gets the local node
func get_local_node() -> ConstellationNode:
	return _local_node


## Returns the name of the local node
func get_node_name() -> String:
	return _local_node.get_node_name()


## Gets this nodes NodeID
func get_node_id() -> String:
	return _local_node.get_node_id()


## Returns the a session from the Id, or NULL
func get_session_from_id(p_session_id: String, p_create_unknown: bool = false) -> ConstellationSession:
	if _known_sessions.has(p_session_id):
		return _known_sessions[p_session_id]
	
	elif p_create_unknown:
		if _unknown_sessions.has(p_session_id):
			return _unknown_sessions[p_session_id]
		
		var session: ConstellationSession = ConstellationSession.create_unknown_session(p_session_id)
		
		_unknown_sessions[p_session_id] = session
		
		return session
	
	return _known_sessions.get(p_session_id)


## Gets a Node from its NodeID
func get_node_from_id(p_node_id: String, p_create_unknown: bool = false) -> ConstellationNode:
	if _known_nodes.has(p_node_id):
		return _known_nodes[p_node_id]
	
	elif p_create_unknown:
		if _unknown_nodes.has(p_node_id):
			return _unknown_nodes[p_node_id]
		
		var unknown_node: ConstellationNode = ConstellationNode.create_unknown_node(p_node_id)
		
		_unknown_nodes[p_node_id] = unknown_node
		_log("Creating unknown node: ", unknown_node.get_node_id())
		
		return unknown_node
	
	return null


## Gets all the nodes as an Array of ConstellationNode
func get_node_array(p_from: ConstaNetSessionAnnounce, p_create_unknown: bool = false) -> Array[ConstellationNode]:
	var typed_array: Array[ConstellationNode]
	
	for node_id: String in p_from.nodes:
		var node: ConstellationNode = get_node_from_id(node_id, p_create_unknown)
		
		if node not in typed_array:
			typed_array.append(node)
	
	return typed_array


## Sets the network state
func _set_network_state(p_network_state: NetworkState) -> bool:
	if p_network_state == _network_state:
		return false
	
	_network_state = p_network_state
	network_state_changed.emit(_network_state, _network_state_err_code if _network_state == NetworkState.ERROR else OK)
	
	return true


## Gets the custom log prefix with node name
func _get_log_prefix() -> String:
	return str(ConstellationConfig.log_prefix, " (", _local_node.get_node_name(), "): ")


## Logs to the console
func _log(...args) -> void:
	if ConstellationConfig.custom_loging_method.is_valid():
		ConstellationConfig.custom_loging_method.callv([_get_log_prefix()] + args)
	
	else:
		print(_get_log_prefix(), "".join(args))


## Logs to the console verbose
func _logv(...args) -> void:
	if ConstellationConfig.custom_loging_method_verbose.is_valid():
		ConstellationConfig.custom_loging_method_verbose.callv([_get_log_prefix()] + args)
	
	else:
		print_verbose(_get_log_prefix(), "".join(args))


## Starts this node, opens network connection
func _bind_network() -> void:
	_mcast_tx.set_reuse_address_enabled(true)
	_mcast_rx.set_reuse_address_enabled(true)
	_mcast_tx.set_reuse_port_enabled(true)
	_mcast_rx.set_reuse_port_enabled(true)
	
	var rx_address: String = ConstellationConfig.bind_address if OS.has_feature("windows") else MCAST_GROUP
	
	var tx_bind_error: Error = _mcast_tx.bind(UDP_MCAST_PORT, ConstellationConfig.bind_address)
	var rx_bind_error: Error = _mcast_rx.bind(UDP_MCAST_PORT, rx_address)
	
	var tx_config_error: Error = _mcast_tx.set_dest_address(MCAST_GROUP, UDP_MCAST_PORT)
	var rx_config_error: Error = _mcast_rx.join_multicast_group(MCAST_GROUP, ConstellationConfig.bind_interface)
	
	var tcp_error: Error = _tcp_socket.listen(0)
	var udp_error: Error = _udp_socket.bind(0)
	
	if tx_bind_error or rx_bind_error or tx_config_error or rx_config_error or tcp_error or udp_error:
		_log("TX Bind Error: ", error_string(tx_bind_error))
		_log("RX Bind Error: ", error_string(rx_bind_error))
		
		_log("TX Config Error: ", error_string(tx_config_error))
		_log("RX Config Error: ", error_string(rx_config_error))
		
		_log("TCP Bind Error: ", error_string(tcp_error))
		_log("UDP Bind Error: ", error_string(udp_error))
		
		_network_state_err_code = ERR_ALREADY_IN_USE
		_set_network_state(NetworkState.ERROR)
	else:
		_tcp_port = _tcp_socket.get_local_port()
		_udp_port = _udp_socket.get_local_port()
		
		_log("TCP bound on port: ", _tcp_port)
		_log("UDP bound on port: ", _udp_port)
		
		_set_network_state(NetworkState.BOUND)
		set_process(true)


## Closes network sockets
func _close_network() -> void:
	_mcast_tx.close()
	_mcast_rx.close()
	
	_tcp_socket.stop()
	_udp_socket.close()
	
	set_process(false)


## Starts the discovery stage
func _begin_discovery() -> void:
	_disco_timer.start()
	
	if ConstellationConfig.auto_create_session and not ConstellationConfig.session_id:
		_auto_create_session()
	
	elif ConstellationConfig.auto_create_session:
		_session_timer.start()
	
	_send_discovery(ConstaNetHeadder.Flags.REQUEST)
	_send_session_discovery(ConstaNetHeadder.Flags.REQUEST)


## Auto creates a session
func _auto_create_session() -> void:
	create_session(_local_node.get_node_name() + "'s Session")


## Creates a discovery message
func _create_discovery(p_flags: int = 0, p_target_id: String = "") -> ConstaNetDiscovery:
	var message: ConstaNetDiscovery = ConstaNetDiscovery.new()
	
	message.origin_id = get_node_id()
	message.target_id = p_target_id
	message.node_name = get_node_name()
	message.node_ip = ConstellationConfig.bind_address
	message.role_flags = _role_flags
	message.tcp_port = _tcp_port
	message.udp_port = _udp_port
	message.flags |= p_flags
	
	return message


## Sends a message to UDP Broadcast
func _send_message_mcast(p_message: ConstaNetHeadder) -> Error:
	if _network_state == NetworkState.OFFLINE:
		return ERR_UNAVAILABLE
	
	var tx_error: Error = _mcast_tx.put_packet(p_message.get_as_packet())
	
	_logv("Sending MCAST message: ", error_string(tx_error))
	return tx_error


## Sends a discovery message to broadcasr
func _send_discovery(p_flags: int = ConstaNetHeadder.Flags.ACKNOWLEDGMENT) -> Error:
	var message: ConstaNetDiscovery = _create_discovery(p_flags)
	
	if _network_state == NetworkState.READY:
		_disco_timer.start(DISCO_TIMEOUT)
	
	return _send_message_mcast(message)


## Sends a session discovery message to broadcast
func _send_session_discovery(p_flags: int = ConstaNetHeadder.Flags.REQUEST) -> Error:
	var message: ConstaNetSessionDiscovery = ConstaNetSessionDiscovery.new()
	
	message.origin_id = get_node_id()
	message.flags = p_flags
	
	return _send_message_mcast(message)


## Sends a sessions anouncement message
func _send_session_anouncement(p_session: ConstellationSession, p_flags: int = ConstaNetHeadder.Flags.ANNOUNCEMENT) -> Error:
	var message: ConstaNetSessionAnnounce = ConstaNetSessionAnnounce.new()
	
	message.origin_id = get_node_id()
	message.session_master = get_node_id()
	message.session_id = p_session.get_session_id()
	message.session_name = p_session.get_session_name()
	message.nodes = [get_node_id()]
	message.flags = p_flags
	
	return _send_message_mcast(message)


## Sends a goodbye message
func _send_goodbye(p_reason: String, p_flags: int = ConstaNetHeadder.Flags.ANNOUNCEMENT) -> Error:
	var message: ConstaNetGoodbye = ConstaNetGoodbye.new()
	
	message.origin_id = get_node_id()
	message.flags = p_flags
	message.reason = p_reason
	
	return _send_message_mcast(message)


## Handles a frame pulled from a network stream
func _handle_packet_frame(p_peer: StreamPeerTCP) -> void:
	_tcp_buffers.get_or_add(p_peer, PackedByteArray()).append_array(p_peer.get_data(p_peer.get_available_bytes())[1])
	var packet: PackedByteArray = _tcp_buffers[p_peer]
	
	while ConstaNetHeadder.is_packet_valid(packet):
		var length: int = ConstaNetHeadder.ba_to_int(packet, 1, 8)
		
		if length <= 0 or packet.size() < length:
			break
		
		var sliced_packet: PackedByteArray = packet.slice(0, length)
		_handle_packet(sliced_packet, p_peer)
		packet = packet.slice(length)
	
	if not ConstaNetHeadder.is_packet_valid(packet):
		_tcp_buffers[p_peer].clear() 


## Handles a packet as a PackedByteArray
func _handle_packet(p_packet: PackedByteArray, p_source: StreamPeerTCP = null) -> void:
	var message: ConstaNetHeadder = ConstaNetHeadder.phrase_packet(p_packet)
	
	if message.is_valid() and message.origin_id != _local_node.get_node_id():
		_handle_message(message, p_source)


## Handles an incomming message, 
func _handle_message(p_message: ConstaNetHeadder, p_source: StreamPeerTCP = null) -> void:
	if p_message.target_id and p_message.target_id != get_node_id():
		return
	
	match p_message.type:
		MessageType.DISCOVERY:
			_handle_discovery_message(p_message, p_source)
		
		MessageType.SESSION_DISCOVERY:
			_handle_session_discovery(p_message)
		
		MessageType.SESSION_ANNOUNCE:
			_handle_session_announce_message(p_message)
		
		MessageType.SESSION_SET_PRIORITY:
			_handle_session_set_priority(p_message)
		
		MessageType.SESSION_SET_ATTRIBUTE:
			_handle_session_set_attribute(p_message)
		
		MessageType.MULTI_PART:
			_handle_multi_part(p_message)
	
	if p_message.target_id == get_node_id():
		_local_node._handle_message(p_message)
	
	elif not p_message.target_id and p_message.origin_id in _known_nodes:
		_known_nodes[p_message.origin_id]._handle_message(p_message)


## Handles a discovery message
func _handle_discovery_message(p_discovery: ConstaNetDiscovery, p_source: StreamPeerTCP = null) -> void:
	if p_discovery.origin_id not in _known_nodes:
		var node: ConstellationNode
		
		if p_discovery.origin_id in _unknown_nodes:
			node = _unknown_nodes[p_discovery.origin_id]
			node._mark_as_unknown(false)
			node._update_from_discovery(p_discovery)
			
			_unknown_nodes.erase(p_discovery.origin_id)
			_log("Using unknown node: ", node.get_node_id())
		
		else:
			node = ConstellationNode.create_from_discovery(p_discovery)
		
		_known_nodes[p_discovery.origin_id] = node
		add_child(node)
		node_found.emit(node)
	
	if is_instance_valid(p_source):
		if p_discovery.is_request():
			var origin_node: ConstellationNode = get_node_from_id(p_discovery.origin_id)
			
			if is_instance_valid(origin_node):
				origin_node._use_stream(p_source)
				origin_node._send_tcp_discovery_acknowledment()
				origin_node._set_connection_status(NetworkNode.ConnectionState.CONNECTED)
		
		elif p_discovery.is_acknowledgment():
			_local_node._set_connection_status(NetworkNode.ConnectionState.CONNECTED)
	
	elif p_discovery.is_request():
		_send_discovery(ConstaNetHeadder.Flags.ACKNOWLEDGMENT)


## Handles a ConstaNetSessionDiscovery
func _handle_session_discovery(p_session_discovery: ConstaNetSessionDiscovery) -> void:
	for p_session: ConstellationSession in _known_sessions.values():
		if p_session.get_session_master() == _local_node:
			_send_session_anouncement(p_session, ConstaNetHeadder.Flags.ACKNOWLEDGMENT)


## Handles a session announce message
func _handle_session_announce_message(p_message: ConstaNetSessionAnnounce) -> void:
	if _known_sessions.has(p_message.session_id):
		_known_sessions[p_message.session_id]._update_with(p_message)
		return
	
	var session: ConstellationSession
	
	if _unknown_sessions.has(p_message.session_id):
		session = _unknown_sessions[p_message.session_id]
		session._mark_as_unknown(false)
		session.update_with(p_message)
		
		_unknown_sessions.erase(p_message.session_id)
		_log("Using unknown session: ", session.get_session_id())
	
	else:
		session = ConstellationSession.create_from_session_announce(p_message)
	
	_known_sessions[session.get_session_id()] = session
	session.request_delete.connect(_on_session_delete_request.bind(session), CONNECT_ONE_SHOT)
	
	session_created.emit(session)
	
	if ConstellationConfig.session_auto_rejoin and not _local_node.get_session() and ConstellationConfig.session_id == session.get_session_id():
		join_session(session)


## Handles a ConstaNetSessionSetPriority
func _handle_session_set_priority(p_session_set_priority: ConstaNetSessionSetPriority) -> void:
	var node: ConstellationNode = get_node_from_id(p_session_set_priority.node_id)
	var session: ConstellationSession = get_session_from_id(p_session_set_priority.session_id)
	
	if is_instance_valid(node) and is_instance_valid(session):
		session._set_priority_order(node, p_session_set_priority.position)


## Handles a ConstaNetSessionSetMaster
func _handle_session_set_attribute(p_session_set_attribute: ConstaNetSessionSetAttribute) -> void:
	var session: ConstellationSession = get_session_from_id(p_session_set_attribute.session_id)
	
	if not is_instance_valid(session):
		return
	
	match p_session_set_attribute.attribute:
		ConstaNetSessionSetAttribute.Attribute.NAME:
			session._set_session_name(p_session_set_attribute.value)
		
		ConstaNetSessionSetAttribute.Attribute.MASTER:
			session._set_session_master(get_node_from_id(p_session_set_attribute.value))


## Handles ConstaNetMultiPart
func _handle_multi_part(p_multi_part: ConstaNetMultiPart) -> void:
	if _active_multi_parts.has(p_multi_part.multi_part_id):
		_active_multi_parts[p_multi_part.multi_part_id].store_multi_part(p_multi_part)
		
	else:
		_active_multi_parts[p_multi_part.multi_part_id] = IncommingMultiPart.new(p_multi_part)


## Handles an incoming TCP connection
func _handle_incoming_tcp_connection() -> bool:
	var peer: StreamPeerTCP = _tcp_socket.take_connection()
	
	if not is_instance_valid(peer):
		return false
	
	_connected_tcp_peers.append(peer)
	_tcp_buffers[peer] = PackedByteArray()
	
	_logv("Accepted new TCP Peer from: ", peer.get_connected_host(), ":", peer.get_connected_port())
	return true


## Processes a StreamPeerTCP for data
func _process_stream_peer(p_peer: StreamPeerTCP) -> void:
	p_peer.poll()
		
	if p_peer.get_status() != StreamPeerTCP.Status.STATUS_CONNECTED:
		_logv("Disconnecting TCP Peer from: ", p_peer.get_connected_host(), ":", p_peer.get_connected_port())
		_connected_tcp_peers.erase(p_peer)
		_tcp_buffers.erase(p_peer)
	
	else:
		while p_peer.get_available_bytes() > 0:
			_handle_packet_frame(p_peer)


## Processes a IncommingMultiPart
func _process_multi_part(p_multi_part: IncommingMultiPart) -> void:
	if p_multi_part.is_complete():
		_handle_packet(p_multi_part.get_data())
		_active_multi_parts.erase(p_multi_part.id)
		p_multi_part.free()
	
	elif Time.get_unix_time_from_system() - p_multi_part.last_seen > MULTI_PART_MAX_WAIT:
		_logv("Dropping multipart ", p_multi_part.id, " due to timeout")
		_active_multi_parts.erase(p_multi_part.id)
		p_multi_part.free()


## Called when the node name is changed on the LocalNode
func _on_local_node_name_changed(p_name: String) -> void:
	ConstellationConfig.node_name = p_name
	ConstellationConfig.save_user_config()


## Called when the session of the local node changes
func _on_local_node_session_changed(p_session: ConstellationSession) -> void:
	if _network_state != NetworkState.READY:
		return
	
	ConstellationConfig.session_id = p_session.get_session_id() if p_session else ""
	ConstellationConfig.save_user_config()


## Called when the discovery timer times out
func _on_disco_timeout() -> void:
	_send_discovery()


## Called when the session timer times out
func _on_session_timer_timeout() -> void:
	if not ConstellationConfig.auto_create_session or _local_node.get_session():
		return
	
	_auto_create_session()


## Called when the sessions is to be deleted after all nodes disconnect
func _on_session_delete_request(p_session: ConstellationSession) -> void:
	_known_sessions.erase(p_session.get_session_id())


## ConstellationConfig object
class ConstellationConfig extends Object:
	## Defines a custom callable to call when logging infomation
	static var custom_loging_method: Callable = Callable()
	
	## Defines a custom callable to call when logging infomation verbosely
	static var custom_loging_method_verbose: Callable = Callable()
	
	## A String prefix to print before all message logs
	static var log_prefix: String = ""
	
	## Default address to bind to. Due to the use of multicast, binding to loopback does not work, it is here as a default for all platforms
	static var bind_address: String = "127.0.0.1"
	
	## Default port to bind to. Due to the use of multicast, binding to loopback does not work, it is here as a default for all platforms
	static var bind_interface: String = "lo"
	
	## File location for a user config override
	static var user_config_file_location: String = "user://"
	
	## File name for the user config file
	static var user_config_file_name: String = "constellation.conf"
	
	## NodeID for the local node
	static var node_id: String = UUID_Util.v4()
	
	## Node name for the local node
	static var node_name: String = "ConstellationNode"
	
	## The SessionID of the session the local node was last in
	static var session_id: String = ""
	
	## Auto rejoins the last session if it still exists on the network
	static var session_auto_rejoin: bool = true
	
	## True if this node should auto create a session once online, asuming previous session is is null and the node is not already in a session
	static var auto_create_session: bool = true
	
	## The ConfigFile object to access the user config file 
	static var _config_access: ConfigFile
	
	
	## Loads config from a file
	static func load_config(p_path: String) -> bool:
		var script: Variant = load(p_path)
		
		if script is not GDScript or script.get("config") is not Dictionary:
			return false
		
		var config: Dictionary = script.get("config")
		
		custom_loging_method = type_convert(config.get("custom_loging_method", custom_loging_method), TYPE_CALLABLE)
		custom_loging_method_verbose = type_convert(config.get("custom_loging_method_verbose", custom_loging_method_verbose), TYPE_CALLABLE)
		log_prefix = type_convert(config.get("log_prefix", log_prefix), TYPE_STRING)
		
		bind_address = type_convert(config.get("bind_address", bind_address), TYPE_STRING)
		bind_interface = type_convert(config.get("bind_interface", bind_address), TYPE_STRING)
		
		user_config_file_location = type_convert(config.get("user_config_file_location", user_config_file_location), TYPE_STRING)
		user_config_file_name = type_convert(config.get("user_config_file_name", user_config_file_name), TYPE_STRING)
		
		node_id = type_convert(config.get("node_id", node_id), TYPE_STRING)
		node_name = type_convert(config.get("node_name", node_name), TYPE_STRING)
		
		session_id = type_convert(config.get("session_id", session_id), TYPE_STRING)
		session_auto_rejoin = type_convert(config.get("session_auto_rejoin", session_auto_rejoin), TYPE_BOOL)
		auto_create_session = type_convert(config.get("auto_create_session", auto_create_session), TYPE_BOOL)
		
		DirAccess.make_dir_recursive_absolute(user_config_file_location)
		_config_access = ConfigFile.new()
		
		return true
	
	
	## Loads (or creates if not already) the user config override
	static func load_user_config() -> Error:
		_config_access.load(get_user_config_path())
		
		bind_address = type_convert(_config_access.get_value("Network", "bind_address", bind_address), TYPE_STRING)
		bind_interface = type_convert(_config_access.get_value("Network", "bind_interface", bind_interface), TYPE_STRING)
		
		node_id = type_convert(_config_access.get_value("LocalNode", "node_id", node_id), TYPE_STRING)
		node_name = type_convert(_config_access.get_value("LocalNode", "node_name", node_name), TYPE_STRING)
		
		session_id = type_convert(_config_access.get_value("Session", "session_id", session_id), TYPE_STRING)
		session_auto_rejoin = type_convert(_config_access.get_value("Session", "session_auto_rejoin", session_auto_rejoin), TYPE_BOOL)
		auto_create_session = type_convert(_config_access.get_value("Session", "auto_create_session", auto_create_session), TYPE_BOOL)
		
		save_user_config()
		return OK
	
	
	## Saves the user config to a file
	static func save_user_config() -> Error:
		_config_access.set_value("Network", "bind_address", bind_address)
		_config_access.set_value("Network", "bind_interface", bind_interface)
		
		_config_access.set_value("LocalNode", "node_id", node_id)
		_config_access.set_value("LocalNode", "node_name", node_name)
		
		_config_access.set_value("Session", "session_id", session_id)
		_config_access.set_value("Session", "session_auto_rejoin", session_auto_rejoin)
		_config_access.set_value("Session", "auto_create_session", auto_create_session)
		
		return _config_access.save(get_user_config_path())
	
	
	## Returns the full filepath to the user config
	static func get_user_config_path() -> String:
		if user_config_file_location.ends_with("/"):
			return user_config_file_location + user_config_file_name
		else:
			return user_config_file_location + "/" + user_config_file_name
 

## Class to repersent an incomming multipart message
class IncommingMultiPart extends Object:
	## The ID of this multipart message
	var id: String
	
	## Stores all numbered chunks
	var chunks: Dictionary[int, PackedByteArray] = {}
	
	## Number of chunks
	var num_of_chunks: int = 0
	
	## Last seen time
	var last_seen: float = Time.get_unix_time_from_system()
	
	## init
	func _init(p_multi_part: ConstaNetMultiPart) -> void:
		id = p_multi_part.multi_part_id
		num_of_chunks = p_multi_part.num_of_chunks
		
		store_multi_part(p_multi_part)
	
	
	## Stores a chunk of data from a ConstaNetMultiPart
	func store_multi_part(p_multi_part: ConstaNetMultiPart) -> void:
		chunks[p_multi_part.chunk_id] = p_multi_part.data
		last_seen = Time.get_unix_time_from_system()
	
	
	## Gets all data that has been sent
	func get_data() -> PackedByteArray:
		var result: PackedByteArray
		
		for i in range(0, num_of_chunks):
			result.append_array(chunks.get(i, PackedByteArray()))
		
		return result
	
	## Returns true if the number of chunks matches what expected
	func is_complete() -> bool:
		return chunks.size() >= num_of_chunks
