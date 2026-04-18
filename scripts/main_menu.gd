extends Control

var current_profile: Dictionary
@onready var JoinRow: PanelContainer = self.get_node("MenuBar/VBoxContainer/JoinRow")
@onready var ProfileBox: PanelContainer = self.get_node("MenuBar/ProfileBox")
@onready var Lobby: Control = self.get_node("Lobby")

const PORT: int = 7653
const PROFILE_PATH = "user://profile.json"
const JOIN_IP_PATH = "user://joinip.txt"
var host_IP: String
var join_IP: String

signal start_game(players: Dictionary)

func _ready() -> void:
	
	#load profile from disk, if one exists
	await get_tree().process_frame
	self.current_profile = self.load_profile_from_disk()
	
	if OS.has_feature("windows"):
		self.host_IP = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)
	else: #This needs testing on non-windows devices
		self.host_IP = IP.get_local_addresses()[0] #TODO: likely needs serious filtering
	self.host_IP = "localhost" #TESTING ONLY
		
	print("HOST IP: " + self.host_IP)
		
	if FileAccess.file_exists(JOIN_IP_PATH):
		var file = FileAccess.open(JOIN_IP_PATH, FileAccess.READ)
		var file_text: String = file.get_as_text()
		file.close()
		file_text = file_text.strip_edges()
		self.JoinRow.get_node("MarginContainer/HBoxContainer/LineEdit").set_text(file_text)

func get_profile_from_box() -> Dictionary:
	
	var profile_dict: Dictionary = {}
	profile_dict.name = self.ProfileBox.get_node("VBoxContainer/NameRow/LineEdit").get_text()
	profile_dict.colour = self.ProfileBox.get_node("VBoxContainer/ColourRow/ColourButton").get_pick_color()
	
	return profile_dict

func load_profile_from_disk() -> Dictionary:
	var profile: Dictionary = {}
	
	if FileAccess.file_exists(PROFILE_PATH):
		var file = FileAccess.open(PROFILE_PATH, FileAccess.READ)
		var file_text: String = file.get_as_text()
		var file_dict = JSON.parse_string(file_text)
		file.close()
		profile = file_dict
	
	if profile.keys().size() > 0:
		self.ProfileBox.get_node("VBoxContainer/NameRow/LineEdit").set_text(profile.name)
		var colour_list: PackedStringArray = profile.colour.format({"(":"", ")":""}, "_").split(", ")
		var colour: Color = Color(float(colour_list[0]), float(colour_list[1]), float(colour_list[2]))
		self.ProfileBox.get_node("VBoxContainer/ColourRow/ColourButton").color = colour
	
	return profile

func swap_to_lobby() -> void:
	
	self.get_node("MenuBar").set_visible(false)
	self.Lobby.set_visible(true)
	current_profile.colour = str(current_profile.colour)
	print(current_profile)
	var colour_list: PackedStringArray = self.current_profile.colour.format({"(":"", ")":""}, "_").split(", ")
	self.Lobby.init(self.current_profile.name, Color(float(colour_list[0]), float(colour_list[1]), float(colour_list[2])))

func _on_save_button_pressed() -> void:
	
	#load the profile from the profile box to current_profile
	self.current_profile = self.get_profile_from_box()

	#then try to save profile to disk
	var file = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	var json_string: String = JSON.stringify(self.current_profile)
	file.store_string(json_string)
	file.close()

func _on_join_button_pressed() -> void:
	
	self.join_IP = self.JoinRow.get_node("MarginContainer/HBoxContainer/LineEdit").get_text()
	self.join_IP = self.join_IP.strip_edges()
	print(self.join_IP)
	
	if self.join_IP != "":
		var file = FileAccess.open(JOIN_IP_PATH, FileAccess.WRITE)
		file.store_string(self.join_IP)
		
		var peer = ENetMultiplayerPeer.new()
		var error: int = peer.create_client(self.join_IP, PORT)
		multiplayer.multiplayer_peer = peer
		for i in range(0, 60):
			await get_tree().process_frame
		self.swap_to_lobby()

func _on_host_button_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var max_connections: int = 6 #TODO: placeholder value; not sure if 6 players works properly right now
	peer.create_server(PORT, max_connections)
	multiplayer.multiplayer_peer = peer
	self.swap_to_lobby()

func _on_start_game(players: Dictionary, factions: Dictionary) -> void:
	var game_node: Control = self.get_node("Game")
	self.get_node("MenuBar").set_visible(false)
	self.get_node("Lobby").set_visible(false)
	game_node.set_visible(true)
	game_node.start_game(players, factions)
