# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CoreLogger extends Node
## Handles custom logging methods


## Emitted when a normal message gets logged
signal on_info_message(p_message: String)

## Emitted when a error message gets logged
signal on_warning_message(p_message: String, p_file: String)

## Emitted when a error message gets logged
signal on_error_message(p_message: String, p_location: String, p_file: String, p_line: int, p_error: Error, p_stacktrace: String)

## Emitted when a command is recieved over the network from a remote stream reciever
signal on_command_recieved(p_command: String)


## Enum for LogLevel
enum LogLevel {
	ALL,		## All log types
	INFO,		## Informational messages, general runtime info
	WARNING,	## Warning messages, indicate potential issues
	ERROR		## Error messages, indicate failures or critical issues
}


## The EngineLogger to capture engine warnings and errors
var _engine_logger: EngineLogger = EngineLogger.new(self)

## The PacketPeerUDP to sending remote logs
var _udp_socket: PacketPeerUDP = PacketPeerUDP.new()

## Stores all remote IP and Port pairs, and timeouts in seconds
var _remotes: Dictionary[String, Dictionary]

## True if the next request to print to stdout or stderr should be ignored
var _ignore_next: bool = false

## The user defined name of this instance of this program
var _instance_name: String


## init
func _init() -> void:
	OS.add_logger(_engine_logger)
	_udp_socket.bind(0, "127.0.0.1")
	
	var cli_args: PackedStringArray = OS.get_cmdline_args()
	if "--remote-logs" in cli_args:
		var name_index: int = cli_args.find("--remote-logs") + 1
		var port: int = int(cli_args[name_index])
		add_remote("127.0.0.1", port, -1)
	
	add_remote("127.0.0.1", 5555, -1)
	


## process
func _process(delta: float) -> void:
	while _udp_socket.get_available_packet_count():
		var message: String = _udp_socket.get_packet().get_string_from_ascii()
		
		match message:
			"getinfo":
				_udp_socket.set_dest_address(_udp_socket.get_packet_ip(), _udp_socket.get_packet_port())
				_udp_socket.put_packet(str({
					"instance_name": _instance_name,
					"project_name": ProjectSettings.get_setting("application/config/name"),
					"version": ProjectSettings.get_setting("application/config/version"),
					"pid": OS.get_process_id(),
					"runtime": Time.get_ticks_msec()
				}).to_ascii_buffer())
		
		on_command_recieved.emit(message)


## Ignores the next request to print to stdout or stderr should be ignored
func ignore_next() -> void:
	_ignore_next = true


## Prints a log message to stdout or stderr depending on loglevel
func print_log(p_log: String, p_level: LogLevel) -> void:
	for ip: String in _remotes.keys():
		for port: int in _remotes[ip].keys():
			_udp_socket.set_dest_address(ip, port)
			_udp_socket.put_packet(JSON.stringify({"level": p_level, "log": p_log}).to_ascii_buffer())
	
	if _ignore_next:
		_ignore_next = false
		return
	
	match p_level:
		LogLevel.ALL:
			print(p_log)
		LogLevel.INFO:
			print("INFO: ", p_log)
		LogLevel.WARNING:
			push_warning("WARNING: ", p_log)
		LogLevel.ERROR:
			push_error("ERROR: ", p_log)


## Prints a new line to the log
func new_line() -> void:
	print_log("", LogLevel.ALL)


## Logs a LogLevel.INFO
func info(...p_args: Array) -> void:
	var as_string: String = ""
	
	for arg: Variant in p_args:
		as_string += str(arg)
	
	print_log(as_string, LogLevel.INFO)
	on_info_message.emit(as_string)


## Logs a LogLevel.WARNING message
func warning(p_file: String, ...p_args: Array) -> void:
	var as_string: String = ""
	
	for arg: Variant in p_args:
		as_string += str(arg)
	
	print_log(" ".join([p_file, as_string]), LogLevel.WARNING)
	on_warning_message.emit(as_string, p_file)


## Logs a LogLevel.ERROR message
func error(p_function: String, p_file: String, p_line: int, p_error: Error, p_stacktrace: String, ...p_args: Array,) -> void:
	var as_string: String = ""
	
	for arg: Variant in p_args:
		as_string += str(arg)
	
	print_log(" ".join([p_file, p_line, error_string(p_error), p_stacktrace, as_string]), LogLevel.ERROR)
	on_error_message.emit(as_string, p_file, p_line, p_error, p_stacktrace)


## Adds a remote ip and port pair to stream logs to
func add_remote(p_ip: String, p_port: int, p_timeout: int) -> void:
	info("Adding remote log stream to: ", p_ip, ":", p_port)
	_remotes.get_or_add(p_ip, {}).get_or_add(p_port, p_timeout)


## Removes a remote IP and port stream, passing port 0 will remote all ports on the address
func remove_remote(p_ip: String, p_port: int) -> void:
	if p_port:
		_remotes.get(p_ip, {}).erase(p_port)
	else:
		_remotes.erase(p_ip)


## Sets the instance name of this project, used for network info
func set_instance_name(p_instance_name: String) -> void:
	_instance_name = p_instance_name


## Gets the instance name
func get_instacne_name() -> String:
	return _instance_name


## The Logger class to capture engine errors
class EngineLogger extends Logger:
	
	## The EngineLogger this Logger should foward logs to
	var _logger: CoreLogger
	
	## init
	func _init(p_logger: CoreLogger) -> void:
		_logger = p_logger
	
	
	## Logs a info message
	func _log_message(p_message: String, p_error: bool) -> void:
		if p_error:
			breakpoint
		_logger.ignore_next()
		_logger.info(p_message)
	
	
	## Logs an error message
	func _log_error(p_function: String, p_file: String, p_line: int, p_code: String, p_rationale: String, p_editor_notify: bool, p_error_type: int, p_script_backtraces: Array[ScriptBacktrace]) -> void:
		_logger.ignore_next()
		_logger.error(p_function, p_file, p_line, p_error_type, str(p_script_backtraces), p_code + p_rationale)
