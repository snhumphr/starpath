extends Control

@onready var MapFrame: Control = self.get_node("GameBox/MainScreen/MapBox/MapFrame")
@onready var GalaxyGen: Node = self.get_node("Panel/GalaxyGen")
@onready var TurnProcessor: Node = self.get_node("Panel/TurnProcessor")
@onready var LeftDesc: Label = self.get_node("GameBox/BottomBar/LeftDesc")
@onready var FactionsDesc: RichTextLabel = self.get_node("GameBox/BottomBar/FactionsDesc")
@onready var ActionPanel: PanelContainer = self.get_node("GameBox/MainScreen/VBoxContainer/ActionPanel")
@onready var ActionQueue: VBoxContainer = self.get_node("GameBox/MainScreen/VBoxContainer/QueuePanel/ActionQueue")

var galaxy: Galaxy

var highlighted: Dictionary = {}
var selections: ActionSelection
var action_queue: Array[FactionAction] = []
var current_action: FactionAction

var player_ids: Dictionary = {} #Dictionary that maps RPC ids to player ids
var turn_orders: Dictionary = {}

const KEYBINDS: Array[String] = [
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9"
]

signal change_current_action(action: FactionAction)
signal add_action_to_queue(action: FactionAction)
signal remove_action_from_queue(action_index: int)

func _ready() -> void:
	
	self.selections = ActionSelection.new()
	self.reset_highlight()
	self.galaxy = GalaxyGen.init(53+53) #testing seed of 53 + 53
	
	var neutral_player: Player = Player.new()
	neutral_player.colour = Color.WHITE
	neutral_player.faction_id = Faction.FACTION_IDS.NONE
	neutral_player.resigned = true
	neutral_player.is_hidden = true
	neutral_player.network_id = -1
	neutral_player.player_id = 0
	
	var test_player: Player = Player.new()
	test_player.player_name = "Arc"
	test_player.colour = Color.BLUE
	test_player.faction_id = Faction.FACTION_IDS.DEVOURER
	test_player.network_id = 1
	test_player.player_id = 1
	
	self.player_ids = {1 : 1}
	
	self.galaxy.players = [neutral_player, test_player]
	self.galaxy.player_id = 1
	self.galaxy.factions[0] = Faction.new()
	self.galaxy.factions[0].player_id = 0
	self.galaxy.factions[0].fac_id = Faction.FACTION_IDS.NONE
	self.galaxy.factions[self.galaxy.player_id] = Eaters.new()
	self.galaxy.factions[self.galaxy.player_id].init(self.galaxy.player_id)
	self.galaxy.factions[self.galaxy.player_id].player_id = self.galaxy.player_id
	
	self.galaxy.setup_order = self.GalaxyGen.generate_setup_order(self.galaxy)
	
	await get_tree().process_frame
	ActionPanel.init(self.galaxy)
	self.update_map()
	self.update_factions_desc()

func attempt_submit_turn() -> void:
	if action_queue.size() > 0:
		#if action_queue[current_action].is_action_executable(self.galaxy.player_id, self.galaxy, self.selections, self.action_queue):
		#	action_queue[self.current_action].bound_action_selection = self.selections.duplicate()
		#	self.reset_selections()
		pass
	
	var end_turn_allowed: bool = true
	
	if self.galaxy.in_setup and self.action_queue.size() == 0:
		end_turn_allowed = false
	else:
		for action in self.action_queue:
			if not action.is_action_executable(self.galaxy.player_id, self.galaxy, action.bound_action_selection, self.action_queue):
				end_turn_allowed = false
				break
	
	if end_turn_allowed:
		print("Turn submitted.")
		self.submit_orders(action_queue)
	else:
		print("Turn could not be submitted: Some selected actions are invalid.")

func submit_orders(submitted_actions: Array[FactionAction]) -> void:
	
	var submitted_action_ids: Array[PackedStringArray] = []
	var selected_system_ids: Array[PackedInt32Array] = []
	var selected_ship_ids: Array[PackedInt32Array] = []
	
	for action in submitted_actions:
		submitted_action_ids.append(action.get_action_id())
		selected_system_ids.append(action.bound_action_selection.export_systems_as_ids())
		selected_ship_ids.append(action.bound_action_selection.export_ships_as_ids())
	
	self.action_queue = []
	self.current_action = null
	self.reset_selections()
	get_tree().call_group("queued_action", "queue_free")
	
	rpc_id(1, "receive_orders", submitted_action_ids, selected_system_ids, selected_ship_ids)

