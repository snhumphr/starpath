extends Faction
class_name Interlopers

func init(new_player_id: int) -> void:
	self.player_id = new_player_id
	self.fac_id = Faction.FACTION_IDS.INTERLOPER

func full_description() -> String:
	var description: String = ""
	
	description += "The INTERLOPERS" + "\n" #TODO: change the name in case of mirror matches
	description += "DIFFICULTY: HIGH" + "\n"
	description += "COMBAT STRENGTH: LOW" + "\n"
	description += "TECHNOLOGY: MODERATE" + "\n"
	description += "INFRASTRUCTURE: LOW" + "\n"
	description += "\n" + "The INTERLOPERS are an enigmatic force seeking to make inroads on the galaxy by stealth rather then by force."
	description += "\n" + "Their ships are few, but their unique cloaking powers allow them to slip through all but the most fortified systems with ease."
	description += "\n" + "Their technology starts powerful, but they will need to use espionage and sabotage to stay ahead in the long-term."
	description += "\n" + "To be any more then a nuisance, however, the INTERLOPERS must find a way to stand their ground."
	description += "\n" + "[The INTERLOPERS are not recommended for new players, or in games with a small number of players]"
	
	return description
