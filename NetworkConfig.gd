static var config: Dictionary[String, Variant] = {
	## The instance of CoreClassListDB asigned to the networkable class 
	"networkable_class_list": ComponentClassList,
	
	## The instance of CoreObjectDB asigned to the networkable class 
	"networkable_object_db": ComponentDB,
	
	## The instacne of CoreClassListDB for NetworkItems
	"network_item_class_list": NetworkClassList,
	
	## The instance of CoreObjectDB for NetworkItems
	"network_item_object_db": NetworkDB,
	
	## All available NetworkHandlers that can be loaded
	"available_handlers": {
		"Constellation": Constellation
	},
}
