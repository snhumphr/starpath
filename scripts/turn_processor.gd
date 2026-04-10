extends Node

func process_turn(old_galaxy: Galaxy, orders_dict: Dictionary) -> Galaxy:
	
	var new_galaxy: Galaxy = old_galaxy.duplicate()
	
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
	
	var current_priority: int = lowest_priority
	while current_priority <= highest_priority:
		
		for player_id in actions_dict.keys():
			var action_queue: Array[FactionAction] = actions_dict[player_id]
			for action in action_queue:
				if action.action_priority == current_priority:
					if action.is_action_executable(player_id, new_galaxy, action.bound_action_selection, action_queue):
						turn_report.append(new_galaxy.players[player_id].player_name + " executing action " + action.action_name + ".")
						for entry in action.execute_action(new_galaxy, action.bound_action_selection, player_id):
							turn_report.append(entry)
					else:
						turn_report.append(new_galaxy.players[player_id].player_name + "'s action " + action.action_name + " failed to execute.")
		
		current_priority += 1
	
	#combat phase
	
	var battlefield_system_ids: Array[int] = []
	var battle_results: Dictionary = {}
	var battle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	battle_rng.randomize()
	
	for system in new_galaxy.systems:
		var occupying_ships = new_galaxy.get_ships_in_system(system.sys_id)
		if occupying_ships.keys().size() > 1:
			battlefield_system_ids.append(system.sys_id)
			battle_results[system.sys_id] = self.process_battle(new_galaxy, system, battle_rng)
	
	print(battle_results)
	
	for sys_id in battle_results.keys():
		var system: StarSystem = new_galaxy.get_system_from_id(sys_id)
		for player_id in battle_results[sys_id].keys():
			for i in range(0, battle_results[sys_id][player_id].destroyed):
				new_galaxy.destroy_ship(sys_id, player_id)
			
			var retreat_system_ids: Array[int] = []
			
			for i in range(0, system.neighbours.size()):
				var neighbour: StarSystem = system.neighbours[i]
				if not battlefield_system_ids.has(neighbour.sys_id) and neighbour.player_id == player_id:
					retreat_system_ids.append(neighbour.sys_id)
			
			for i in range(0, battle_results[sys_id][player_id].retreating):
				if i < retreat_system_ids.size():
					new_galaxy.move_ship(sys_id, player_id, retreat_system_ids[i])
					print("voyote vowel")
				else:
					new_galaxy.destroy_ship(sys_id, player_id)
	
	#TODO: make a nice neat battle log for the turn report!
	
	#systems change ownership here, usually destroying enemy buildings
	for system in new_galaxy.systems:
		var occupying_ships = new_galaxy.get_ships_in_system(system.sys_id)
		if occupying_ships.keys().size() == 1: #TODO: make hidden ships not count for this
			var occupier_id: int = occupying_ships.keys()[0]
			if system.player_id != occupier_id:
				system.player_id = occupier_id
				system.faction_id = new_galaxy.players[occupier_id].faction_id
				turn_report.append(new_galaxy.players[occupier_id].player_name + " now occupies " + system.get_system_name() + ".")
				if new_galaxy.in_setup == false and system.construction != StarSystem.CONSTRUCTIONS.EMPTY:
					system.construction = StarSystem.CONSTRUCTIONS.EMPTY
					turn_report.append("The construction present at " + system.get_system_name() + " was destroyed in the process.")
	
	#once all combats are concluded, handle retreats
	
	#regenerate all faction resources + increase tech levels
	
	print(turn_report)
	
	if new_galaxy.in_setup:
		new_galaxy.setup_index +=1
		if new_galaxy.setup_index >= new_galaxy.setup_order.size():
			new_galaxy.in_setup = false
	
	if not new_galaxy.in_setup:
		new_galaxy.current_turn += 1
	
	return new_galaxy

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
	
	var num_ships = combatant_ships[victor_index].size()
	var casualties: int = floori(losers_destroyed / 2.0)
	results_dict[victor_id].retreating = ceili(casualties / 2.0)
	results_dict[victor_id].destroyed = casualties - results_dict[victor_index].retreating
	results_dict[victor_id].victorious = true
	
	return results_dict
