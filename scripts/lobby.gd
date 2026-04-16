extends Control

var players: Dictionary
var factions: Dictionary

signal change_player(new_faction_id: Faction.FACTION_IDS, new_name: String, new_colour: Color)

func init(player_name: String, player_colour: Color) -> void:

	#multiplayer = new_multiplayer
	
	print(multiplayer.is_server())
	print(multiplayer.get_unique_id())
	
	self.factions = self.init_factions()
	
	print(multiplayer.get_unique_id() )
	
	if multiplayer.get_unique_id() != 1:
		self.get_node("MarginContainer/HBoxContainer/Lobby/Control/StartButton").set_visible(false)
	
	if not multiplayer.is_server():
		rpc_id(1, "new_player_joined")
	rpc("add_player", player_name, player_colour.r, player_colour.g, player_colour.b)

func init_factions() -> Dictionary:
	
	var new_factions: Dictionary = {}
	
	var eater_faction: Faction = Eaters.new()
	eater_faction.init(0) #TODO: check that this doesn't break anything!
	new_factions[eater_faction.fac_id] = eater_faction
	
	return new_factions

func update_players_column():
	
	get_tree().call_group("player_card", "queue_free")
	
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

func update_faction_display(faction_id: Faction.FACTION_IDS) -> void:
	
	var display_faction: Faction = self.factions[faction_id]
	var display_node: RichTextLabel = self.get_node("MarginContainer/HBoxContainer/Factions/Control/FactionsCol/MarginContainer/FactionText")
	display_node.set_text("")
	display_node.append_text(display_faction.full_description())

@rpc("any_peer", "call_local", "reliable")
func add_player(player_name: String, r: float, g: float, b: float) -> void:
	var new_player: Player = Player.new()
	#var new_player: Dictionary = {}
	new_player.network_id = multiplayer.get_remote_sender_id()
	new_player.player_name = player_name
	new_player.faction_id = self.factions[self.factions.keys()[0]].fac_id
	new_player.colour = Color(r, g, b)
	if not players.has(multiplayer.get_remote_sender_id()):
		self.players[multiplayer.get_remote_sender_id()] = new_player
	else:
		printerr("Tried to add duplicate player")
	self.update_players_column()
	if new_player.network_id == multiplayer.get_unique_id():
		update_faction_display(new_player.faction_id)
	#print(new_player)

@rpc("any_peer", "call_local", "reliable")
func set_player(new_faction_id: Faction.FACTION_IDS = Faction.FACTION_IDS.NONE, new_name: String = "", r: float = 99.0, g: float = 99.0, b: float = 99.0) -> void:
	
	var player: Player = self.players[multiplayer.get_remote_sender_id()]
	
	if new_faction_id != Faction.FACTION_IDS.NONE:
		player.faction_id = new_faction_id
	if new_name != "": #TODO: check that the name isn't already in use before changing this
		player.player_name = new_name 
	if r <= 1.0 and g <= 1.0 and b <= 1.0:
		player.colour = Color(r, g, b)
	self.update_players_column()
	if player.network_id == multiplayer.get_unique_id():
		update_faction_display(player.faction_id)

@rpc("authority", "reliable")
func upload_player(player_dict: Dictionary) -> void:
	
	var new_player: Player = Player.new()
	new_player.network_id = player_dict.network_id
	new_player.faction_id = player_dict.faction_id
	new_player.player_name = player_dict.player_name
	new_player.colour = Color(player_dict.r, player_dict.g, player_dict.b)
	
	self.players[player_dict.network_id] = new_player
	self.update_players_column()

@rpc("any_peer", "reliable")
func new_player_joined() -> void:
	for key in self.players.keys():
		var player: Player = self.players[key]
		var player_dict: Dictionary = {}
		player_dict.network_id = player.network_id
		player_dict.faction_id = player.faction_id
		player_dict.player_name = player.player_name
		player_dict.r = player.colour.r
		player_dict.g = player.colour.g
		player_dict.b = player.colour.b
		rpc_id(multiplayer.get_remote_sender_id(), "upload_player", player_dict)

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	get_tree().call_group("menu", "emit_signal", "start_game", self.players, self.factions)

func _on_change_player(new_faction_id: Faction.FACTION_IDS, new_name: String, r: float, g: float, b: float) -> void:
	rpc.call("set_player", new_faction_id, new_name, r, g ,b)

func _on_start_button_pressed() -> void:
	if multiplayer.get_unique_id() == 1: #check probably not needed, but just in case
		rpc.call("start_game")
