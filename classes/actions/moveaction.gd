extends FactionAction
class_name MoveAction

func init() -> void:
	
	self.action_priority = 10 # Move actions prevent future shipbuilding/construction/etc from happening
	self.system_slots = [self.starting_system_slot(), self.dest_system_slot()]

func starting_system_slot() -> SystemSlot:
	
	var slot: SystemSlot = SystemSlot.new()
	
	slot.accepts_enemy_system = false
	slot.own_ship_minimum = 1
	
	return slot

func dest_system_slot() -> SystemSlot:
	
	var slot: SystemSlot = SystemSlot.new()
	
	return slot

func is_action_valid(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = [], is_in_queue: bool = true) -> bool:
	
	if selection.selected_systems.size() > 0:
		var starting_system: StarSystem = selection.selected_systems[0]
		if starting_system.player_id != galaxy.player_id and starting_system.construction == StarSystem.CONSTRUCTIONS.FORTRESS:
			print("Cannot move out of a system with an enemy fortress.")
			return false
	
	if self.system_slots.size() > 1 and selection.selected_systems.size() == self.system_slots.size():
		for i in range(0, selection.selected_systems.size()-1):
			var system_1: StarSystem = selection.selected_systems[i]
			var system_2: StarSystem = selection.selected_systems[i+1]
			if not system_1.is_system_neighbour(system_2):
				print("Cannot move between system " + system_1.get_system_name() + " and " + system_2.get_system_name() + ", they are not adjacent.")
				return false
	
	return self.is_action_valid_base(actor_id, galaxy, selection, action_queue, is_in_queue)

func execute_action(galaxy: Galaxy, selection: ActionSelection, actor_id: int, changes: Array[PackedInt32Array]) -> Array[String]:
	
	var ship_list: Array[Ship] = []
	
	for i in range(0, self.system_slots.size() -1):
		var friendly_system_ships: Array = galaxy.get_ships_in_system(selection.selected_systems[i].sys_id).get(galaxy.player_id, [])
		for ship_index in range(0, selection.selected_ships[i]):
			ship_list.append(friendly_system_ships[ship_index])
	
	var dest_system: StarSystem = selection.selected_systems[self.system_slots.size()-1]
	
	var move_change: PackedInt32Array = PackedInt32Array([
		Galaxy.ChangeTypes.MOVE_SHIP, #change type 0
		0, #player id 1
		0, #faction id 2
		0, #system id 3
		0, #dest id 4
		1, #num ships 5
		StarSystem.CONSTRUCTIONS.EMPTY, #new construction 6
	])
	
	for ship in ship_list:
		var new_move_change: PackedInt32Array = move_change.duplicate()
		new_move_change[1] = actor_id
		new_move_change[3] = ship.system_id
		new_move_change[4] = dest_system.sys_id
		changes.append(new_move_change)
	
	#TODO: MAKE THIS WORK WITH CUSTOM EXECUTION ACTIONS
	
	return ["    " + str(ship_list.size()) + " ships moved to " + dest_system.get_system_name()]
