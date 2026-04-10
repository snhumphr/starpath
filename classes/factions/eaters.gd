extends Faction
class_name Eaters

func init(new_player_id: int) -> void:
	self.player_id = new_player_id
	self.fac_id = Faction.FACTION_IDS.DEVOURER
	self.actions = self.load_actions()
	self.setup_actions = self.load_setup_actions()
	self.setup_priority = 20
	self.tech_points = Faction.TRIANGLE_MULT + 1
	self.num_actions_per_category = {
		"Setup": 1,
		"Basic": 1,
		"Swarm": 4,
	}

func full_description() -> String:
	var description: String = ""
	
	description += "The EATERS" + "\n"
	description += "DIFFICULTY: LOW" + "\n"
	description += "COMBAT STRENGTH: HIGH" + "\n"
	description += "TECHNOLOGY: VERY LOW" + "\n"
	description += "INFRASTRUCTURE: VERY LOW" + "\n"
	description += "\n" + "The EATERS are a vast collective intelligence devoted solely to their own self-propagation."
	description += "\n" + "The more systems they spread to, the more ships they will be able to construct, even without shipyards."
	description += "\n" + "However, they are not without weakness; destroying their central hive will substantially disrupt their logistics."
	description += "\n" + "Finally, their technology only advances when the hive is re-built, as a new intelligence takea command."
	
	return description

func load_setup_actions() -> Array[FactionAction]:
	
	var eater_setup: Array[FactionAction] = []
	
	var place_hive: FactionAction = BuildAction.new()
	place_hive.init()
	place_hive.action_name = "Place Hive"
	place_hive.action_category = "Setup"
	place_hive.is_setup_action = true
	place_hive.is_action_unique = true
	place_hive.reserves_selected_ships = false
	place_hive.system_slots[0].accepts_enemy_system = true
	place_hive.construction_type = StarSystem.CONSTRUCTIONS.FORTRESS
	place_hive.ships_built = 9
	place_hive.short_desc = "Build a Fortress & 9 ships in 1 system."
	
	eater_setup.append(place_hive)
	
	return eater_setup

func load_actions() -> Array[FactionAction]:
	
	var eater_actions: Array[FactionAction] = []
	
	var demolish_action: BuildAction = BuildAction.new()
	demolish_action.init()
	demolish_action.action_name = "Demolish(DEBUG)"
	demolish_action.action_category = "Basic"
	demolish_action.reserves_selected_ships = false
	demolish_action.construction_type = StarSystem.CONSTRUCTIONS.EMPTY
	demolish_action.system_slots[0].allowed_constructions = [StarSystem.CONSTRUCTIONS.FORTRESS, StarSystem.CONSTRUCTIONS.LAB, StarSystem.CONSTRUCTIONS.SHIPYARD]
	#eater_actions.append(demolish_action)
	
	var rebuild_action: BuildAction = BuildAction.new()
	rebuild_action.init()
	rebuild_action.action_name = "Rebuild Hive"
	rebuild_action.action_category = "Basic"
	rebuild_action.reserves_selected_ships = false
	rebuild_action.construction_type = StarSystem.CONSTRUCTIONS.FORTRESS
	rebuild_action.ships_built = 5
	rebuild_action.short_desc = "Build a Fortress, 5 ships and research."
	rebuild_action.custom_validity_checks.append(self.rebuild_action_check)
	rebuild_action.custom_execution_actions.append(self.rebuild_execution)
	eater_actions.append(rebuild_action)
	
	var proliferate_action: BuildAction = BuildAction.new()
	proliferate_action.init()
	proliferate_action.action_name = "Proliferate"
	proliferate_action.action_category = "Basic"
	proliferate_action.reserves_selected_ships = false
	proliferate_action.construction_type = StarSystem.CONSTRUCTIONS.FORTRESS
	proliferate_action.system_slots[0].allowed_constructions = [StarSystem.CONSTRUCTIONS.FORTRESS]
	proliferate_action.ships_built = 1
	proliferate_action.short_desc = "Build 1 ship in owned systems, +1 near Hive."
	proliferate_action.custom_execution_actions.append(self.proliferate_execution)
	eater_actions.append(proliferate_action)
	
	var move_action: MoveAction = MoveAction.new()
	move_action.init()
	move_action.action_category = "Swarm"
	move_action.action_name = "Move"
	move_action.short_desc = "Move 1-9 ships to an adjacent system."
	move_action.custom_validity_checks.append(self.swarm_action_check)
	eater_actions.append(move_action)
	
	var spawn_action: BuildAction = BuildAction.new()
	spawn_action.init()
	spawn_action.action_category = "Swarm"
	spawn_action.action_name = "Spawn"
	spawn_action.short_desc = "Builds 1 ship in an owned empty system."
	spawn_action.ships_built = 1
	spawn_action.custom_validity_checks.append(self.swarm_action_check)
	eater_actions.append(spawn_action)
	
	return eater_actions

