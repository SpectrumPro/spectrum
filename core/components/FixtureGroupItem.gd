# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name FixtureGroupItem extends EngineComponent
## A data container for Fixture Groups, this does not do anyting by its self.


## Emited when the fixture changes
signal fixture_changed(fixture: Fixture)

## Emitted when the position changes
signal position_changed(position: Vector3)


## The fixture asigned to this group item
var _fixture: Fixture = null

## The position of this fixture in this group item
var _position: Vector3 = Vector3.ZERO


## init
func _init(p_uuid: String = UUID.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("FixtureGroupItem")
	_set_class_name("FixtureGroupItem")
	
	_settings.register_networked_callbacks({
		"on_fixture_changed": _set_fixture,
		"on_position_changed": _set_position,
	})


## Sets the fixture
func set_fixture(p_fixture: Fixture) -> void: rpc("set_fixture", [p_fixture])

## Internal: Sets the fixture
func _set_fixture(p_fixture: Fixture) -> void:
	if p_fixture == _fixture: return
	
	_fixture = p_fixture
	fixture_changed.emit(_fixture)

## Gets the fixture
func get_fixture() -> Fixture: return _fixture


## Sets the fixtures position
func set_position(p_position: Vector3) -> void: rpc("set_position", [p_position])

## Internal: Sets the fixtures position
func _set_position(p_position: Vector3) -> void:
	if _position == p_position: return
	
	_position = p_position
	position_changed.emit(_position)

## Gets the position
func get_position() -> Vector3: return _position


## Saves this component into a dict
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"fixture": _fixture.uuid,
		"position": var_to_str(_position)
	})


## Loads this component from a dict
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	if p_serialized_data.get("fixture") is String and ComponentDB.get_component(p_serialized_data.fixture) is Fixture:
		_set_fixture(ComponentDB.get_component(p_serialized_data.fixture))
	
	var position: Variant = p_serialized_data.get("position", null)
	if position is String and str_to_var(position) is Vector3:
		_set_position(str_to_var(position))
