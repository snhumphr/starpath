extends Action
class_name FactionAction

@export var action_category: String = "Basic"
@export var action_name: String = "Dance"
@export var short_desc: String = "Get down and boogey."
@export var shortcut_key: String = ""

@export var bound_action_selection: ActionSelection

@export var reserves_selected_ships: bool = true
@export var is_action_unique: bool = false #A unique action can only be performed once per turn.
@export var action_priority: int = 1 #An action cannot be performed after an action with a higher action priority has been performed that turn
@export var is_setup_action: bool = false

@export var system_slots: Array[SystemSlot] = []

@export var custom_validity_checks: Array[Callable] = []
@export var custom_execution_actions: Array[Callable] = []

func get_action_id() -> PackedStringArray:
	return PackedStringArray([self.action_name, self.action_category, self.short_desc])

func is_action_identical(other_action: FactionAction) -> bool:
	return self.get_action_id() == other_action.get_action_id()

func is_action_valid(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = [], is_in_queue: bool = true) -> bool:
	
	return is_action_valid_base(actor_id, galaxy, selection, action_queue, is_in_queue)

func is_action_valid_base(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction], is_in_queue: bool) -> bool:
	
	#var target_systems: Array[StarSystem] = selection.get_selected_systems()
	
	print("Player #" + str(actor_id) + " checking validity of action " + self.action_name)
	
	if self.is_setup_action != galaxy.in_setup:
		print("Action cannot be used in current galaxy due to setup state")
		return false
	
	if selection.selected_systems.size() > self.system_slots.size():
		print("Too many systems selected")
		return false
	
	var own_index: int = action_queue.size()
	
	for i in range(0, action_queue.size()):
		var action: FactionAction = action_queue[i]
		if self == action: #TODO: CHECK THAT THIS ACTUALLY WORKS! <- it currently kind of SEEMS like it works???
			own_index = i
	
	
	var actions_by_category: Dictionary = {}
	
	if not is_in_queue:
		actions_by_category[self.action_category] = 1
	
	for i in range(0, action_queue.size()):
		var action: FactionAction = action_queue[i]
		if not actions_by_category.has(action.action_category):
			actions_by_category[action.action_category] = 1
		else:
			actions_by_category[action.action_category] += 1
		if self.is_action_unique and self.is_action_identical(action):
			if not is_in_queue or i != own_index:
				print("Unique action already selected.")
				return false
	
	#if not is_in_queue:
	#	actions_by_category[self.action_category] += 1
	
	var actor_faction: Faction = galaxy.factions[actor_id]
	
	if actions_by_category[self.action_category] > actor_faction.num_actions_per_category.get(self.action_category, 0):
		print("Allowed actions of category " + self.action_category + " exceeded: Faction only has " + str(actor_faction.num_actions_per_category.get(self.action_category, 0)) + " actions while " + str(actions_by_category[self.action_category]) + " are queued.")
		return false
	
	for i in range(0, own_index):
		var action: FactionAction = action_queue[0]
		if action.action_priority > self.action_priority:
			print("Action with higher priority already selected")
			return false
	
	for i in range(0, selection.selected_systems.size()):
		if not self.system_slots[i].is_system_valid(galaxy, selection, i, actor_id):
			print("Selected systems not valid for action's slots")
			return false
	
	for function in self.custom_validity_checks:
		var error_message: String = function.call(self, actor_id, galaxy, selection, action_queue, is_in_queue)
		if error_message != "":
			print(error_message)
			return false
	
	return true

func is_action_executable(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = [], is_in_queue: bool = true) -> bool:
	
	return self.is_action_executable_base(actor_id, galaxy, selection, action_queue, is_in_queue)

func is_action_executable_base(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction], is_in_queue: bool) -> bool:
	
	if selection.selected_systems.size() != self.system_slots.size():
		print("Not enough systems selected to fill all action's slots")
		return false
	
	return self.is_action_valid(actor_id, galaxy, selection, action_queue, is_in_queue)

func execute_action(galaxy: Galaxy, selection: ActionSelection, actor_id: int, changes: Array[PackedInt32Array]) -> Array[String]:
	
	var execution_log: Array[String] = []
	
	execution_log += self.execute_action_base(galaxy, selection, actor_id, changes)
	
	return execution_log

func execute_action_base(galaxy: Galaxy, selection: ActionSelection, actor_id: int, changes: Array[PackedInt32Array]) -> Array[String]:
	
	var execution_log: Array[String] = []
	
	for function in self.custom_execution_actions:
		execution_log += function.call(self, galaxy, selection, actor_id, changes)
	
	return execution_log

func reserves_ships() -> bool:
	return self.reserves_selected_ships

func compile_change(change_type: Galaxy.ChangeTypes, player_id: int, faction_id: int, sys_id: int, dest_id: int, num_ships: int = 0, new_construction: StarSystem.CONSTRUCTIONS = StarSystem.CONSTRUCTIONS.EMPTY) -> PackedInt32Array:
	var change: PackedInt32Array = PackedInt32Array([])
	
	change.append(change_type)
	change.append(player_id)
	change.append(faction_id)
	change.append(sys_id)
	change.append(dest_id)
	change.append(num_ships)
	change.append(new_construction)
	
	return change