func rebuild_execution(executing_action: FactionAction, galaxy: Galaxy, selection: ActionSelection, actor_id: int) -> Array[String]:
	
	var execution_log: Array[String]  = []
	
	var owned_empty_systems: int = galaxy.get_constructions_owned_by_player(actor_id).get(StarSystem.CONSTRUCTIONS.EMPTY, []).size()
	var num_tech_per_system: int = 2 #TODO: This needs SERIOUS playtesting
	
	var tech_point_change: int =  owned_empty_systems * num_tech_per_system
	
	var own_faction: Faction = galaxy.factions[actor_id]
	var old_tech_level: int = own_faction.calculate_tech_level()
	var tech_change: int = own_faction.increase_tech_points(tech_point_change)
	
	execution_log.append("    " + "Gained " + str(tech_point_change) + " tech points(" + str(num_tech_per_system) + " per owned system ")
	if tech_change > 0:
		var change_text: String = "    " + "This increased tech level by " + str(tech_change) + ", from " + str(old_tech_level) + " to " + str(own_faction.calculate_tech_level())
		execution_log.append(change_text)
	else:
		execution_log.append("    " + "However, this was not enough to result in an overall tech level increase.")
	
	return execution_log

func proliferate_execution(executing_action: FactionAction, galaxy: Galaxy, selection: ActionSelection, actor_id: int) -> Array[String]:
	
	var execution_log: Array[String]  = []
	
	var hive_system_id: int = galaxy.get_constructions_owned_by_player(actor_id)[StarSystem.CONSTRUCTIONS.FORTRESS][0]
	var hive_system: StarSystem = galaxy.get_system_from_id(hive_system_id)
	
	for system in galaxy.get_systems_owned_by_player(actor_id):
		var num_ships: int = executing_action.ships_built
		print(num_ships)
		if system.is_system_neighbour(hive_system):
			num_ships += 1
		execution_log.append(executing_action.build_ships(system, galaxy, actor_id, num_ships))
	
	return execution_log

func rebuild_action_check(checked_action: FactionAction, actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction], is_in_queue: bool) -> String:
	
	if galaxy.get_constructions_owned_by_player(actor_id).has(StarSystem.CONSTRUCTIONS.FORTRESS):
		return "Cannot rebuild the hive when one is already active."
		
	return ""

func swarm_action_check(checked_action: FactionAction, actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction], is_in_queue: bool) -> String:
	
	if not galaxy.get_constructions_owned_by_player(actor_id).has(StarSystem.CONSTRUCTIONS.FORTRESS):
		return "Cannot perform a Swarm action without an active hive." #TODO: Consider checking instead if the targeted sectors can trace a path to the hive through friendly territories
	
	for action in action_queue:
		if action.action_category == "Basic" and checked_action.action_category != "Basic":
			return "Cannot perform a Swarm action when a Basic action is queued."
	
	return ""
