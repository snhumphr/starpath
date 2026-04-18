extends Resource
class_name Galaxy

enum ChangeTypes {
	ADD_SHIP, # args; player_id, sys_id, number of ships
	MOVE_SHIP, # args; player_id, starting sys_id, ending sys_id
	REMOVE_SHIP, # args; player_id, sys_id, number of ships
	CHANGE_CONSTRUCTION, # args; sys_id, new construction id
	CHANGE_OWNERSHIP, # args; sys_id, new player_id
	ADVANCE_SETUP, # args are unimportant
	RESEARCH, # uses player_id to find the faction + uses num_ships as tech points
}

const CHANGE_TYPE_INDEX: int = 0
const PLAYER_ID_INDEX: int = 1
const FACTION_ID_INDEX: int = 2
const SYSTEM_ID_INDEX: int = 3
const DEST_ID_INDEX: int = 4
const NUM_SHIPS_INDEX: int = 5

@export var size: Vector2
@export var invalid_paths: Dictionary = {}
@export var display_paths: Dictionary

@export var factions: Dictionary #dictionary should contain player ids(int) mapped to faction objects
@export var players: Array[Player]
@export var systems: Array[StarSystem] = []
@export var ships: Array[Ship] = []

@export var current_turn: int = 0
@export var setup_index: int = 0
@export var setup_order: Array[int] = []
@export var in_setup: bool = true

@export var player_id: int

func end_setup() -> void:
	self.in_setup = false
	self.actions_disabled = false

func get_own_faction() -> Faction:
	return factions[player_id]

func get_faction_name(owner_id: int, index: int, append_player_name: bool = true) -> String:
	
	var faction_id: Faction.FACTION_IDS = self.factions[owner_id].fac_id
	
	if faction_id == Faction.FACTION_IDS.NONE or owner_id == null or owner_id == 0:
		return Faction.FACTION_NAMES[Faction.FACTION_IDS.NONE][index]
	elif index == 0:
		return Faction.FACTION_NAMES[faction_id][index]
	else:
		var faction_name: String = Faction.FACTION_NAMES[faction_id][index]
		if append_player_name:
			faction_name += "(" + self.players[owner_id].player_name + ")"
		return faction_name

func get_system_from_id(system_id: int) -> StarSystem:
	
	for system in self.systems:
		if system.sys_id == system_id:
			return system
	
	return null

func get_systems_from_starpath(starpath: Array[Vector2]) -> Array[StarSystem]:
	
	var starpath_systems: Array[StarSystem] = []
	
	for system in self.systems:
		for neighbour in system.neighbours:
			var possible_match: Array[Vector2] = system.get_starpath(neighbour)
			if starpath == possible_match:
				starpath_systems = [system, neighbour]
				break
	
	return starpath_systems

func init_display_paths() -> void:
	
	var new_display_paths: Dictionary = {}
	
	for system in self.systems:
		for neighbour in system.neighbours:
			var starpath: Array[Vector2] = system.get_starpath(neighbour)
			var display_path: Array[Vector2] = [system.pos, neighbour.pos]
			new_display_paths[starpath] = display_path
	
	self.display_paths = new_display_paths

func get_systems_owned_by_player(owning_player_id: int) -> Array[StarSystem]:
	
	var owned_systems: Array[StarSystem] = []
	var owning_fac_id: Faction.FACTION_IDS = self.factions[owning_player_id].fac_id
	
	for system in self.systems:
		if system.player_id == owning_player_id and system.faction_id == owning_fac_id:
			owned_systems.append(system)
	
	return owned_systems

func get_constructions_owned_by_player(owning_player_id: int) -> Dictionary:
	
	var construction_dict: Dictionary = {}
	var owned_systems: Array[StarSystem] = self.get_systems_owned_by_player(owning_player_id)
	#print("Systems owned by player id # "+ str(owning_player_id) + " : " + str(owned_systems))
	for system in owned_systems:
		if not construction_dict.has(system.construction):
			construction_dict[system.construction] = [system.sys_id]
		else:
			construction_dict[system.construction].append(system.sys_id)
	
	#print(construction_dict)
	return construction_dict

func get_ships_in_system(sys_id: int) -> Dictionary:
	
	var ship_dict: Dictionary = {}
	
	for ship in self.ships:
		
		if ship.system_id == sys_id:
			if not ship_dict.has(ship.player_id):
				ship_dict[ship.player_id] = []
			ship_dict[ship.player_id].append(ship)
	
	return ship_dict

