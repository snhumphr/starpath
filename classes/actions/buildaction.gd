extends FactionAction
class_name BuildAction

@export var construction_type: StarSystem.CONSTRUCTIONS = StarSystem.CONSTRUCTIONS.EMPTY
@export var ships_built: int = 0

func init() -> void:
	self.action_priority = 1
	self.system_slots = [self.starting_system_slot()]
	self.reserves_selected_ships = false

func starting_system_slot() -> SystemSlot:
	
	var slot: SystemSlot = SystemSlot.new()
	
	slot.accepts_enemy_system = false
	slot.allowed_constructions = [StarSystem.CONSTRUCTIONS.EMPTY]
	slot.own_ship_maximum = 0
	
	return slot

func execute_action(galaxy: Galaxy, selection: ActionSelection, actor_id: int, changes: Array[PackedInt32Array]) -> Array[String]:
	
	var execution_message: Array[String] = []
	
	var build_change: PackedInt32Array = PackedInt32Array([
		Galaxy.ChangeTypes.CHANGE_CONSTRUCTION, #change type 0
		0, #player id 1
		0, #faction id 2
		0, #system id 3
		0, #dest id 4
		0, #num ships 5
		StarSystem.CONSTRUCTIONS.EMPTY, #new construction 6
	])
	
	for system in selection.selected_systems:

		var construction_message: String = self.get_construction_message(system)
		if construction_message != "":
			execution_message.append(construction_message)
	
		var new_build_change: PackedInt32Array = build_change.duplicate()
		new_build_change[1] = actor_id
		new_build_change[2] = system.sys_id
		new_build_change[5] = self.construction_type
		changes.append(new_build_change)
	
		if self.ships_built > 0:
			execution_message.append(self.build_ships(system, galaxy, actor_id, self.ships_built, changes))
		elif self.ships_built < 0:
			pass #TODO: implement consuming ships to build things when implementing Ancients
	
	execution_message += self.execute_action_base(galaxy, selection, actor_id, changes)
	
	return execution_message

func build_ships(system: StarSystem, galaxy: Galaxy, actor_id: int, num_ships: int, changes: Array[PackedInt32Array]) -> String:
	
	var build_message: String = ""
	
	var add_ship_change: PackedInt32Array = PackedInt32Array([
		Galaxy.ChangeTypes.ADD_SHIP, #change type 0
		0, #player id 1
		Faction.FACTION_IDS.NONE, #faction id 2
		0, #system id 3
		0, #dest id 4
		1, #num ships 5
		StarSystem.CONSTRUCTIONS.EMPTY, #new construction 6
	])
	
	for i in range(0, num_ships):
		var new_ship_change: PackedInt32Array = add_ship_change.duplicate()
		new_ship_change[1] = actor_id
		new_ship_change[2] = galaxy.players[actor_id].faction_id
		new_ship_change[3] = system.sys_id
		changes.append(new_ship_change)
		build_message += "    " +str(self.ships_built) + " ship"
		if self.ships_built > 1:
			build_message += "s"
		build_message += " built at " + system.get_system_name()
	
	return build_message

func get_construction_message(system: StarSystem) -> String:
	
	if system.construction != self.construction_type:
		match self.construction_type:	
			StarSystem.CONSTRUCTIONS.SHIPYARD:
				return "    " +"Shipyard constructed at " + system.get_system_name()
			StarSystem.CONSTRUCTIONS.LAB:
				return "    " +"Laboratory constructed at " + system.get_system_name()
			StarSystem.CONSTRUCTIONS.FORTRESS:
				return "    " +"Fortress constructed at " + system.get_system_name()
			_:
				return "    " +"Construction demolished at " + system.get_system_name()
	else:
		return ""