@rpc("any_peer", "call_local", "reliable")
func receive_orders(received_actions: Array[PackedStringArray], selected_system_ids: Array[PackedInt32Array], selected_ship_ids: Array[PackedInt32Array]) -> void:
	
	var received_dict: Dictionary = {}
	received_dict.action_ids = received_actions
	received_dict.system_ids = selected_system_ids
	received_dict.ship_ids = selected_ship_ids
	
	self.turn_orders[multiplayer.get_remote_sender_id()] = received_dict
	
	if not galaxy.in_setup and self.turn_orders.keys().size() == self.player_ids.size():
		
		print(turn_orders)
		print("^turn orders, pre turn_processor, about to be converted to orders_dict")
		
		var orders_dict: Dictionary = {}
		for key in self.turn_orders.keys():
			orders_dict[player_ids[key]] = self.turn_orders[key]
		
		var new_galaxy: Galaxy = self.TurnProcessor.process_turn(self.galaxy, orders_dict)
		rpc("receive_turn", new_galaxy)
	elif galaxy.in_setup:
		var wanted_network_id: int = -1
		for player in self.galaxy.players:
			if player.player_id == self.galaxy.setup_order[self.galaxy.setup_index]:
				wanted_network_id = player.network_id
		if self.turn_orders.keys().has(wanted_network_id):
			var new_galaxy: Galaxy = self.TurnProcessor.process_turn(self.galaxy, {wanted_network_id: self.turn_orders[wanted_network_id]})
			if not new_galaxy.in_setup:
				self.GalaxyGen.place_neutrals(new_galaxy)
				pass
			rpc("receive_turn", new_galaxy)

@rpc("authority", "call_local", "reliable")
func receive_turn(received_galaxy: Galaxy) -> void:
	print("New turn received!")
	var new_galaxy: Galaxy = received_galaxy.duplicate()
	new_galaxy.player_id = self.galaxy.player_id
	self.galaxy = new_galaxy
	self.ActionPanel.init(self.galaxy)
	self.reset_selections()
	self.update_map()
	self.update_factions_desc()

func update_map() -> void:
	self.galaxy = MapFrame.init(self.galaxy, self.selections, self.highlighted, self.action_queue)

func reset_highlight() -> void:
	
	self.highlighted = {
		"highlight_type": "",
		"highlight_id": null
	}

func add_system_to_selection(new_system: StarSystem) ->bool:
	
	var is_selected: bool = self.selections.add_system(self.galaxy, new_system, self.action_queue)
	
	#if self.current_action != null:
	#	self.emit_signal("add_action_to_queue", self.current_action)
	
	self.update_action_buttons()
	
	return is_selected

func reset_selections() -> void:
	
	self.selections.wipe()
	
	self.update_action_buttons()

func update_action_buttons() -> void:
	
	for node in get_tree().get_nodes_in_group("action_button"):
		if not node is Label:
			if self.current_action != null and self.current_action.is_action_identical(node.action):
				node.is_clickable = false
				node.is_selected = true
			elif node.action.is_action_valid(galaxy.player_id, galaxy, self.selections, self.action_queue, false):
				node.is_clickable = true
				node.is_selected = false
			else:
				node.is_clickable = false
				node.is_selected = false
			node.adjust_display_theme()

func update_system_desc(system_id: int) -> void:
	
	if system_id == null or system_id < 0:
		LeftDesc.set_text("")
	else:
		var system: StarSystem = self.galaxy.get_system_from_id(system_id)
		LeftDesc.set_text(system.get_system_description(self.galaxy))

func update_factions_desc() -> void:
	var desc_template: String = "You are the $faction_name.
