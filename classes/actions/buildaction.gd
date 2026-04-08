extends FactionAction
class_name BuildAction

@export var construction_type: StarSystem.CONSTRUCTIONS = StarSystem.CONSTRUCTIONS.EMPTY
@export var ships_built: int = 0

func starting_system_slot() -> SystemSlot:
	
	var slot: SystemSlot = SystemSlot.new()
	
	slot.accepts_enemy_system = false
	slot.allowed_constructions = [StarSystem.CONSTRUCTIONS.EMPTY]
	
	return slot

func execute_action(galaxy: Galaxy, selection: ActionSelection, actor_id: int) -> Array[String]:
	
	var execution_message: Array[String] = []
	
	for system in selection.selected_systems:
		galaxy.get_system_from_id(system.sys_id).construction = self.construction_type #TODO: maybe route this through a setter?

		execution_message.append(self.get_construction_message(system))
	
		if self.ships_built > 0:
			for i in range(0, self.ships_built):
				galaxy.add_ship(system.sys_id, galaxy.players[actor_id].faction_id, actor_id)
			execution_message.append(str(self.ships_built) + " ships built at " + system.get_system_name())
		elif self.ships_built < 0:
			pass #TODO: implement consuming ships to build things when implementing Ancients
	
	return execution_message

func get_construction_message(system: StarSystem) -> String:
	
	match self.construction_type:	
		StarSystem.CONSTRUCTIONS.SHIPYARD:
			return "Shipyard constructed at " + system.get_system_name()
		StarSystem.CONSTRUCTIONS.LAB:
			return "Laboratory constructed at " + system.get_system_name()
		StarSystem.CONSTRUCTIONS.FORTRESS:
			return "Fortress constructed at " + system.get_system_name()
		_:
			return "Construction demolished at " + system.get_system_name()
