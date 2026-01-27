# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CoreFixtureLibrary extends Node
## The main fixture library used to manage fixture manifests


## Emitted when the manifests are found
signal manifests_found()


## All the current found manifests, { "manufacturer": { "name": {...} } }
var _found_sorted_manifest_info: Dictionary[String, Dictionary] = {}

## All loaded fixture manifests, { "manifest_uuid": FixtureManifest }
var _loaded_manifests: Dictionary = {}

## All the current requests for manifests, used when fixtures are loaded before manifest importing
var _manifest_requests: Dictionary

## Loaded state
var _is_loaded: bool = false

## The SettingsManager
var _settings_manager: SettingsManager = SettingsManager.new()


## Init
func _init() -> void:
	_settings_manager.set_owner(self)
	_settings_manager.set_inheritance_array(["CoreFixtureLibrary"])


## Ready
func _ready() -> void:
	Core.synchronizing.connect(_synchronize)


## Gets the SettingsManager
func settings() -> SettingsManager:
	return _settings_manager


## Creates a new fixture from a manifest
func create_fixture(p_manifest_uuid: String, p_universe: Universe, p_channel: int, p_quantity: int, p_offset: int, p_mode: String, p_name: String, p_increment_name: bool) -> void:
	Network.send_command("FixtureLibrary", "create_fixture", [p_manifest_uuid, p_universe, p_channel, p_quantity, p_offset, p_mode, p_name, p_increment_name])


## Gets a manifest, imports it if its not already imported
func get_manifest(p_manifest_uuid: String) -> FixtureManifest:
	if _loaded_manifests.has(p_manifest_uuid):
		return _loaded_manifests[p_manifest_uuid]

	return null


## Returnes the sorted manifest info of all manifests found
func get_sorted_manifest_info() -> Dictionary[String, Dictionary]:
	return _found_sorted_manifest_info.duplicate(true)


## Gets a manifest from a manifest uuid, return a promise 
func request_manifest(p_manifest_uuid: String) -> Promise:
	var promise: Promise = Promise.new()
	
	if not p_manifest_uuid:
		return promise.auto_reject()
	
	var manifest: FixtureManifest = _loaded_manifests.get(p_manifest_uuid)
	
	if manifest:
		promise.auto_resolve([_loaded_manifests[p_manifest_uuid]])
	
	else:
		if p_manifest_uuid not in _manifest_requests:
			Network.send_command("FixtureLibrary", "get_manifest", [p_manifest_uuid]).then(_on_get_manifest_received)
		
		_manifest_requests.get_or_add(p_manifest_uuid, []).append(promise)
	
	return promise


## Check loaded state
func is_loaded() -> bool: 
	return _is_loaded


## Called when the engine send out a synchronize request
func _synchronize() -> void:
	_is_loaded = false
	
	Network.send_command("FixtureLibrary", "get_sorted_manifest_info").then(func (p_sorted_fixture_manifests: Dictionary):
		_found_sorted_manifest_info = Dictionary(p_sorted_fixture_manifests, TYPE_STRING, "", null, TYPE_DICTIONARY, "", null)
		_is_loaded = true
		manifests_found.emit()
	)


## Resets this CoreFixtureLibrary
func _reset() -> void:
	_is_loaded = false
	
	for promise_array: Array in _manifest_requests:
		for promise: Promise in promise_array:
			promise.reject()
	
	_found_sorted_manifest_info.clear()
	_loaded_manifests.clear()
	_manifest_requests.clear()


## Called when a manifest is received from the server
func _on_get_manifest_received(p_manifest: FixtureManifest) -> void:
	if p_manifest:
		_loaded_manifests[p_manifest.uuid()] = p_manifest
		for promise: Promise in _manifest_requests.get(p_manifest.uuid(), []):
			promise.resolve([p_manifest])
		
		_manifest_requests.erase(p_manifest.uuid)
