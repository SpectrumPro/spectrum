# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Details extends RefCounted
## Static class to store program detils

static var version: String = ProjectSettings.get_setting("application/config/version")

static var schema_version: int = 5

static var copyright: String = "(c) 2026 Liam Sherwin. Licensed under GPL v3."

static var ascii_name: String = """      
  ___              _                  
 / __|_ __  ___ __| |_ _ _ _  _ _ __  
 \\__ \\ '_ \\/ -_) _|  _| '_| || | '  \\ 
 |___/ .__/\\___\\__|\\__|_|  \\_,_|_|_|_|
	 |_|"""



## Function to print all the details
static func print_startup_detils() -> void:
	print(ascii_name, " Version: ", version)
	print()
	print(copyright)
	print()
 
