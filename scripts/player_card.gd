extends MarginContainer

const default_faction_id: Faction.FACTION_IDS = Faction.FACTION_IDS.NONE
const default_name: String = ""
const default_colour: float = 99.0

func init(player: Player, factions: Dictionary, editing_allowed: bool) -> void:
	
	var name_row: Node = self.get_node("PanelContainer/VBoxContainer/NameRow")
	var colour_row: Node = self.get_node("PanelContainer/VBoxContainer/ColourRow")
	var faction_row: Node = self.get_node("PanelContainer/VBoxContainer/FactionRow")
	
	colour_row.get_node("ColourButton").color = player.colour
	name_row.get_node("NameEdit").set_text(player.player_name)
	
	var faction_button: OptionButton = faction_row.get_node("FactionButton")
	
	for key in factions.keys():
		var faction: Faction = factions[key]
		faction_button.add_item(Faction.FACTION_NAMES[faction.fac_id][1], faction.fac_id)
	
	faction_button.select(faction_button.get_item_index(player.faction_id))
	
	if not editing_allowed:
		colour_row.get_node("ColourButton").set_disabled(true)
		name_row.get_node("NameEdit").set_editable(false)
		faction_button.set_disabled(true)

# on_change_player(new_faction_id: Faction.FACTION_IDS, new_name: String, r: float, g: float, b: float)

func _on_name_edit_text_submitted(new_text: String) -> void:
	get_tree().call_group("lobby", "emit_signal", "change_player", self.default_faction_id, new_text, self.default_colour, self.default_colour, self.default_colour)

func _on_colour_button_popup_closed() -> void:
	var colour_button: ColorPickerButton = self.get_node("PanelContainer/VBoxContainer/ColourRow/ColourButton")
	var color: Color = colour_button.get_pick_color()
	print([color.r, color.g, color.b])
	get_tree().call_group("lobby", "emit_signal", "change_player", self.default_faction_id, self.default_name, color.r, color.g, color.b)

func _on_faction_button_item_selected(index: int) -> void:
	var faction_button: OptionButton = self.get_node("PanelContainer/VBoxContainer/FactionRow/FactionButton")
	get_tree().call_group("lobby", "emit_signal", "change_player", faction_button.get_item_id(index), self.default_name, self.default_colour, self.default_colour, self.default_colour)
