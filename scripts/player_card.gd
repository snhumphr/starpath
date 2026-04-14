extends MarginContainer

func init(player: Player, factions: Array[Faction], editing_allowed: bool) -> void:
	
	var name_row: Node = self.get_node("PanelContainer/VBoxContainer/NameRow")
	var colour_row: Node = self.get_node("PanelContainer/VBoxContainer/ColourRow")
	var faction_row: Node = self.get_node("PanelContainer/VBoxContainer/FactionRow")
	
	colour_row.get_node("ColourButton").color = player.colour
	name_row.get_node("NameEdit").set_text(player.player_name)
	
	var faction_button: OptionButton = faction_row.get_node("FactionButton")
	
	for i in range(factions.size()):
		var faction: Faction = factions[i]
		faction_button.add_item(Faction.FACTION_NAMES[faction.fac_id][1], faction.fac_id)
	
	faction_button.select(faction_button.get_item_index(player.faction_id))
	
	if not editing_allowed:
		colour_row.get_node("ColourButton").set_disabled(true)
		name_row.get_node("NameEdit").set_editable(false)
		faction_button.set_disabled(true)
		
