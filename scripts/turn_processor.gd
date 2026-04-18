extends Node

var retreat_change: PackedInt32Array = PackedInt32Array([
	Galaxy.ChangeTypes.MOVE_SHIP, #change type
	0, #player id
	0, #faction id
	0, #system id
	0, #dest id
	1, #num ships
	StarSystem.CONSTRUCTIONS.EMPTY, #new construction
])

var destroy_change: PackedInt32Array = PackedInt32Array([
	Galaxy.ChangeTypes.REMOVE_SHIP, #change type
	0, #player id
	0, #faction id
	0, #system id
	0, #dest id
	1, #num ships
	StarSystem.CONSTRUCTIONS.EMPTY, #new construction
])

var raze_change: PackedInt32Array = PackedInt32Array([
	Galaxy.ChangeTypes.CHANGE_CONSTRUCTION, #change type
	0, #player id
	0, #faction id
	0, #system id
	0, #dest id
	0, #num ships
	StarSystem.CONSTRUCTIONS.EMPTY, #new construction
])

var ownership_change: PackedInt32Array = PackedInt32Array([
	Galaxy.ChangeTypes.CHANGE_OWNERSHIP, #change type
	0, #player id
	0, #faction id
	0, #system id
	0, #dest id
	0, #num ships
	StarSystem.CONSTRUCTIONS.EMPTY, #new construction
])

var inc_setup_change: PackedInt32Array = PackedInt32Array([
	Galaxy.ChangeTypes.ADVANCE_SETUP, #change type
	0, #player id
	Faction.FACTION_IDS.NONE, #faction id
	-1, #system id #this is set to -1 as a hack to avoid neutrals not spawning in system #0
	0, #dest id
	0, #num ships
	StarSystem.CONSTRUCTIONS.EMPTY, #new construction
])

const CHANGE_TYPE_INDEX: int = 0
const PLAYER_ID_INDEX: int = 1
const FACTION_ID_INDEX: int = 2
const SYSTEM_ID_INDEX: int = 3
const DEST_ID_INDEX: int = 4
const NUM_SHIPS_INDEX: int = 5

