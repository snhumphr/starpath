extends Faction
class_name Ancients

func init(new_player_id: int) -> void:
	self.player_id = new_player_id
	self.fac_id = Faction.FACTION_IDS.ANCIENTS

func full_description() -> String:
	var description: String = ""
	
	description += "The ANCIENTS" + "\n" #TODO: change the name in case of mirror matches
	description += "DIFFICULTY: MODERATE" + "\n"
	description += "COMBAT STRENGTH: MODERATE" + "\n"
	description += "TECHNOLOGY: VERY HIGH" + "\n"
	description += "INFRASTRUCTURE: MODERATE" + "\n"
	description += "\n" + "The ANCIENTS are an elder race of star-dwellers, who can no longer tolerate the infringement of lesser beings on their hegemony."
	description += "\n" + "Their vast world-ships move slowly, and are almost irreplaceable, but are terrifying forces on the battlefield."
	description += "\n" + "Their technology is leagues above the rest of the galaxy, but their caches are not limitless; Once spent, they must be replenished."
	description += "\n" + "A quick victory against them is infeasible, but they are overall much more vulnerable to attrition then the younger kindred."
	
	return description
