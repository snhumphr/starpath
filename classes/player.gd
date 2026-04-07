extends Resource
class_name Player

@export var player_id: int
@export var network_id: int
@export var faction_id: Faction.FACTION_IDS
@export var player_name: String
@export var colour: Color

@export var is_hidden: bool = false
@export var resigned: bool = false
