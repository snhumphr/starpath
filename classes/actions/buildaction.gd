extends FactionAction
class_name BuildAction

@export var construction_type: StarSystem.CONSTRUCTIONS = StarSystem.CONSTRUCTIONS.EMPTY
@export var ships_built: int = 0

func starting_system_slot() -> SystemSlot:
	
	var slot: SystemSlot = SystemSlot.new()
	
	slot.accepts_enemy_system = false
	slot.allowed_constructions = [StarSystem.CONSTRUCTIONS.EMPTY]
	
	return slot
