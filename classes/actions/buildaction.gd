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

func execute_action(galaxy: Galaxy, selection: ActionSelection, actor_id: int) -> Array[String]:
	
	var execution_message: Array[String] = []
	
	for system in selection.selected_systems:

		var construction_message: String = self.get_construction_message(system)
		if construction_message != "":
			execution_message.append(construction_message)
		galaxy.get_system_from_id(system.sys_id).construction = self.construction_type #TODO: maybe route this through a setter?
	
		if self.ships_built > 0:
			execution_message.append(self.build_ships(system, galaxy, actor_id, self.ships_built))
		elif self.ships_built < 0:
			pass #TODO: implement consuming ships to build things when implementing Ancients
	
	execution_message += self.execute_action_base(galaxy, selection, actor_id)
	
	return execution_message

func build_ships(system: StarSystem, galaxy: Galaxy, actor_id: int, num_ships: int) -> String:
	
	var build_message: String = ""
	
	for i in range(0, num_ships):
		galaxy.add_ship(system.sys_id, galaxy.players[actor_id].faction_id, actor_id)
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
