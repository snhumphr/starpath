@abstract
extends Resource
class_name Action

@abstract func get_action_id() -> PackedStringArray

@abstract func is_action_valid(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = [], is_in_queue: bool = true) -> bool

@abstract func is_action_executable(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = [], is_in_queue: bool = true) -> bool

@abstract func execute_action(galaxy: Galaxy, selection: ActionSelection, actor_id: int) -> Array[String]

@abstract func reserves_ships() -> bool
