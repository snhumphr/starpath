extends Control

var current_profile: Dictionary
@onready var ProfileBox: PanelContainer = self.get_node("MenuBar/ProfileBox")

const PROFILE_PATH = "user://profile.json"

func _ready() -> void:
	
	#load profile from disk, if one exists
	await get_tree().process_frame
	var current_profile = self.load_profile_from_disk()

func get_profile_from_box() -> Dictionary:
	
	var profile_dict: Dictionary = {}
	profile_dict.name = self.ProfileBox.get_node("VBoxContainer/NameRow/LineEdit").get_text()
	profile_dict.colour = self.ProfileBox.get_node("VBoxContainer/ColourRow/ColourButton").get_pick_color()
	
	return profile_dict

func load_profile_from_disk() -> Dictionary:
	var profile: Dictionary = {}
	
	if FileAccess.file_exists(PROFILE_PATH):
		var file = FileAccess.open(PROFILE_PATH, FileAccess.READ)
		var file_text: String = file.get_as_text()
		var file_dict = JSON.parse_string(file_text)
		file.close()
		profile = file_dict
	
	if profile.keys().size() > 0:
		self.ProfileBox.get_node("VBoxContainer/NameRow/LineEdit").set_text(profile.name)
		var colour_list: PackedStringArray = profile.colour.format({"(":"", ")":""}, "_").split(", ")
		var colour: Color = Color(float(colour_list[0]), float(colour_list[1]), float(colour_list[2]))
		self.ProfileBox.get_node("VBoxContainer/ColourRow/ColourButton").color = colour
	
	return profile

func _on_save_button_pressed() -> void:
	
	#load the profile from the profile box to current_profile
	self.current_profile = self.get_profile_from_box()

	#then try to save profile to disk
	print(PROFILE_PATH)
	var file = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	var json_string: String = JSON.stringify(self.current_profile)
	file.store_string(json_string)
	file.close()
