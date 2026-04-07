@abstract
extends Resource
class_name Action

@abstract func get_action_id() -> PackedStringArray

@abstract func is_action_valid(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = []) -> bool

@abstract func is_action_executable(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = []) -> bool

@abstract func execute_action(galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction]) -> void

@abstract func reserves_ships() -> bool
