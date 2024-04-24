# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

extends Node
## Client side network control

var _networked_objects: Dictionary = {} ## Contains a list of networked objects, stores their functions and data types of there args
var _callbacks: Dictionary = {} ## Contains a list of callbacks, stored as callback id:callable


func _ready() -> void:
	MainSocketClient.connected_to_server.connect(func(): print("connected"))
	MainSocketClient.message_received.connect(self._on_message_receved)
	MainSocketClient.connect_to_url("ws://127.0.0.1:3824")


## Send a message to the server, all data passed is automatically converted to strings, and serialised
func send(data: Dictionary, callback: Callable = Callable()) -> void:
	if callback.is_valid():
		var callback_id = UUID_Util.v4()
		_callbacks[callback_id] = callback
		data.callback_id = callback_id
		
	MainSocketClient.send(var_to_str(Utils.objects_to_uuids(data)))


## Add a network object
func add_networked_object(object_name: String, object: Object) -> void:
	var new_networked_config: Dictionary = {
		"object": object,
		"functions": {},
	}

	var method_list: Array = object.get_script().get_script_method_list()

	# Loop through each function on the object that is being added, and create a dictionary containing the avaibal function, and their args
	for index: int in range(len(method_list)):
		
		# If the method name starts with an "_", discard it, as this meanes its an internal method that should not be called by the client
		if method_list[index].name.begins_with("_"):
			continue 
	
		var method: Dictionary = {
			"callable":object.get(method_list[index].name),
			"args":{}
		}
		
		# Loop through all the args in this method, and note down there name and type
		for arg: Dictionary in method_list[index].args:
			method.args[arg.name] = arg.type

		new_networked_config.functions[method_list[index].name] = method

	_networked_objects[object_name] = new_networked_config 
	
	print(_networked_objects)


## Remove a network object
func remove_networked_object(name: String) -> void:
	_networked_objects.erase(name)


## Called when a message is receved from the server 
func _on_message_receved(message: Variant) -> void:
	
	# Check to make sure the message passed is a Dictionary
	message = str_to_var(message)
	if not message is Dictionary:
		return
	
	# Conver all seralized objects to objects refs
	var command: Dictionary = Utils.uuids_to_objects(message, _networked_objects, add_networked_object)
	
	# If command has the "signal" value, check if its a valid function in the network object specifyed in the command.for value
	if "signal" in command and command.get("for") in _networked_objects:
		var networked_object: Dictionary = _networked_objects[message.for]
		
		# Check if the function still exists, in case it is no longer valid
		if networked_object.object.has_method(command.signal):
			
			var method: Dictionary = networked_object.functions[command.signal]
			
			# Loop through all the args passed from the server, and check the type of them against the function in the networked object
			if "args" in command:
				for index in len(command.args):
					# Check if the server has passed too many args to the client, if so stop now to avoid a crash
					if index >= len(method.args.values()):
						print("Total arguments provided by server: ", len(command.args), " Is more then: ", command.signal, " Is expecting, at: ", len(method.args))
						return
					
					# Check if the type of the arg passed by the sever matches the arg expected by the function, if not stop now to avoid a crash
					if not typeof(command.args[index]) == method.args.values()[index]:
						print("Type of data: ", command.args[index],  " does not match type: ", type_string(method.args.values()[index]), " required by: ", method.callable)
						return
			
			# If all check above pass, call the function and pass the arguments
			(networked_object.object.get(command.signal) as Callable).callv(command.get("args", []))
	
	# Check if it has "callback_id"
	if "callback_id" in command:
		
		# Check if the callback_id in regestered in _callbacks
		if command.get("callback_id", "") in _callbacks:
			if command.get("response"):
				_callbacks[command.callback_id].call(command.response)
			else:
				_callbacks[command.callback_id].call()
			
			_callbacks.erase(command.callback_id)