You face the $enemy_names as your rivals.
It is year $current_turn and your technology level is $tech_level.
You possess $num_systems system$sys_s, $num_constructions constructions$const_s and $num_ships ship$ship_s."
	
	var desc_format: Dictionary = {
		"$faction_name": self.galaxy.get_faction_name(galaxy.player_id, 1, false),
		"$current_turn": str(self.galaxy.current_turn),
		"$tech_level": str(self.galaxy.factions[self.galaxy.player_id].calculate_tech_level()), #TODO: count tech points too!
		"$num_systems": str(self.galaxy.get_systems_owned_by_player(galaxy.player_id).size()),
		"$sys_s": "s",
		"$num_constructions": str(self.galaxy.get_constructions_owned_by_player(galaxy.player_id).size()),
		"$const_s": "s",
		"$num_ships": str(self.galaxy.get_ships_by_player(self.galaxy.player_id).size()),
		"$ship_s": "s",
		"$enemy_names": "",
	}
	
	var enemies_template: String = ""
	
	desc_format["$tech_level"] += "(" + str(self.galaxy.factions[self.galaxy.player_id].calculate_points_for_advancement()) + " points until the next tech level)"
	
	if desc_format["$num_systems"] == "1":
		desc_format["$sys_s"] = ""
	
	if desc_format["$num_constructions"] == "1":
		desc_format["$const_s"] = ""
	
	if desc_format["$num_ships"] == "1":
		desc_format["$ship_s"] = ""
	
	desc_template = desc_template.format(desc_format, "_")
	
	self.FactionsDesc.set_text("")
	self.FactionsDesc.append_text(desc_template)

func update_starpath_desc(starpath: Array[Vector2]) -> void:
	
	if starpath.size() < 2:
		LeftDesc.set_text("")
	else:
		var systems: Array[StarSystem] = self.galaxy.get_systems_from_starpath(starpath)
		LeftDesc.set_text("Starpath between " + systems[0].get_system_name() + " and " + systems[1].get_system_name())

func is_pos_in_system(pos: Vector2) -> StarSystem:
	
	for system in galaxy.systems:
		var dist: float = pow(pos.x - system.pos.x, 2) + pow(pos.y - system.pos.y, 2)
		if dist < pow(system.radius, 2):
			return system
	
	return null

func is_pos_along_starpath(pos: Vector2) -> Array[Vector2]:
	
	for key in self.galaxy.display_paths.keys():
		var starpath: Array[Vector2] = key
		var display_path: Array[Vector2] = self.galaxy.display_paths[starpath]
		display_path.sort()
		if Geometry2D.segment_intersects_circle(display_path[0], display_path[1], pos, 8.0) != -1:
			#print(display_path)
			return starpath
	
	return []

func _input(event: InputEvent) -> void:
	
	if event is InputEventKey and not event.pressed:
		if event.is_action("clear"):
			self.reset_selections()
			self.update_map()
		elif event.is_action("queue"):
			if self.current_action != null:
				self.emit_signal("add_action_to_queue", current_action)
		elif event.is_action("submit"):
			#self.attempt_submit_turn()
			pass

