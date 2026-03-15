static var config: Dictionary = {
	## Defines a custom callable to call when logging infomation
	"custom_loging_method": Log.info,
	
	## Defines a custom callable to call when logging infomation verbosely
	"custom_loging_method_verbose": Callable(),
	
	## A String prefix to print before all message logs
	"log_prefix": "CTL:",
	
	## Default IP address to bind to
	"bind_address": "",
	
	## Default IP address to bind to
	"bind_interface": "",
	
	## File location for a user config override
	"user_config_file_location": "user://",
	
	## File name for the user config override
	"user_config_file_name": "constellation.conf",
	
	## NodeID of the local node
	"node_id": UUID.v4(),
	
	## Node name of the local node
	"node_name": "Spectrum Client",
	
	## SessionID of the previous session the local node was in
	"session_id": "",
	
	## True if the previous session
	"session_auto_rejoin": true,
	
	## True if this node should auto create a session once online, asuming previous session is is null and the node is not already in a session
	"auto_create_session": false
}
