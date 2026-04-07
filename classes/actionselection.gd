extends Resource
class_name ActionSelection

@export var selected_systems: Array[StarSystem] = []
@export var selected_ships: Array[int] = []

func add_system(galaxy: Galaxy, new_system: StarSystem, current_action: FactionAction = null) -> bool:
	
	if self.selected_systems.has(new_system):
		return false
	else:
		
		if current_action != null:
			pass 	#TODO: check if the currently selected action allows for adding this particular system
		
		self.selected_systems.append(new_system)
		print(new_system.get_system_name() + " has been added to the selection")
		if false: #TODO: check if there are any valid ships to select in the chosen system
			self.selected_ships.append(1)
		else:
			self.selected_ships.append(0)
		return true

func get_system_index(galaxy: Galaxy, system: StarSystem) -> int:
	
	var index: int = -1
	
	for i in range(0, self.selected_systems.size()):
		if system.is_system_identical(self.selected_systems[i]):
			index = i
			break
	
	return index

func remove_system(galaxy: Galaxy, del_system: StarSystem) -> void:
	
	var index: int = self.get_system_index(galaxy, del_system)
	
	if index != -1:
		
		self.selected_systems.remove_at(index)
		self.selected_ships.remove_at(index)
		print(del_system.get_system_name() + " has been removed from the selection")

func add_ship(galaxy: Galaxy, system: StarSystem) -> void:
	
	var index: int = self.get_system_index(galaxy, system)
	
	if index != -1:
		pass #TODO: make it so that trying to add ships over the amount present in the system resets the selection to 0 ships
		self.selected_ships[index] += 1

func wipe() -> void:
	print("All selected systems/ships have been wiped.")
	self.selected_systems = []
	self.selected_ships = []
