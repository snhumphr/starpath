extends Resource
class_name Faction

enum FACTION_IDS {
	NONE,
	EMPIRE,
	DEVOURER,
	ANCIENTS,
	INTERLOPER
}

const FACTION_NAMES: Dictionary = {
	Faction.FACTION_IDS.NONE: ["a", "minor power", "independent"],
	Faction.FACTION_IDS.EMPIRE: ["the", "Immortal Empire", "Imperial"],
	Faction.FACTION_IDS.DEVOURER: ["the", "Eaters", "Eater"],
	Faction.FACTION_IDS.ANCIENTS: ["the", "Ancients", "Ancient"],
	Faction.FACTION_IDS.INTERLOPER: ["the", "Interlopers", "Interloper"],
}

const TRIANGLE_MULT: int = 3

@export var player_id: int
@export var fac_id: FACTION_IDS
#@export var colour: Color = Color.WHITE

@export var num_actions_per_category: Dictionary = {} #This should contain strings mapped to numbers
@export var tech_points: int = 0
@export var actions: Array[FactionAction]

@export var setup_priority: int = 0  # Ancients -> Empire -> Eaters -> Interlopers
@export var setup_actions: Array[FactionAction]

func calculate_tech_level() -> int:
	
	var tech_level = 0
	
	while self.tech_points > TRIANGLE_MULT * (tech_level +1):
		tech_level += 1
	
	return tech_level 

func increase_tech_points(amount: int) -> int: #Returns the number of tech levels gained from this increase
	
	var old_tech_level: int = self.calculate_tech_level()
	self.tech_points += amount
	var new_tech_level: int = self.calculate_tech_level()
	
	return new_tech_level - old_tech_level