func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		var pos: Vector2 = event.position
		var system: StarSystem = self.is_pos_in_system(pos)
		var starpath: Array[Vector2] = self.is_pos_along_starpath(pos)
		
		if system != null:
			if self.highlighted["highlight_type"] != "system" or self.highlighted["highlight_id"] != system.sys_id:
				self.highlighted["highlight_type"] = "system"
				self.highlighted["highlight_id"] = system.sys_id
				self.update_system_desc(system.sys_id)
				self.update_map()
				#print("mouse position in system " + str(system.sys_id))
		elif starpath.size() > 0:
			if self.highlighted["highlight_type"] != "starpath" or  self.highlighted["highlight_id"] != starpath:
				self.highlighted["highlight_type"] = "starpath"
				self.highlighted["highlight_id"] = starpath
				self.update_starpath_desc(starpath)
				self.update_map()
				#print("mouse position along starpath")
		else:
			if self.highlighted["highlight_type"] != "": 
				reset_highlight()
				self.update_system_desc(-1)
				self.update_map()
	elif event is InputEventMouseButton and event.pressed:
		
		if self.highlighted["highlight_type"] == "system":
			var system: StarSystem = galaxy.get_system_from_id(self.highlighted["highlight_id"])
			if event.button_index == MOUSE_BUTTON_LEFT:
				var is_selected: bool = self.add_system_to_selection(system)
				if not is_selected:
					selections.add_ship(galaxy, system, action_queue)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				selections.remove_system(galaxy, system)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if self.selections.get_system_index(galaxy, system) != -1:
					selections.add_ship(galaxy, system, action_queue)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if self.selections.get_system_index(galaxy, system) != -1:
					selections.remove_ship(galaxy, system, action_queue)
			self.update_action_buttons()
		elif self.highlighted["highlight_type"] == "starpath":
			
			var starpath_systems: Array[StarSystem] = self.galaxy.get_systems_from_starpath(self.highlighted["highlight_id"])
			
			if starpath_systems.size() == 2 and self.selections.selected_systems.size() > 0:
				var latest_system: StarSystem = self.selections.selected_systems.back()
				if starpath_systems[0].is_system_identical(latest_system):
					var is_selected: bool = self.add_system_to_selection(starpath_systems[1])
					#if not is_selected:
					#	selections.add_ship(galaxy, starpath_systems[1], action_queue)
				elif starpath_systems[1].is_system_identical(latest_system):
					var is_selected: bool = self.add_system_to_selection(starpath_systems[0])
					#if not is_selected:
					#	selections.add_ship(galaxy, starpath_systems[0], action_queue)
		
		self.update_map()
	
		#print(self.highlighted["highlight_id"])

func _on_change_current_action(action: FactionAction) -> void:
	
	var are_previous_actions_executable: bool = true
	
	for prev_action in self.action_queue:
		if not prev_action.is_action_executable(galaxy.player_id, galaxy, prev_action.bound_action_selection, self.action_queue):
			are_previous_actions_executable = false
			break
	
	if are_previous_actions_executable and action.is_action_valid(galaxy.player_id, galaxy, self.selections, self.action_queue, false):
		self.current_action = action
		self.update_action_buttons()
		print("Set action " + action.action_name + " as current action.")

func _on_add_action_to_queue(action_to_add: FactionAction) -> void:
	
	var are_previous_actions_executable: bool = true
	
	for prev_action in self.action_queue:
		if not prev_action.is_action_executable(galaxy.player_id, galaxy, prev_action.bound_action_selection, self.action_queue):
			are_previous_actions_executable = false
			break
	
	if are_previous_actions_executable and action_to_add.is_action_executable(galaxy.player_id, galaxy, self.selections, self.action_queue, false):
		var new_action: FactionAction = action_to_add.duplicate()
		self.action_queue.append(new_action)
		new_action.bound_action_selection = ActionSelection.new()
		new_action.bound_action_selection.load_selection(galaxy, self.selections.export_systems_as_ids(), self.selections.export_ships_as_ids())
		self.current_action = null
		self.reset_selections()
		self.update_map()
		var current_action_index: int = self.action_queue.size() -1
		
		self.update_action_buttons()
		
		var queue_scene = load("res://scenes/queued_action.tscn")
		var instance = queue_scene.instantiate()
		instance.init(new_action, current_action_index)
		self.get_node("GameBox/MainScreen/VBoxContainer/QueuePanel/ActionQueue").add_child(instance)
		
		print("Added action " + new_action.action_name + " to action queue!")
		
	else:
		print("Failed to add action " + action_to_add.action_name + " to action queue...")

func _on_remove_action_from_queue(action_index: int) -> void:

	if action_index >= 0 and action_index < self.action_queue.size():
		var new_action_queue: Array[FactionAction]
		for i in range(self.action_queue.size()):
			if i != action_index:
				new_action_queue.append(self.action_queue[i])
			
		if new_action_queue.size() < self.action_queue.size():
			self.action_queue = []
			#TODO: make it so that this actually does what it's supposed to instead of just clearing the entire queue
			get_tree().call_group("queued_action", "queue_free")
			for action in new_action_queue:
				self.emit_signal("add_action_to_queue", action)
		
		self.update_action_buttons()

func _on_button_pressed() -> void:
	#printerr("END TURN BUTTON PRESSED")
	attempt_submit_turn()

func _on_queue_button_pressed() -> void:
	if self.current_action != null:
		self.emit_signal("add_action_to_queue", current_action)
