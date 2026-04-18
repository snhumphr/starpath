extends Resource
class_name StarSystem

enum CONSTRUCTIONS {
	EMPTY,
	SHIPYARD,
	LAB,
	FORTRESS,
}

const SYSTEM_NAMES: Array[String] = [
	"The Origin",
	"Unity",
	"Blackport",
	"The Wheel",
	"Firestar",
	"Precipice",
	"The Mists",
	"Antediluvia",
	"Trinity",
	"Ard Draconis",
	"Verge",
	"The Dancers",
	"Babel",
	"Whitefall",
	"The Bucket",
	"Icecrown",
	"King's Rest",
	"The Maiden",
	"Hawkmoth",
	"Siren",
	"Lantern's Dream",
	"Valkyr",
	"Sandhell",
	"Aria",
	"Silvercup",
	"The Pit",
	"Darkmere",
	"The Brothers",
	"Arth's Dream",
	"Shroudwell",
	"The Hand",
	"Phoenix",
	"Breakford",
	"Three of a Kind",
	"Polaris",
	"Ember",
	"The Tower",
	"Barrowrock",
	"Eternal Approach",
	"Redstone",
	"The Plunge",
	"Lightbreaker",
	"Minotaur",
	"Sapphire",
	"Aille's Fall",
	"Bastion",
	"The Geyser",
	"Mirrorhound",
	"Flotsam",
	"Gloamdeep",
	"The Bear",
	"Broke",
	"Nighthold",
	"Golden Twins",
	"The Dying Sun",
	"Wink",
	"Hermes",
	"Carousel",
	"Bluegrave",
	"Foxfire",
	"Manse",
	"Basilisk",
	"Promise",
	"Last Seed",
	"Blindheart",
	"Threshold",
	"Totality",
	"Eclipse",
	"New Atlantis",
	"The Claw",
	"The Thousand",
	"Omen",
	"Helix",
	"Yearning",
	"Prism",
	"Hollowhand",
	"Shimmersong",
	"The Doorway",
	"Telluria"
]

@export var sys_id: int

@export var player_id: int = 0
@export var faction_id: Faction.FACTION_IDS = Faction.FACTION_IDS.NONE
@export var neighbours: Array[StarSystem] = []
@export var construction: StarSystem.CONSTRUCTIONS

@export var gal_pos: Vector2
@export var pos: Vector2
@export var radius: float

func init(new_id: int, new_gal_pos: Vector2) -> void:
	self.sys_id = new_id
	self.gal_pos = new_gal_pos

func get_system_name() -> String:
	
	var sys_name: String = "System #" + str(self.sys_id)
	
	if self.sys_id < SYSTEM_NAMES.size():
		sys_name += "(" + SYSTEM_NAMES[self.sys_id] + ")"
	
	return sys_name

func get_system_description(galaxy: Galaxy) -> String:
	
	var description: String = self.get_system_name()
	
	description += ".  " + "Owned by " + Faction.FACTION_NAMES[self.faction_id][0] + " " + galaxy.get_faction_name(self.player_id, 1) + "."
	
	description += "\n"
	match self.construction:
		StarSystem.CONSTRUCTIONS.SHIPYARD:
			description += "SHIPYARD: Titanic factories lathe oceans of metal into weapons."
		StarSystem.CONSTRUCTIONS.LAB:
			description += "LAB: Home to a cutting-edge ether-compliant research facility."
		StarSystem.CONSTRUCTIONS.FORTRESS:
			description += "FORTRESS: Fortified with an interdiction-class Star Citadel."
		_:
			description += "VACANT: No major constructions are present. WWWWWWWWWWWWWWWW"
	
	var ships_dict: Dictionary = galaxy.get_ships_in_system(self.sys_id)
	var ships_desc: PackedStringArray = PackedStringArray([])
	var ship_verb: String = ""
	
	for key in ships_dict.keys():
		var ship_count: int = 0
		var ship_array: Array[Ship] = []
		for ship in ships_dict[key]:
			if not ship.is_hidden:
				ship_count += 1
			ship_array.append(ship) #TODO: CHECK THAT THIS STILL WORKS WITH STEALTHED SHIPS
		if ship_count > 0:
			var ship_desc: String = str(ship_count) + " " + galaxy.get_faction_name(key, 2) + " ship"
			if ship_count > 1:
				ship_desc += "s"
				ship_verb = "occupy"
			else:
				ship_verb = "occupies"
			
			ship_desc += "(" + str(galaxy.calculate_fleet_strength(key, ship_array)) + " fleet strength)"
			ships_desc.append(ship_desc)

	var ships_message: String = ""
	
	if ships_desc.size() > 1:
		ships_message += "\n"
		var index: int = 0
		while index < ships_desc.size() -1:
			
			if index != 0:
				ships_message += ", "
			
			ships_message += ships_desc[index]
			index += 1
		
		if ships_desc.size() > 1:
			ships_message += " and " + ships_desc[index]
		
		ships_message += " contest the system."
	elif ships_desc.size() == 1:
		ships_message += "\n"
		ships_message += ships_desc[0] + " " + ship_verb + " the system."
	
	description += ships_message
	
	return description

func get_starpath(dest_system: StarSystem) -> Array[Vector2]:
	
	var starpath: Array[Vector2]
	
	var small_vec: Vector2 = Vector2.ONE * 0.01
	
	var start_pos: Vector2 = self.gal_pos + small_vec * self.gal_pos.direction_to(dest_system.gal_pos)
	starpath.append(start_pos)
	
	var dest_pos: Vector2 = dest_system.gal_pos + small_vec * dest_system.gal_pos.direction_to(self.gal_pos)
	starpath.append(dest_pos)
	
	starpath.sort()
	
	return starpath

func offset() -> Vector2:
	var rng = RandomNumberGenerator.new()
	rng.set_seed(self.sys_id+53)
	
	return Vector2(rng.randf(), rng.randf()) * 0.7

func set_neighbour(new_neighbour: StarSystem) -> bool:
	
	if not self.is_system_identical(new_neighbour) and not self.is_system_neighbour(new_neighbour):
		self.neighbours.append(new_neighbour)
		new_neighbour.neighbours.append(self)
		return true
	else:
		return false

func is_system_neighbour(possible_neighbour: StarSystem) -> bool:
	
	for system in self.neighbours:
		if system.is_system_identical(possible_neighbour):
			return true
	
	return false

func is_system_identical(other_system: StarSystem) -> bool:
	return self.sys_id == other_system.sys_id
