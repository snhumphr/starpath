extends MarginContainer

var action: FactionAction
var index: int

func init(new_action: FactionAction, action_index: int) -> void:
	self.action = new_action
	self.index = action_index
	
	#print(new_action.bound_action_selection.selected_systems)
	
	self.get_node("PanelContainer/VBoxContainer/HBoxContainer/ActionName").set_text(str(action_index+1) + " " + new_action.action_name)
	
	var selection_desc: String = ""
	var selected_system_ids: PackedStringArray = PackedStringArray([])
	
	for system in self.action.bound_action_selection.selected_systems:
		selected_system_ids.append(str(system.sys_id))
	
	if selected_system_ids.size() > 0:
		selection_desc += "System"
		if selected_system_ids.size() > 1:
			selection_desc += "s"
		selection_desc += " "
		selection_desc += "->".join(selected_system_ids)
	
	self.get_node("PanelContainer/VBoxContainer/ActionDesc").set_text(selection_desc)

func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.is_pressed():
		#print("Action "+ self.action.action_name + " selected!")
		get_tree().call_group("game", "emit_signal", "remove_action_from_queue", self.index)
