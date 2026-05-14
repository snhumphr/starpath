extends PopupPanel

func _exit_tree() -> void:
	print("FAREWELL")

func load_turn_report(report: String) -> void:
	
	var label: RichTextLabel = self.get_node("Control/TabContainer/Turn Report/VBoxContainer/MarginContainer/RichTextLabel")
	
	label.set_text("")
	label.append_text(report)