func get_reserved_ships(sys_id: int, action_queue: Array[FactionAction]) -> int:
	#var friendly_ships: Array = self.get_ships_in_system(sys_id).get(self.player_id, [])
	var num_reserved_ships: int = 0
	
	for action in action_queue:
		if action.reserves_ships():
			for i in range(0, action.bound_action_selection.selected_systems.size()):
				if action.bound_action_selection.selected_systems[i].sys_id == sys_id:
					num_reserved_ships += action.bound_action_selection.selected_ships[i]
	
	return num_reserved_ships

func get_ships_by_system() -> Dictionary:
	
	var ship_dict: Dictionary = {}
	
	for system in self.systems:
		ship_dict[system.sys_id] = self.get_ships_in_system(system.sys_id)
	
	return ship_dict

func get_ships_by_player() -> Dictionary:
	
	var ship_dict: Dictionary = {}
	
	for player in self.players:
		ship_dict[player.player_id] = []
	
	for system in self.systems:
		var system_dict: Dictionary = self.get_ships_in_system(system.sys_id)
		for key in system_dict:
			ship_dict[key] += system_dict[key]
	
	return ship_dict

func add_ship(sys_id: int, faction_id: Faction.FACTION_IDS, owner_id: int) -> void:
	
	var new_ship: Ship = Ship.new()
	new_ship.faction_id = faction_id
	new_ship.player_id = owner_id
	new_ship.system_id = sys_id
	
	self.ships.append(new_ship)

func move_ship(start_sys_id: int, owner_id: int, dest_id: int) -> void:
	
	for i in range(0, self.ships.size()):
		var ship: Ship = self.ships[i]
		if ship.system_id == start_sys_id and ship.player_id == owner_id:
			self.ships[i].system_id = dest_id
			break

func destroy_ship(sys_id: int, owner_id: int) -> void:
	
	for i in range(0, self.ships.size()):
		var ship: Ship = self.ships[i]
		if ship.system_id == sys_id and ship.player_id == owner_id:
			self.ships.remove_at(i)
			break

func apply_changes(changes: Array[PackedInt32Array]) -> Array[String]:
	
	var turn_report: Array[String] = []
	
	for change in changes:
		self.apply_change(change)
	
	if self.setup_index >= self.setup_order.size():
		self.in_setup = false
	
	if not self.in_setup:
		self.current_turn += 1
	
	return turn_report

func apply_change(change_list: PackedInt32Array) -> void:
	
	var change_type: ChangeTypes = change_list[0]
	var changed_player_id: int = change_list[1]
	var faction_id: int = change_list[2]
	var sys_id: int = change_list[3]
	var dest_id: int = change_list[4]
	var num_ships: int = change_list[5]
	var new_construction: StarSystem.CONSTRUCTIONS = change_list[6]
	
	match change_type:
		self.ChangeTypes.ADD_SHIP:
			for i in range(0, num_ships):
				self.add_ship(sys_id, faction_id, changed_player_id)
		self.ChangeTypes.MOVE_SHIP:
			for i in range(0, num_ships):
				self.move_ship(sys_id, changed_player_id, dest_id)
		self.ChangeTypes.REMOVE_SHIP:
			for i in range(0, num_ships):
				self.destroy_ship(sys_id, changed_player_id)
		self.ChangeTypes.CHANGE_CONSTRUCTION:
			var system: StarSystem = self.get_system_from_id(sys_id)
			system.construction =  new_construction
		self.ChangeTypes.CHANGE_OWNERSHIP:
			var system: StarSystem = self.get_system_from_id(sys_id)
			system.player_id = changed_player_id
			system.faction_id = faction_id
		self.ChangeTypes.RESEARCH:
			var faction: Faction = self.factions[player_id]
			faction.increase_tech_points(num_ships)
		self.ChangeTypes.ADVANCE_SETUP:
			self.setup_index += 1
		_:
			printerr("Invalid change type " + str(change_type))
			assert(false)

func calculate_fleet_strength(player_id: int, ships: Array[Ship]) -> int:
	
	var fleet_strength: int = 0
	
	fleet_strength += ships.size()
	
	fleet_strength += self.factions[player_id].calculate_tech_level() #TODO: TESTING *DEFINITELY* NEEDED HERE!!!
	
	#TODO: maybe make fortresses give a fleet strength bonus?
	
	return fleet_strength
