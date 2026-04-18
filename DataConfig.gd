class_name DataConfig extends Object
## Class to store config for Data


## Class to store SubType keys
class SubType:
	enum Type {
		NULL,						## No Type
		INT_CID,					## A Component ID
		OBJECT_ENGINECOMPONENT,		## A EngineComponent
		OBJECT_FIXTUREMANIFEST,		## A FixtureManifest
		OBJECT_NETWORKITEM,			## A NetworkItem
		OBJECT_UIPANEL,				## A UIPanel instance
		PACKEDSCENE_UIPANEL,		## A UIPanel PackedScene
	}


## Config for Data
var config: Dictionary[String, Variant] = {
	"gbc_index": {
		"EngineComponent": GBCIndexConfig.new(EngineComponent, ComponentDB, ComponentClassList, ChildManager.new(
			Core, 
			Core.create_component,
			Core.add_component,
			Core.add_components,
			Core.remove_component,
			Core.remove_components,
			Core.duplicate_component,
			Callable(), ## TODO add CoreEngine.duplicate_components() method
			ComponentDB.get_components,
			ComponentDB.components_added,
			ComponentDB.components_removed,
			EngineComponent,
			EngineComponent, 
		)),
		"NetworkItem": GBCIndexConfig.new(NetworkItem, NetworkDB, NetworkClassList, ChildManager.new(
			Network,
			Callable(),
			Callable(),
			Callable(),
			Callable(),
			Callable(),
			Callable(),
			Callable(),
			NetworkDB.get_components,
			NetworkDB.components_added,
			NetworkDB.components_removed,
			NetworkItem,
			NetworkItem
		))
	}
}
