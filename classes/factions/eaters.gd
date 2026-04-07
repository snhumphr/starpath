extends Faction
class_name Eaters

func init(new_player_id: int) -> void:
	self.player_id = new_player_id
	self.fac_id = Faction.FACTION_IDS.DEVOURER
	self.actions = self.load_actions()
	self.setup_actions = self.load_setup_actions()
	self.setup_priority = 20
	self.num_actions_per_category = {
		"Setup": 1,
		"Basic": 1,
		"Swarm": 4,
	}

func full_description() -> String:
	var description: String = ""
	
	description += "The EATERS" + "\n" #TODO: change the name in case of mirror matches
	description += "DIFFICULTY: LOW" + "\n"
	description += "COMBAT STRENGTH: HIGH" + "\n"
	description += "TECHNOLOGY: VERY LOW" + "\n"
	description += "INFRASTRUCTURE: VERY LOW" + "\n"
	description += "\n" + "The EATERS are a vast collective intelligence devoted solely to their own self-propagation."
	description += "\n" + "The more systems they spread to, the more ships they will be able to construct, even without shipyards."
	description += "\n" + "However, they are not without weakness; destroying their central hive will substantially disrupt their logistics."
	description += "\n" + "Finally, their technology only advances when the hive is re-built, as a new intelligence takea command."
	
	return description

func load_setup_actions() -> Array[FactionAction]:
	
	var eater_setup: Array[FactionAction] = []
	
	var place_hive: FactionAction = BuildAction.new()
	place_hive.action_name = "Place Hive"
	place_hive.action_category = "Setup"
	place_hive.is_setup_action = true
	place_hive.is_action_unique = true
	place_hive.system_slots = [place_hive.starting_system_slot()]
	place_hive.system_slots[0].accepts_enemy_system = true
	place_hive.construction_type = StarSystem.CONSTRUCTIONS.FORTRESS
	place_hive.ships_built = 9
	place_hive.short_desc = "Build a Fortress & 9 ships in 1 system."
	
	eater_setup.append(place_hive)
	
	return eater_setup

func load_actions() -> Array[FactionAction]:
	
	var eater_actions: Array[FactionAction] = []
	
	var move_action: MoveAction = MoveAction.new()
	move_action.init()
	move_action.action_category = "Swarm"
	move_action.action_name = "Move"
	move_action.short_desc = "Move 1-9 ships to an adjacent system."
	eater_actions.append(move_action)
	
	return eater_actions
