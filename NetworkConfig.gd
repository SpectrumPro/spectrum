static var config: Dictionary[String, Variant] = {
	## The instance of ClassListDB asigned to the networkable class 
	"networkable_class_list": ClassList,
	
	## The instance of ObjectDB asigned to the networkable class 
	"networkable_object_db": ComponentDB,
	
	## The instacne of ClassListDB for NetworkItems
	"network_item_class_list": NetworkClassList,
	
	## The instance of ObjectDB for NetworkItems
	"network_item_object_db": NetworkDB,
	
	## All available NetworkHandlers that can be loaded
	"available_handlers": {
		"Constellation": Constellation
	},
}
