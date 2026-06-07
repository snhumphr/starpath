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
	place_lab.action_name = "Laboratory Capital"
	place_lab.action_category = "Setup"
	place_lab.is_setup_action = true
	place_lab.is_action_unique = true
	place_lab.reserves_selected_ships = false
	place_lab.system_slots[0].accepts_enemy_system = true
	place_lab.construction_type = StarSystem.CONSTRUCTIONS.LAB
	place_lab.ships_built = 6
	place_lab.short_desc = "Build a Laboratory & 6 ships in 1 system."
	
	empire_setup.append(place_lab)
	
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

	var shipyard_action: BuildAction = BuildAction.new()
	shipyard_action.init()
	shipyard_action.action_name = "Shipyard Construction"
	shipyard_action.action_category = "Industrial"
	shipyard_action.reserves_selected_ships = false
	shipyard_action.construction_type = StarSystem.CONSTRUCTIONS.SHIPYARD
	shipyard_action.ships_built = 0
	shipyard_action.short_desc = "Build a Shipyard in 1 system."
	empire_actions.append(shipyard_action)
	#empire_actions.append(shipyard_action)
	
	var shipbuild_action: BuildAction = BuildAction.new()
	shipbuild_action.init()
	shipbuild_action.action_name = "Vessel Fabrication"
	shipbuild_action.action_category = "Industrial"
	shipbuild_action.reserves_selected_ships = false
	shipbuild_action.system_slots[0].allowed_constructions = [StarSystem.CONSTRUCTIONS.SHIPYARD]
	shipbuild_action.construction_type = StarSystem.CONSTRUCTIONS.SHIPYARD
	shipbuild_action.ships_built = 0
	shipbuild_action.short_desc = "Build 2 ships per Shipyard, half at 1 Shipyard"
	empire_actions.append(shipbuild_action)
	
	var fortress_action: BuildAction = BuildAction.new()
	fortress_action.init()
	fortress_action.action_name = "Fortress Construction"
	fortress_action.action_category = "Military"
	fortress_action.reserves_selected_ships = false
	fortress_action.construction_type = StarSystem.CONSTRUCTIONS.FORTRESS
	fortress_action.ships_built = 2
	fortress_action.short_desc = "Build a Fortress & 2 ships in 1 system."
	empire_actions.append(fortress_action)
	#empire_actions.append(fortress_action)
	
	var deploy_action: MoveAction = MoveAction.new()
	deploy_action.init()
	deploy_action.action_name = "Deploy Ships"
	deploy_action.action_category = "Military"
	deploy_action.system_slots[0].own_ship_maximum = 30
	deploy_action.short_desc = "Move 1-30 ships to/from an adjacent Fortress."
	deploy_action.custom_validity_checks.append(self.deploy_action_check)
	empire_actions.append(deploy_action)
	
	var laboratory_action: BuildAction = BuildAction.new()
	laboratory_action.init()
	laboratory_action.action_name = "Laboratory Construction"
	laboratory_action.action_category = "Research"
	laboratory_action.reserves_selected_ships = false
	laboratory_action.construction_type = StarSystem.CONSTRUCTIONS.LAB
	laboratory_action.ships_built = 0
	laboratory_action.short_desc = "Build a Laboratory in 1 system."
	empire_actions.append(laboratory_action)
	#empire_actions.append(laboratory_action)

	var research_action: FactionAction = FactionAction.new()
	var lab_slot: SystemSlot = SystemSlot.new()
	lab_slot.accepts_enemy_system = false
	lab_slot.accepts_own_system = true
	lab_slot.allowed_constructions = [StarSystem.CONSTRUCTIONS.LAB]
	research_action.system_slots.append(lab_slot)
	research_action.action_name = "Research"
	research_action.action_category = "Research"
	research_action.short_desc = "Gives 1 tech point per owned Lab"
	research_action.custom_execution_actions.append(self.research_execution)
	empire_actions.append(research_action)

	return empire_actions

func research_execution(executing_action: FactionAction, galaxy: Galaxy, selection: ActionSelection, actor_id: int, changes: Array[PackedInt32Array]) -> Array[String]:
	
	var execution_log: Array[String]  = []
	
	var num_labs: int = galaxy.get_constructions_owned_by_player(actor_id)[StarSystem.CONSTRUCTIONS.LAB].size()
	var num_tech_per_lab: int = 1 #TODO: This needs SERIOUS playtesting
	
	var tech_point_change: int =  num_labs * num_tech_per_lab
	
	var own_faction: Faction = galaxy.factions[actor_id]
	var old_tech_level: int = own_faction.calculate_tech_level()
	var tech_change: int = own_faction.increase_tech_points(tech_point_change, false)
	
	var research_change: PackedInt32Array = PackedInt32Array([
		Galaxy.ChangeTypes.RESEARCH, #change type 0
		actor_id, #player id 1
		own_faction.fac_id, #faction id 2
		0, #system id 3
		0, #dest id 4
		tech_point_change, #num ships 5
		StarSystem.CONSTRUCTIONS.EMPTY, #new construction 6
	])
	
	changes.append(research_change)
	
	execution_log.append("    " + "Gained " + str(tech_point_change) + " tech points(" + str(num_labs) + " per owned lab).")
	if tech_change > 0:
		var change_text: String = "    " + "This increased tech level by " + str(tech_change) + ", from " + str(old_tech_level) + " to " + str(old_tech_level+tech_change)
		execution_log.append(change_text)
	else:
		execution_log.append("    " + "However, this was not enough to result in an overall tech level increase.")
	
	return execution_log

func deploy_action_check(checked_action: FactionAction, actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction], is_in_queue: bool) -> String:
	
	var num_fortresses: int = 0
	var systems_selected: int = selection.selected_systems.size()
	
	for system in selection.selected_systems:
		if system.player_id == actor_id and system.construction == StarSystem.CONSTRUCTIONS.FORTRESS:
			num_fortresses += 1
	
	if systems_selected >= 2 and num_fortresses < 1:
		return "Deploy must move to/from at least one friendly fortress construction."
	else:
		return ""
