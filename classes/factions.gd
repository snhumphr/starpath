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

@export var player_id: int
@export var fac_id: FACTION_IDS
@export var colour: Color = Color.WHITE

@export var num_actions_per_category: Dictionary = {} #This should contain strings mapped to numbers
@export var resources: Array[FactionResource]
@export var actions: Array[FactionAction]

@export var setup_priority: int = 0  # Ancients -> Empire -> Eaters -> Interlopers
@export var setup_actions: Array[FactionAction]
