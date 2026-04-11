extends RichTextLabel

func _make_custom_tooltip(for_text: String) -> Object:
	
	if for_text == "":
		return null
	
	var tooltip_scene = load("res://scenes/tooltip.tscn")
	var instance = tooltip_scene.instantiate()
	instance.get_node("ToolTipText").set_text(for_text)
	
	return instance
