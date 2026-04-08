extends Resource
class_name SystemSlot

#@export var system: StarSystem

@export var accepts_own_system: bool = true
@export var accepts_enemy_system: bool = true
@export var own_ship_minimum: int = 0
@export var own_ship_maximum: int = 9 #TODO: further playtesting needed for ship numbers/ranges

@export var allowed_constructions: Array[StarSystem.CONSTRUCTIONS] = [
	StarSystem.CONSTRUCTIONS.EMPTY,
	StarSystem.CONSTRUCTIONS.SHIPYARD,
	StarSystem.CONSTRUCTIONS.LAB,
	StarSystem.CONSTRUCTIONS.FORTRESS
]

func is_system_valid(galaxy: Galaxy, selection: ActionSelection, index: int, actor_id: int) -> bool:
	
	var faction: Faction = galaxy.factions[actor_id]
	var system: StarSystem = selection.selected_systems[index]
	var ships: int = selection.selected_ships[index]
	
	if not self.accepts_own_system and system.player_id == actor_id:
		print("System not valid because an enemy does not own it.")
		return false
	
	if not self.accepts_enemy_system and system.player_id != actor_id:
		print("System not valid because an enemy owns it.")
		return false
	
	if ships < self.own_ship_minimum:
		print("System not valid because not enough ships selected.")
		return false
	
	if ships > self.own_ship_maximum:
		print("System not valid because too many ships selected.")
		return false
	
	return true