func process_turn(new_galaxy: Galaxy, orders_dict: Dictionary) -> Array[Array]: #index 0 = turn report, index 1 = changes list
	
	print("Processing turn...")
	
	print(orders_dict)
	var actions_dict: Dictionary = {}
	var lowest_priority: int = 100
	var highest_priority: int = -100
	
	for player_id in orders_dict.keys():
		var player_faction: Faction = new_galaxy.factions[player_id]
		var action_list: Array[FactionAction]
		if new_galaxy.in_setup:
			action_list = player_faction.setup_actions
		else:
			action_list = player_faction.actions
		
		print("Processing " + new_galaxy.players[player_id].player_name + "'s turn...")
		var index: int = 0
		for action_id in orders_dict[player_id].action_ids:
			
			for action in action_list:
				if action_id == action.get_action_id():
					lowest_priority = min(lowest_priority, action.action_priority)
					highest_priority = max(highest_priority, action.action_priority)
					var new_action: FactionAction = action.duplicate()
					new_action.bound_action_selection = ActionSelection.new()
					new_action.bound_action_selection.load_selection(new_galaxy, orders_dict[player_id].system_ids[index], orders_dict[player_id].ship_ids[index])
					if not actions_dict.has(player_id):
						var action_array: Array[FactionAction] = [new_action]
						actions_dict[player_id] = action_array
					else:
						actions_dict[player_id].append(new_action)
			index += 1
	
	print("Lowest priority action: " + str(lowest_priority))
	print("Highest priority action: " + str(highest_priority))
	print(actions_dict)
	print("^Actions dict in turn_processor, about to be executed")
	#TODO: CHECK THAT THE ID -> ACTION TRANSFORMATION PROCESS PRESERVES ACTION QUEUE ORDER
	#^wait is the above actually even important. with the priority system + most actions firing simultaneously it shouldn't matter, right
	#TODO: NOTE IF A SUBMITTED ACTION WASN'T PROPERLY CONVERTED INTO A PROCESSED ACTION
	# shipbuilding/construction actions first
	# then movement + hostile ship spawning
	
	var turn_report: Array[String] = []
	var changes: Array[PackedInt32Array] = []
	
	var current_priority: int = lowest_priority
	while current_priority <= highest_priority:
		
		for player_id in actions_dict.keys():
			var action_queue: Array[FactionAction] = actions_dict[player_id]
			for action in action_queue:
				if action.action_priority == current_priority:
					if action.is_action_executable(player_id, new_galaxy, action.bound_action_selection, action_queue):
						turn_report.append(new_galaxy.players[player_id].player_name + " executing action " + action.action_name + ".")
						for entry in action.execute_action(new_galaxy, action.bound_action_selection, player_id, changes):
							turn_report.append(entry)
					else:
						turn_report.append(new_galaxy.players[player_id].player_name + "'s action " + action.action_name + " failed to execute.")
		
		current_priority += 1
	
	var combat_galaxy: Galaxy = new_galaxy.duplicate(true)
	combat_galaxy.apply_changes(changes)
	
	#combat phase
	
	var battlefield_system_ids: Array[int] = []
	var battle_results: Dictionary = {}
	var battle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	battle_rng.randomize()
	
	for system in combat_galaxy.systems:
		var occupying_ships = combat_galaxy.get_ships_in_system(system.sys_id)
		if occupying_ships.keys().size() > 1:
			battlefield_system_ids.append(system.sys_id)
			battle_results[system.sys_id] = self.process_battle(combat_galaxy, system, battle_rng)
	
	print(battle_results)
	
	for sys_id in battle_results.keys():
		var system: StarSystem = combat_galaxy.get_system_from_id(sys_id)
		for player_id in battle_results[sys_id].keys():
			for i in range(0, battle_results[sys_id][player_id].destroyed):
				var new_destroy_change: PackedInt32Array = self.destroy_change.duplicate()
				new_destroy_change[SYSTEM_ID_INDEX] = sys_id
				new_destroy_change[PLAYER_ID_INDEX] = player_id
				changes.append(new_destroy_change)
				combat_galaxy.apply_change(new_destroy_change)
			
			var retreat_system_ids: Array[int] = []
			
			for i in range(0, system.neighbours.size()):
				var neighbour: StarSystem = system.neighbours[i]
				if not battlefield_system_ids.has(neighbour.sys_id) and neighbour.player_id == player_id:
					retreat_system_ids.append(neighbour.sys_id)
			
			var attempted_retreats: int = battle_results[sys_id][player_id].retreating
			for i in range(0, attempted_retreats):
				if i < retreat_system_ids.size():
					var new_retreat_change: PackedInt32Array = self.retreat_change.duplicate()
					new_retreat_change[SYSTEM_ID_INDEX] = sys_id
					new_retreat_change[PLAYER_ID_INDEX] = player_id
					new_retreat_change[DEST_ID_INDEX] = retreat_system_ids[i]
					changes.append(new_retreat_change)
					combat_galaxy.apply_change(new_retreat_change)
					if not battle_results[sys_id][player_id].has("retreat_systems"):
						battle_results[sys_id][player_id].retreat_systems = []
					battle_results[sys_id][player_id].retreat_systems.append(retreat_system_ids[i])
				else:
					var new_destroy_change: PackedInt32Array = self.destroy_change.duplicate()
					new_destroy_change[SYSTEM_ID_INDEX] = sys_id
					new_destroy_change[PLAYER_ID_INDEX] = player_id
					changes.append(new_destroy_change)
					combat_galaxy.apply_change(new_destroy_change)
					battle_results[sys_id][player_id].retreating -= 1
					battle_results[sys_id][player_id].destroyed += 1
			
		turn_report += self.generate_battle_log(combat_galaxy, sys_id, battle_results[sys_id])
	
	#systems change ownership here, usually destroying enemy buildings
	for system in combat_galaxy.systems:
		var occupying_ships = combat_galaxy.get_ships_in_system(system.sys_id)
		if occupying_ships.keys().size() == 1: #TODO: make hidden ships not count for this
			var occupier_id: int = occupying_ships.keys()[0]
			if system.player_id != occupier_id:
				print("awoo")
				var new_ownership_change: PackedInt32Array = ownership_change.duplicate()
				new_ownership_change[SYSTEM_ID_INDEX] = system.sys_id
				new_ownership_change[PLAYER_ID_INDEX] = occupier_id
				new_ownership_change[FACTION_ID_INDEX] = combat_galaxy.players[occupier_id].faction_id
				changes.append(new_ownership_change)
				turn_report.append(combat_galaxy.players[occupier_id].player_name + " now occupies " + system.get_system_name() + ".")
				if combat_galaxy.in_setup == false and system.construction != StarSystem.CONSTRUCTIONS.EMPTY:
					system.construction = StarSystem.CONSTRUCTIONS.EMPTY
					var new_raze_change: PackedInt32Array = raze_change.duplicate()
					new_raze_change[SYSTEM_ID_INDEX] = system.sys_id
					changes.append(new_raze_change)
					turn_report.append("The construction present at " + system.get_system_name() + " was destroyed in the process.")
	
	#regenerate all faction resources + increase tech levels
	
	if combat_galaxy.in_setup:
		changes.append(self.inc_setup_change)
	
	var results: Array[Array] = [changes, turn_report]
	
	return results

