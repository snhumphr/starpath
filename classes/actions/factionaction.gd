extends Resource
class_name FactionAction

@export var action_category: String = "Basic"
@export var action_name: String = "Dance"
@export var short_desc: String = "Get down and boogey."

@export var bound_action_selection: ActionSelection

@export var is_action_unique: bool = true #A unique action can only be performed once per turn.
@export var action_priority: int = 1 #An action cannot be performed after an action with a higher action priority has been performed that turn
@export var is_setup_action: bool = false

@export var system_slots: Array[SystemSlot] = []

func get_action_id() -> PackedStringArray:
	return PackedStringArray([self.action_name, self.action_category, self.short_desc])

func is_action_identical(other_action: FactionAction) -> bool:
	return self.get_action_id() == other_action.get_action_id()

func is_action_valid(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = []) -> bool:
	
	return is_action_valid_base(actor_id, galaxy, selection, action_queue)

func is_action_valid_base(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = []) -> bool:
	
	#var target_systems: Array[StarSystem] = selection.get_selected_systems()
	
	if galaxy.actions_disabled:
		print("Actions cannot currently be used in this galaxy")
		return false
	
	if self.is_setup_action != galaxy.in_setup:
		print("Action cannot be used in current galaxy due to setup state")
		return false
	
	if selection.selected_systems.size() > self.system_slots.size():
		print("Too many systems selected")
		return false
	
	var own_index: int = 0
	
	for i in range(0, action_queue.size()):
		var action: FactionAction = action_queue[i]
		if self == action:
			own_index = i
	
	var actions_by_category: Dictionary = {}
	
	for i in range(0, action_queue.size()):
		var action: FactionAction = action_queue[i]
		if not actions_by_category.has(action.action_category):
			actions_by_category[action.action_category] = 1
		else:
			actions_by_category[action.action_category] +=1
		if i != own_index and self.is_action_unique and self.is_action_identical(action):
			print("Unique action already selected.")
			return false
	
	if not actions_by_category.has(self.action_category):
		actions_by_category[self.action_category] = 1
	else:
		actions_by_category[self.action_category] += 1
	
	var actor_faction: Faction = galaxy.factions[actor_id]
	
	if actions_by_category[self.action_category] > actor_faction.num_actions_per_category.get(self.action_category, 0):
		print("Allowed actions of category " + self.action_category + " exceeded")
		return false
	
	for i in range(0, own_index):
		var action: FactionAction = action_queue[0]
		if action.action_priority > self.action_priority:
			print("Action with higher priority already selected")
			return false
	
	for i in range(0, selection.selected_systems.size()):
		if not self.system_slots[i].is_system_valid(galaxy, selection, i, galaxy.player_id):
			print("Selected systems not valid for action's slots")
			return false
	
	return true

func is_action_executable(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = []) -> bool:
	
	return self.is_action_executable_base(actor_id, galaxy, selection, action_queue)

func is_action_executable_base(actor_id: int, galaxy: Galaxy, selection: ActionSelection, action_queue: Array[FactionAction] = []) -> bool:
	
	if selection.selected_systems.size() != self.system_slots.size():
		print("Not enough systems selected to fill all action's slots")
		return false
	
	return self.is_action_valid(actor_id, galaxy, selection, action_queue)

func reserves_ships() -> bool:
	return true
