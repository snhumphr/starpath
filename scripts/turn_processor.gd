extends Node

func process_turn(old_galaxy: Galaxy, orders_dict: Dictionary) -> Galaxy:
	
	var new_galaxy: Galaxy = old_galaxy.duplicate()
	
	print("Processing turn...")
	
	#TODO: very robust correctness checking on submitted orders
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
				if action.is_action_executable(player_id, new_galaxy, action.bound_action_selection, action_queue):
					turn_report.append(new_galaxy.players[player_id].player_name + " executing action " + action.action_name + ".")
					for entry in action.execute_action(new_galaxy, action.bound_action_selection, player_id):
						turn_report.append(entry)
				else:
					turn_report.append(new_galaxy.players[player_id].player_name + "'s action " + action.action_name + " failed to execute.")
		
		current_priority += 1
	
	#combat phase
	
	#systems change ownership here, usually destroying enemy buildings
	for system in new_galaxy.systems:
		var occupying_ships = new_galaxy.get_ships_in_system(system.sys_id)
		if occupying_ships.keys().size() == 1: #TODO: make hidden ships not count for this
			var occupier_id: int = occupying_ships.keys()[0]
			if system.player_id != occupier_id:
				system.player_id = occupier_id
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