func generate_battle_log(galaxy: Galaxy, sys_id: int, battle_report: Dictionary) -> Array[String]:
	
	var final_battle_log: Array[String] = []
	var combatant_names: PackedStringArray = PackedStringArray([])
	var victor_name: String = ""
	
	for player_id in battle_report.keys():
		combatant_names.append(galaxy.get_faction_name(player_id, 0) + " " + galaxy.get_faction_name(player_id, 1))
		if battle_report[player_id].victorious:
			victor_name = galaxy.get_faction_name(player_id, 1)
	
	var battle_log_intro: String = "A battle occurred in the " + galaxy.get_system_from_id(sys_id).get_system_name() + " system between "
	
	var combatants_message: String = ""
	var index: int = 0
	while index < battle_report.size() -1:
			
		if index != 0:
			combatants_message += ", "
		
		var player_id: int = battle_report.keys()[index]
		combatants_message += galaxy.get_faction_name(player_id, 0) + " " + galaxy.get_faction_name(player_id, 1)
		index += 1
	
	combatants_message += " and " + galaxy.get_faction_name(battle_report.keys()[index], 0) + " " + galaxy.get_faction_name(battle_report.keys()[index], 1)
	battle_log_intro += combatants_message
	
	final_battle_log.append(battle_log_intro)
	final_battle_log.append("    " + "The " + victor_name + " were victorious.")
	
	for player_id in battle_report.keys():
		if battle_report[player_id].victorious:
			final_battle_log.append("    " + self.generate_casualty_report(galaxy, battle_report[player_id], player_id))
	
	for player_id in battle_report.keys():
		if not battle_report[player_id].victorious:
			final_battle_log.append("    " + self.generate_casualty_report(galaxy, battle_report[player_id], player_id))
	
	return final_battle_log

func generate_casualty_report(galaxy: Galaxy, battle_report: Dictionary, player_id: int) -> String: #note that the battle report here should be only 1 player's report
	
	var report: String = ""
	
	print(battle_report)
	if battle_report.destroyed > 0 or battle_report.retreating > 0:
		report = "$destroyed $faction ship$ds $were destroyed and $retreated $faction ship$rs fled"
		if battle_report.retreat_systems.size() > 0:
			report += " to "
			var retreat_message: String = ""
			var index: int = 0
			while index < battle_report.retreat_systems.size() -1:
			
				if index != 0:
					retreat_message += ", "
		
				retreat_message += galaxy.get_system_from_id(battle_report.retreat_systems[index]).get_system_name()
				index += 1
			if battle_report.retreat_systems.size() > 1:
				retreat_message += " and "
			retreat_message += galaxy.get_system_from_id(battle_report.retreat_systems[index]).get_system_name()
			report += retreat_message + "."
		else:
			report += "."
		
		var format_dict: Dictionary = {
			"$destroyed": "No",
			"$retreated": "no",
			"$were": "were",
			"$ds": "s",
			"$rs": "s",
		}
		
		format_dict["$faction"] = Faction.FACTION_NAMES[galaxy.factions[player_id].fac_id][2]
		
		if battle_report.destroyed > 0:
			format_dict["$destroyed"] = str(battle_report.destroyed)
			if battle_report.destroyed == 1:
				format_dict["$were"] = "was"
				format_dict["$ds"] = ""
		
		if battle_report.retreating > 0:
			format_dict["$retreated"] = str(battle_report.retreating)
			if battle_report.retreating == 1:
				format_dict["$rs"] = ""
		
		report = report.format(format_dict, "_")
		
	else:
		report = "They suffered no losses."
	
	return report

func process_battle(galaxy: Galaxy, system: StarSystem, battle_rng: RandomNumberGenerator) -> Dictionary:
	
	var victor_ids: Array[int] = []
	var highest_fleet_strength: int = 0
	var combatant_ships: Dictionary = galaxy.get_ships_in_system(system.sys_id) #TODO: account for stealthed ships
	
	for player_id in combatant_ships.keys():
		var ships_array: Array[Ship] = []
		for ship in combatant_ships[player_id]:
			ships_array.append(ship)
		var fleet_strength: int = galaxy.calculate_fleet_strength(player_id, ships_array)
		if fleet_strength > highest_fleet_strength:
			highest_fleet_strength = fleet_strength
			victor_ids = [player_id]
		elif fleet_strength == highest_fleet_strength:
			victor_ids.append(player_id)
	
	var victor_index: int = battle_rng.randi() % victor_ids.size()
	var victor_id: int = victor_ids[victor_index]
	
	var results_dict: Dictionary = {}
	
	for player_id in combatant_ships.keys():
		var num_ships = combatant_ships[player_id].size()
		var num_retreating: int = 0
		var num_destroyed: int = 0
		if player_id != victor_id:
			num_destroyed = ceili(num_ships / 2.0)
			num_retreating = num_ships - num_destroyed
		results_dict[player_id] = {}
		results_dict[player_id].retreating = num_retreating
		results_dict[player_id].destroyed = num_destroyed
		results_dict[player_id].victorious = false
	
	var losers_destroyed: int = 0
	for player_id in results_dict.keys():
		losers_destroyed += results_dict[player_id].destroyed
	
	var winning_ships = combatant_ships[victor_index].size()
	var casualties: int = floori(losers_destroyed / 2.0)
	results_dict[victor_id].retreating = ceili(casualties / 2.0)
	results_dict[victor_id].destroyed = casualties - results_dict[victor_index].retreating
	results_dict[victor_id].victorious = true
	
	return results_dict
