extends Node

func process_turn(galaxy: Galaxy, actions_dict: Dictionary) -> Galaxy:
	
	var new_galaxy: Galaxy = galaxy.duplicate()
	
	print("Processing turn...")
	
	#TODO: very robust correctness checking on submitted orders
	
	# shipbuilding/construction actions first
	
	# then movement + hostile ship spawning
	
	#combat phase
	
	#systems change ownership here, usually destroying enemy buildings
	
	#once all combats are concluded, handle retreats
	
	#regenerate all faction resources + increase tech levels
	
	if new_galaxy.in_setup:
		new_galaxy.setup_index +=1
		if new_galaxy.setup_index >= new_galaxy.setup_order.size():
			new_galaxy.in_setup = false
	
	if not new_galaxy.in_setup:
		new_galaxy.current_turn += 1
	
	return new_galaxy
