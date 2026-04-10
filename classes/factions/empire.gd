extends Faction
class_name Empire

func init(new_player_id: int) -> void:
	self.player_id = new_player_id
	self.fac_id = Faction.FACTION_IDS.EMPIRE

func full_description() -> String:
	var description: String = ""
	
	description += "The IMMORTAL EMPIRE" + "\n"
	description += "DIFFICULTY: MODERATE" + "\n"
	description += "COMBAT STRENGTH: MODERATE" + "\n"
	description += "TECHNOLOGY: MODERATE" + "\n"
	description += "INFRASTRUCTURE: HIGH" + "\n"
	description += "\n" + "The IMMORTAL EMPIRE is a union of countless rich worlds, only recently united under a powerful monarchy."
	description += "\n" + "Their fleets have no especial advantages to begin with, but as the EMPIRE grows they become more powerful and numerous."
	description += "\n" + "The hallmark expansionism of the EMPIRE is also it's weakness; Starved of systems, they will be unable to contest anything."
	description += "\n" + "However, IMPERIAL ambition is boundless; If they are not stopped quickly, their technological edge can easily become insurmountable."
	
	return description
