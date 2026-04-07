extends FactionAction
class_name MoveAction

func init() -> void:
	
	self.action_priority = 2 # Move actions prevent future building/researching/etc from happening
	self.system_slots = [self.starting_system_slot(), self.dest_system_slot()]

func starting_system_slot() -> SystemSlot:
	
	var slot: SystemSlot = SystemSlot.new()
	
	slot.accepts_enemy_system = false
	slot.own_ship_minimum = 1
	
	return slot

func dest_system_slot() -> SystemSlot:
	
	var slot: SystemSlot = SystemSlot.new()
	
	return slot

func is_action_valid(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = []) -> bool:
	
	if selection.selected_systems.size() > 0:
		var starting_system: StarSystem = selection.selected_systems[0]
		if starting_system.player_id != galaxy.player_id and starting_system.construction == StarSystem.CONSTRUCTIONS.FORTRESS:
			print("Cannot move out of a system with an enemy fortress.")
			return false
	
	if self.system_slots.size() > 1 and selection.selected_systems.size() == self.system_slots.size():
		pass
		for i in range(0, selection.selected_systems.size()-1):
			var system_1: StarSystem = selection.selected_systems[i]
			var system_2: StarSystem = selection.selected_systems[i+1]
			if not system_1.is_system_neighbour(system_2):
				print("Cannot move between system " + system_1.get_system_name() + " and " + system_2.get_system_name() + ", they are not adjacent.")
	
	return self.is_action_valid_base(actor_id, galaxy, selection, action_queue)
