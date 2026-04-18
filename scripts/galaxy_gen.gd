extends Node

const GALAXY_SIZE: Vector2i = Vector2i(6, 6)
const EMPTY_SYSTEM_PERCENTAGE: float = 0.2

var max_starpath_length: float = 0.5
var starpaths: Dictionary = {}

var add_change: PackedInt32Array = PackedInt32Array([
	Galaxy.ChangeTypes.ADD_SHIP, #change type
	0, #player id
	Faction.FACTION_IDS.NONE, #faction id
	0, #system id
	0, #dest id
	1, #num ships
	StarSystem.CONSTRUCTIONS.EMPTY, #new construction
])

func init(gal_seed: int) -> Galaxy:

	var new_galaxy: Galaxy = self.generate_random_galaxy(gal_seed)
	
	#TODO: Better galaxy testing here
	
	#self.check_neighbours(new_galaxy)

	return new_galaxy

func check_neighbours(galaxy: Galaxy) -> void:
	
	var pairs: Dictionary = {}
	
	for system in galaxy.systems:
		for neighbour in system.neighbours:
			if not pairs.has(system.get_starpath(neighbour)):
				pairs[system.get_starpath(neighbour)] = true
				print(str(system.sys_id) + " neighbours " + str(neighbour.sys_id))

func num_empty_systems() -> int:
	return ceil(GALAXY_SIZE.x * GALAXY_SIZE.y * EMPTY_SYSTEM_PERCENTAGE)

func generate_random_galaxy(galaxy_seed: int) -> Galaxy:
	
	#TODO: do more RNG/seeding/whatever here
	
	seed(galaxy_seed)
	
	var coords: Array[Vector2] = []
	
	for x in range(1, GALAXY_SIZE.x):
		for y in range(1, GALAXY_SIZE.y):
			var new_coord: Vector2 = Vector2(x, y)
			coords.append(new_coord)
	
	coords.shuffle()
	
	var coord_removal_list: Array[Vector2] = []
	var coord_index: int = 0
	while coord_index < self.num_empty_systems():
		coord_removal_list.append(coords[coord_index])
		coord_index += 1
	
	for coord in coord_removal_list:
		coords.erase(coord)
	
	#print(coords)
	#print(coords.size())
	
	var new_galaxy: Galaxy = Galaxy.new()
	
	new_galaxy.size = GALAXY_SIZE
	
	coord_index = 0
	while coord_index < coords.size():
		var new_system: StarSystem = StarSystem.new(coord_index, coords[coord_index])
		new_system.gal_pos = new_system.gal_pos + new_system.offset()
		new_galaxy.systems.append(new_system)
		coord_index += 1
	
	new_galaxy.systems.shuffle()
	
	for i in range(0, 7):
		
		for system in new_galaxy.systems:
			var neighbour_candidates: Array[StarSystem] = self.get_possible_neighbours(new_galaxy, system)
			for candidate in neighbour_candidates:
				self.try_neighbour_connection(system, candidate)
		
		max_starpath_length += 0.2
	
	return new_galaxy

func generate_setup_order(galaxy: Galaxy) -> Array[int]:
	
	var order: Array[int] = []
	
	for index in range(0, galaxy.players.size()):
		var player: Player = galaxy.players[index]
		var player_faction: Faction = galaxy.factions[player.player_id]
		if not player.is_hidden and not player.resigned:
			order.append(player.player_id)
			#order.append(player_faction.setup_priority+index)
	
	order.sort()
	
	#TODO: MAKE THIS ACTUALLY RETURN A LIST OF PLAYER IDS SORTED BY THEIR FACTION PRIORITY
	
	return order

func get_possible_neighbours(galaxy: Galaxy, system: StarSystem) -> Array[StarSystem]:
	
	var other_systems: Array[StarSystem] = []
	
	for possible_system in galaxy.systems:
		if not system.is_system_identical(possible_system):
			if Geometry2D.is_point_in_circle(possible_system.gal_pos, system.gal_pos, max_starpath_length):
				var intersections: Dictionary = try_neighbour_connection(system, possible_system)
				for key in intersections:
					galaxy.invalid_paths[key] = intersections[key]
	
	return other_systems

func try_neighbour_connection(system_a: StarSystem, system_b: StarSystem) -> Dictionary:
	
	var starpath: Array[Vector2] = system_a.get_starpath(system_b)
	var intersections: Dictionary = {}
	#print(starpaths.keys().size())
	
	if not starpaths.has(starpath):
		
		var starpath_valid: bool = true
		
		for otherpath in starpaths.keys():
			var intersection = Geometry2D.segment_intersects_segment(starpath[0], starpath[1], otherpath[0], otherpath[1])
			if intersection != null:
				
				intersections[intersection] = starpath
				starpath_valid = false
				
				break
		
		if starpath_valid:
			system_a.set_neighbour(system_b)
			starpaths[starpath] = true
	
	return intersections

func place_neutrals(galaxy: Galaxy, changes: Array[PackedInt32Array]) -> void:
	
	var empty_system_ids: Array[int] = []
	
	for system in galaxy.systems:
		if system.player_id == 0:
			var is_targeted: bool = false
			for change in changes:
				if system.sys_id == change[3]:
					is_targeted = true
					break
			if not is_targeted:
				empty_system_ids.append(system.sys_id)
	
	for sys_id in empty_system_ids:
		var system: StarSystem = galaxy.get_system_from_id(sys_id)
		var new_add_change: PackedInt32Array = self.add_change.duplicate()
		new_add_change[3] = sys_id
		changes.append(new_add_change)
		for i in range(0, ceil(system.neighbours.size()/2)):
			changes.append(new_add_change)
