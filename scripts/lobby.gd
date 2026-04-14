extends Control

var players: Dictionary
var factions: Array[Faction]

func init(player_name: String, player_colour: Color) -> void:

	#multiplayer = new_multiplayer
	
	print(multiplayer.is_server())
	print(multiplayer.get_unique_id())
	
	self.factions = self.init_factions()
	
	rpc("add_player", player_name, player_colour.r, player_colour.g, player_colour.b)

func init_factions() -> Array[Faction]:
	
	var new_factions: Array[Faction] = []
	
	var eater_faction: Faction = Eaters.new()
	eater_faction.init(0) #TODO: check that this doesn't break anything!
	new_factions.append(eater_faction)
	
	return new_factions

func update_players_column():
	
	for key in players.keys():
		var player: Player = players[key]
		if key == multiplayer.get_unique_id():
			self.add_player_card(player, true)
		else:
			self.add_player_card(player, false)

func add_player_card(player: Player, editing_allowed: bool = false) -> void:
	var card_scene = load("res://scenes/player_card.tscn")
	var instance = card_scene.instantiate()
	instance.init(player, self.factions, editing_allowed)
	self.get_node("MarginContainer/HBoxContainer/Lobby/Control/PlayersCol").add_child(instance)

@rpc("any_peer", "call_local", "reliable")
func add_player(player_name: String, r: float, g: float, b: float) -> void:
	var new_player: Player = Player.new()
	#var new_player: Dictionary = {}
	new_player.network_id = multiplayer.get_remote_sender_id()
	new_player.player_name = player_name
	new_player.faction_id = self.factions[0].fac_id
	new_player.colour = Color(r, g, b)
	if not players.has(multiplayer.get_remote_sender_id()):
		self.players[multiplayer.get_remote_sender_id()] = new_player
	else:
		printerr("Tried to add duplicate player")
	self.update_players_column()
	#print(new_player)

@rpc("any_peer", "call_local", "reliable")
func set_player(new_faction_id: Faction.FACTION_IDS = Faction.FACTION_IDS.NONE, new_name: String = "", r: float = 99.0, g: float = 99.0, b: float = 99.0) -> void:
	
	var player: Player = self.players[multiplayer.get_remote_sender_id()]
	
	if new_faction_id != Faction.FACTION_IDS.NONE:
		player.faction_id = new_faction_id
	if new_name != "": #TODO: check that the name isn't already in use before changing this
		player.new_name = new_name 
	if r < 1.0 and g < 1.0 and b < 1.0:
		player.colour = Color(r, g, b)
	self.update_players_column()
