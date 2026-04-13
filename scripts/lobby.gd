extends Control

var players: Array[Player]

func init(player_name: String, player_colour: Color) -> void:

	#multiplayer = new_multiplayer
	
	print(multiplayer.is_server())
	print(multiplayer.get_unique_id())
	
	rpc("add_player", player_name, player_colour.r, player_colour.g, player_colour.b)

func update_players_column():
	
	for player in players:
		if player.network_id == multiplayer.get_unique_id():
			pass
		else:
			pass

@rpc("any_peer", "call_local", "reliable")
func add_player(player_name: String, r: float, g: float, b: float) -> void:
	var new_player: Player = Player.new()
	#var new_player: Dictionary = {}
	new_player.network_id = multiplayer.get_remote_sender_id()
	new_player.player_id = self.players.size() +1 #TODO: MAKE ABSOLUTELY SURE THAT ALL PLAYER IDS ARE CONSISTENT!!!!
	new_player.player_name = player_name
	new_player.faction_id = Faction.FACTION_IDS.NONE
	new_player.colour = Color(r, g, b)
	self.players.append(new_player)
	self.update_players_column()
	#print(new_player)

@rpc("any_peer", "call_local", "reliable")
func set_player(player_id: int, new_faction_id: Faction.FACTION_IDS = Faction.FACTION_IDS.NONE, new_name: String = "", r: float = 99.0, g: float = 99.0, b: float = 99.0) -> void:
	
	var player: Player = self.players[player_id-1]
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	if sender_id == player.network_id:
		if new_faction_id != Faction.FACTION_IDS.NONE:
			player.faction_id = new_faction_id
		if new_name != "": #TODO: check that the name isn't already in use before changing this
			player.new_name = new_name 
		if r < 1.0 and g < 1.0 and b < 1.0:
			player.colour = Color(r, g, b)
		self.update_players_column()
	else:
		printerr(" wrong network id used to modify player")
