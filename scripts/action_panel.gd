extends PanelContainer

#const ActionButton: PackedScene = preload("res://scenes/action_button.tscn")

func init(galaxy: Galaxy) -> void:
	
	var played_faction: Faction = galaxy.factions[galaxy.player_id]
	
	var actions_dict: Dictionary = {}
	
	if galaxy.in_setup:
		for action in played_faction.setup_actions:
			if not actions_dict.has(action.action_category):
				actions_dict[action.action_category] = []
			
			actions_dict[action.action_category].append(action)
	else:
		for action in played_faction.actions:
			
			if not actions_dict.has(action.action_category):
				actions_dict[action.action_category] = []
			
			actions_dict[action.action_category].append(action)
	
	get_tree().call_group("action_button", "queue_free")
	
	print(actions_dict)
	
	for key in actions_dict.keys():
		#TODO: sort the actions here
		
		var label: Label = Label.new()
		label.set_text(key + " Actions " + str(played_faction.num_actions_per_category[key]) + "/turn") 
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_to_group("action_button")
		self.get_node("VBoxContainer").add_child(label)
		
		for i in range(0, actions_dict[key].size()):
			var button_scene = load("res://scenes/action_button.tscn")
			var instance = button_scene.instantiate()
			instance.init(actions_dict[key][i])
			self.get_node("VBoxContainer").add_child(instance)
			#await get_tree().process_frame
