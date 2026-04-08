extends MarginContainer

var action: FactionAction
var is_clickable: bool
var is_selected: bool = false

func init(new_action: FactionAction, new_clickability: bool = true) -> void:
	
	self.action = new_action
	self.is_clickable = new_clickability
	print(self.action.action_name)
	
	self.adjust_display_theme()
	
	self.get_node("PanelContainer/VBoxContainer/HBoxContainer/ActionName").set_text(self.action.action_name)
	self.get_node("PanelContainer/VBoxContainer/ActionDesc").set_text(self.action.short_desc)

func adjust_display_theme() -> void:
	
	var stylebox: StyleBoxFlat = preload("res://assets/panels/blackwhite.tres").duplicate()
	
	if self.is_selected:
		stylebox = preload("res://assets/panels/blackyellow.tres").duplicate()
	elif not self.is_clickable:
		stylebox = preload("res://assets/panels/blackgrey.tres").duplicate()
	
	self.get_node("PanelContainer").add_theme_stylebox_override("panel", stylebox)

func _gui_input(event: InputEvent) -> void:
	
	if self.is_clickable and event is InputEventMouseButton and event.is_pressed():
		#print("Action "+ self.action.action_name + " selected!")
		get_tree().call_group("game", "emit_signal", "change_current_action", self.action)
		#self.is_selected = true
		#self.adjust_display_theme()
