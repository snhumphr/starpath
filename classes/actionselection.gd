extends Resource
class_name ActionSelection

@export var selected_systems: Array[StarSystem] = []
@export var selected_ships: Array[int] = []

func add_system(galaxy: Galaxy, new_system: StarSystem, action_queue: Array[FactionAction]) -> bool:
	
	if self.selected_systems.has(new_system):
		return false
	else:
		self.selected_systems.append(new_system)
		#print(new_system.get_system_name() + " has been added to the selection")
		
		self.selected_ships.append(0)
		
		#self.add_ship(galaxy, new_system, action_queue)
		
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

func add_ship(galaxy: Galaxy, system: StarSystem, action_queue: Array[FactionAction]) -> void:
	
	var index: int = self.get_system_index(galaxy, system)
	
	if index != -1:
		var system_ships: Dictionary = galaxy.get_ships_in_system(system.sys_id)
		var friendly_ships: Array = system_ships.get(galaxy.player_id, [])
		var num_ships_reserved: int = 0
		
		num_ships_reserved = galaxy.get_reserved_ships(system.sys_id, action_queue)
		
		#print(num_ships_reserved)
		
		if friendly_ships.size() > num_ships_reserved + self.selected_ships[index]:
			self.selected_ships[index] += 1
		else:
			self.selected_ships[index] = 0
	else:
		printerr("Invalid system id " + str(system.sys_id))

func remove_ship(galaxy: Galaxy, system: StarSystem, action_queue: Array[FactionAction]) -> void:
	
	var index: int = self.get_system_index(galaxy, system)
	
	if index != -1:
		if self.selected_ships[index] > 1:
			self.selected_ships[index] -= 1
		else:
			self.selected_ships[index] = 1
	else:
		printerr("Invalid system id " + str(system.sys_id))

func export_ships_as_ids() -> PackedInt32Array:
	
	var export_array: PackedInt32Array = PackedInt32Array([])
	for ship in self.selected_ships:
		export_array.append(ship)
	
	return export_array

func export_systems_as_ids() -> PackedInt32Array:
	
	var export_array: PackedInt32Array = PackedInt32Array([])
	for system in self.selected_systems:
		export_array.append(system.sys_id)
	
	return export_array

func load_selection(galaxy: Galaxy, system_ids: PackedInt32Array, ship_ids: PackedInt32Array):
	
	for sys_id in system_ids:
		self.selected_systems.append(galaxy.get_system_from_id(sys_id))
	
	for ship_id in ship_ids:
		self.selected_ships.append(ship_id)

func wipe() -> void:
	#print("All selected systems/ships have been wiped.")
	self.selected_systems = []
	self.selected_ships = []
