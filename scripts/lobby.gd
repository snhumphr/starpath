extends Control

func init() -> void:

	#multiplayer = new_multiplayer
	
	print(multiplayer.is_server())
	print(multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func add_player() -> void:
	pass

@rpc("any_peer", "call_local", "reliable")
func set_player(new_faction_id: Faction.FACTION_IDS = Faction.FACTION_IDS.NONE, new_name: String = "", r: float = 99.0, g: float = 99.0, b: float = 99.0) -> void:
	pass
