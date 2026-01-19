# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Universe extends EngineComponent
## Engine component for handling universes, and there outputs


## Emited when a fixture / fixtures are added to this universe
signal fixtures_added(fixtures: Array[DMXFixture])

## Emited when a fixture / fixtures are removed from this universe
signal fixtures_removed(fixtures: Array[DMXFixture])

## Emited when a output / outputs are added to this universe
signal outputs_added(outputs: Array[DMXOutput])

## Emited when a output / outputs are removed from this universe
signal outputs_removed(outputs: Array[DMXOutput])


## Dictionary containing all the fixtures in this universe, stored as channel:Array[fixture]
var _fixture_channels: Dictionary[int, Array] = {} 

## Dictionary containing all the fixtures in this universe, stored as uuid:fixture
var _fixtures: Dictionary[String, DMXFixture] = {}

## Dictionary containing all the outputs in this universe
var _outputs: Dictionary[String, DMXOutput] = {} 


## Called when this EngineComponent is ready
func _init(p_uuid: String = UUID_Util.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("Universe")
	_set_self_class("Universe")
	
	_settings_manager.register_custom_panel("outputs", preload("res://components/SettingsManagerCustomPanels/UniverseOutputEditor.tscn"), "set_universe")
	
	_settings_manager.register_networked_callbacks({
		"on_fixtures_added": _add_fixtures,
		"on_fixtures_removed": _remove_fixtures,
		"on_outputs_added": _add_outputs,
		"on_outputs_removed": _remove_outputs,
	})
	
	_settings_manager.set_callback_allow_deserialize("on_outputs_added")
	_settings_manager.set_callback_allow_deserialize("on_fixtures_added")


## Creates a new output by class name
func create_output(p_output_class_name: String) -> Promise: 
	return rpc("create_output", [p_output_class_name])


## Adds a new output to this universe, returning false if this output can't be added
func add_output(p_output: DMXOutput) -> Promise: 
	return rpc("add_output", [p_output])


## Adds mutiple outputs to this univere at once
func add_outputs(p_outputs: Array[DMXOutput]) -> Promise: 
	return rpc("add_outputs", [p_outputs])


## Removes a output from this engine
func remove_output(p_output: DMXOutput) -> Promise: 
	return rpc("remove_output", [p_output])


## Removes mutiple outputs from this universe
func remove_outputs(p_outputs: Array[DMXOutput]) -> Promise: 
	return rpc("remove_outputs", [p_outputs])


## Adds a new fixture to this universe
func add_fixture(p_fixture: DMXFixture, p_channel: int = -1) -> Promise: 
	return rpc("add_fixture", [p_fixture, p_channel])


## Adds mutiple fixtures to this universe
func add_fixtures(p_fixtures: Array[DMXFixture]) -> Promise: 
	return rpc("add_fixtures", [p_fixtures])


## Removes a fixture from this universe
func remove_fixture(p_fixture: DMXFixture) -> Promise: 
	return rpc("remove_fixture", [p_fixture])


## Removes mutiple fixtures from this universe
func remove_fixtures(p_fixtures: Array[DMXFixture]) -> Promise: 
	return rpc("remove_fixtures", [p_fixtures])


## Returns all fixture on the given channel
func get_fixture_by_channel(p_channel: int) -> Array[DMXFixture]:
	var fixtures: Array[DMXFixture] = []
	fixtures.assign(_fixture_channels.get(p_channel, []))
	
	return fixtures


## Gets all the outputs in this universe
func get_outputs() -> Dictionary:
	return _outputs.duplicate()


## Gets all the fixtures in this universe
func get_fixtures() -> Dictionary:
	return _fixtures.duplicate()


## Sets a manual dmx channel to the set value
func set_dmx_override(p_channel: int, p_value: int) -> Promise: 
	return rpc("set_dmx_override", [p_channel, p_value])


## Removes a manual dmx override
func remove_dmx_override(p_channel: int) -> Promise: 
	return rpc("remove_dmx_override", [p_channel]) 


## Removes all dmx overrides
func remove_all_dmx_overrides() -> Promise:
	return rpc("remove_all_dmx_overrides")


## Internal: Adds an output to this universe
func _add_output(p_output: DMXOutput, p_no_signal: bool = false) -> bool:
	if p_output in _outputs.values():
		return false
	
	_outputs[p_output.uuid()] = p_output
	
	p_output.delete_requested.connect(_remove_output.bind(p_output), CONNECT_ONE_SHOT)
	ComponentDB.register_component(p_output)
	
	if not p_no_signal:
		outputs_added.emit([p_output])
	
	return true


## Internal: Adds mutiple outputs at once
func _add_outputs(p_outputs: Array, p_no_signal: bool = false) -> void:
	var just_added_outputs: Array[DMXOutput] = []

	for output: Variant in p_outputs:
		if output is DMXOutput:
			if _add_output(output, true):
				just_added_outputs.append(output)

	if not p_no_signal and just_added_outputs:
		outputs_added.emit(just_added_outputs)


## Internal: Removes a output from this universe
func _remove_output(p_output: DMXOutput, p_no_signal: bool = false, p_delete: bool = false) -> bool: 
	if not p_output in _outputs.values():
		return false
	
	_outputs.erase(p_output.uuid)

	if not p_no_signal:
		outputs_removed.emit([p_output])
	
	if p_delete:
		p_output.delete()
	
	return true


# Internal: Removes mutiple outputs from this universe
func _remove_outputs(p_outputs: Array, p_no_signal: bool = false, p_delete: bool = false) -> void:
	var just_removed_outputs: Array[DMXOutput] = []

	for output: Variant in p_outputs:
		if output is DMXOutput:
			if _remove_output(output, true, p_delete):
				just_removed_outputs.append(output)
	
	if not p_no_signal and just_removed_outputs:
		outputs_removed.emit(just_removed_outputs)


## Internal: Adds a new fixture to this universe
func _add_fixture(p_fixture: DMXFixture, p_channel: int = -1, p_no_signal: bool = false) -> bool:
	if p_fixture in _fixtures.values():
		return false

	var fixture_channel: int = p_fixture.get_channel() if p_channel == -1 else p_channel
	p_fixture._set_channel(fixture_channel, p_no_signal)
	p_fixture._set_universe(self, p_no_signal)
	
	if not _fixture_channels.get(fixture_channel):
		_fixture_channels[fixture_channel] = []
	
	_fixture_channels[fixture_channel].append(p_fixture)
	_fixtures[p_fixture.uuid()] = p_fixture

	p_fixture.delete_requested.connect(_remove_fixture.bind(p_fixture), CONNECT_ONE_SHOT)

	if not p_no_signal:
		fixtures_added.emit([p_fixture])
	
	return true


## Internal: Adds mutiple fixtures to this universe
func _add_fixtures(p_fixtures: Array, p_no_signal: bool = false) -> void:
	var just_added_fixtures: Array[DMXFixture] = []

	for fixture: Variant in p_fixtures:
		if fixture is DMXFixture:
			if _add_fixture(fixture, -1, true):
				just_added_fixtures.append(fixture)
	
	if not p_no_signal and just_added_fixtures:
		fixtures_added.emit(just_added_fixtures)


## Internal: Removes a fixture from this universe
func _remove_fixture(p_fixture: DMXFixture, p_no_signal: bool = false, p_delete: bool = false) -> bool:
	if not p_fixture in _fixtures.values():
		return false
	
	_fixtures.erase(p_fixture.uuid())
	
	if _fixture_channels.has(p_fixture.get_channel()):
		_fixture_channels[p_fixture.get_channel()].erase(p_fixture)
		
		if not _fixture_channels[p_fixture.get_channel()]:
			_fixture_channels.erase(p_fixture.get_channel())
		
	if not p_no_signal:
		fixtures_removed.emit([p_fixture])
	
	if p_delete:
		p_fixture.local_delete()
	
	return true


## Internal: Removes mutiple fixtures from this universe
func _remove_fixtures(p_fixtures: Array, p_no_signal: bool = false, p_delete: bool = false) -> void:
	var just_removed_fixtures: Array[DMXFixture] = []
	
	for fixture: Variant in p_fixtures:
		if fixture is DMXFixture:
			if _remove_fixture(fixture, true, p_delete):
				just_removed_fixtures.append(fixture)
	
	if not p_no_signal and just_removed_fixtures:
		fixtures_removed.emit(just_removed_fixtures)


## Called when this universe is to be deleted, see [method EngineComponent.delete]
func delete() -> void:
	_remove_outputs(_outputs.values(), false, true)
	_remove_fixtures(_fixtures.values(), false, true)
	
	super.delete()


## Serializes this universe
func serialize() -> Dictionary:
	var serialized_outputs: Dictionary[String, Dictionary] = {}
	var serialized_fixtures: Dictionary[String, Array] = {}

	for output: DMXOutput in _outputs.values():
		serialized_outputs[output.uuid()] = output.serialize()
	
	for channel: int in _fixture_channels.keys():
		serialized_fixtures[str(channel)] = []

		for fixture: DMXFixture in _fixture_channels[channel]:
			serialized_fixtures[str(channel)].append(fixture.uuid)

	return super.serialize().merged({
		"outputs": serialized_outputs,
		"fixtures": serialized_fixtures
	})



## Loads this universe from a serialised universe
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	var just_added_fixtures: Array[DMXFixture] = []
	var just_added_output: Array[DMXOutput] = []

	for fixture_channel: String in p_serialized_data.get("fixtures", []):
		for fixture_uuid: String in p_serialized_data.fixtures[fixture_channel]:
			var fixture: EngineComponent = ComponentDB.get_component(fixture_uuid)

			if fixture is DMXFixture:
				_add_fixture(fixture, -1, true)
				just_added_fixtures.append(fixture)
	
	for output_uuid: String in p_serialized_data.get("outputs", {}).keys():
		var classname: String = p_serialized_data.outputs[output_uuid].get("class_name", "")
		if ClassList.has_class(classname, "DMXOutput"):
			var new_output: DMXOutput = ClassList.get_class_script(classname).new(output_uuid)
			new_output.deserialize(p_serialized_data.outputs[output_uuid])
			
			_add_output(new_output, true)
			just_added_output.append(new_output)

	if just_added_fixtures:
		fixtures_added.emit(just_added_fixtures)
	
	if just_added_output:
		outputs_added.emit(just_added_output)
