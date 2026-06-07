extends Faction
class_name Empire

func init(new_player_id: int) -> void:
	self.player_id = new_player_id
	self.fac_id = Faction.FACTION_IDS.EMPIRE
	self.actions = self.load_actions()
	self.setup_actions = self.load_setup_actions()
	self.setup_priority = 10
	self.tech_points = Faction.TRIANGLE_MULT + 1
	self.num_actions_per_category = {
		"Setup": 1,
		"Basic": 3,
		"Military": 1,
		"Industrial": 1,
		"Research": 1,
	}

func full_description() -> String:
	var description: String = ""
	
	description += "The IMMORTAL EMPIRE" + "\n"
	description += "DIFFICULTY: MODERATE" + "\n"
	description += "COMBAT STRENGTH: MODERATE" + "\n"
	description += "TECHNOLOGY: MODERATE" + "\n"
	description += "INFRASTRUCTURE: HIGH" + "\n"
	description += "\n" + "The IMMORTAL EMPIRE is a union of countless rich worlds, only recently united under a powerful monarchy."
	description += "\n" + "Their fleets have no especial advantages to begin with, but as the EMPIRE grows they become more powerful and numerous."
	description += "\n" + "The hallmark expansionism of the EMPIRE is also it's weakness; Starved of systems, they will be unable to contest anything."
	description += "\n" + "However, IMPERIAL ambition is boundless; If they are not stopped quickly, their technological edge can easily become insurmountable."
	
	return description


func load_setup_actions() -> Array[FactionAction]:
	
	var empire_setup: Array[FactionAction] = []
	
	var place_fort: FactionAction = BuildAction.new()
	place_fort.init()
	place_fort.action_name = "Fortress Capital"
	place_fort.action_category = "Setup"
	place_fort.is_setup_action = true
	place_fort.is_action_unique = true
	place_fort.reserves_selected_ships = false
	place_fort.system_slots[0].accepts_enemy_system = true
	place_fort.construction_type = StarSystem.CONSTRUCTIONS.FORTRESS
	place_fort.ships_built = 8
	place_fort.short_desc = "Build a Fortress & 8 ships in 1 system."
	
	empire_setup.append(place_fort)
	
	var place_yard: FactionAction = BuildAction.new()
	place_yard.init()
	place_yard.action_name = "Shipyard Capital"
	place_yard.action_category = "Setup"
	place_yard.is_setup_action = true
	place_yard.is_action_unique = true
	place_yard.reserves_selected_ships = false
	place_yard.system_slots[0].accepts_enemy_system = true
	place_yard.construction_type = StarSystem.CONSTRUCTIONS.SHIPYARD
	place_yard.ships_built = 6
	place_yard.short_desc = "Build a Shipyard & 6 ships in 1 system."
	
	empire_setup.append(place_yard)
	
	var place_lab: FactionAction = BuildAction.new()
	place_lab.init()
	place_lab.action_name = "Shipyard Capital"
	place_lab.action_category = "Setup"
	place_lab.is_setup_action = true
	place_lab.is_action_unique = true
	place_lab.reserves_selected_ships = false
	place_lab.system_slots[0].accepts_enemy_system = true
	place_lab.construction_type = StarSystem.CONSTRUCTIONS.SHIPYARD
	place_lab.ships_built = 6
	place_lab.short_desc = "Build a Laboratory & 6 ships in 1 system."
	
	empire_setup.append(place_yard)
	
	return empire_setup

func load_actions() -> Array[FactionAction]:
	
	var empire_actions: Array[FactionAction] = []
	
	var demolish_action: BuildAction = BuildAction.new()
	demolish_action.init()
	demolish_action.action_name = "Unbuild"
	demolish_action.action_category = "Basic"
	demolish_action.short_desc = "Removes an owned construction."
	demolish_action.reserves_selected_ships = false
	demolish_action.construction_type = StarSystem.CONSTRUCTIONS.EMPTY
	demolish_action.system_slots[0].allowed_constructions = [StarSystem.CONSTRUCTIONS.FORTRESS, StarSystem.CONSTRUCTIONS.LAB, StarSystem.CONSTRUCTIONS.SHIPYARD]
	empire_actions.append(demolish_action)

	var move_action: MoveAction = MoveAction.new()
	move_action.init()
	move_action.system_slots[0].own_ship_maximum = 6
	move_action.action_category = "Basic"
	move_action.action_name = "Move"
	move_action.short_desc = "Move 1-6 ships to an adjacent system."
	empire_actions.append(move_action)

	return empire_actions

# basic actions(x3):
# move 6 ships Move
# demolish a building Unbuild

# industrial actions
# build a shipyard Shipyard Construction
# build 1 ship at each shipyard, and then 1 ship per constructed shipyard at the selected shipyard Vessel Fabrication

# military actions
# build a fortress + 2 ships Fortress Construction
# move 30 ships to or from a friendly fortress Deploy

# research actions:
# build a lab Laboratory Construction
# research 1 tech point for each lab Research
