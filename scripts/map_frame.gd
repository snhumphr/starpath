extends Control

var display_polygons: Dictionary = {
	StarSystem.CONSTRUCTIONS.EMPTY: PackedVector2Array(), #Blank
	StarSystem.CONSTRUCTIONS.SHIPYARD: PackedVector2Array([ #Triangle
		Vector2(1, 1),
		Vector2(-1, 1),
		Vector2(0, -1),
		Vector2(1, 1), # comment this out if you swap back from polyline to polygon
	]),
	StarSystem.CONSTRUCTIONS.LAB: PackedVector2Array([
		Vector2(0.5, -1),
		Vector2(-0.5, -1),
		Vector2(-1, 0),
		Vector2(-0.5, 1),
		Vector2(0.5, 1),
		Vector2(1, 0),
		Vector2(0.5, -1), # comment this out if you swap back from polyline to polygon
	]), #Hexagon
	StarSystem.CONSTRUCTIONS.FORTRESS: PackedVector2Array([
		Vector2(1, -1),
		Vector2(-1, -1),
		Vector2(-1, 1),
		Vector2(1, 1),
		Vector2(1, -1), # comment this out if you swap back from polyline to polygon
	]), #Square
}

const SYSTEM_RADIUS: float = 36.0

const NEUTRAL_COLOUR: Color = Color.WHITE
const HIGHLIGHTED_COLOUR: Color = Color.YELLOW
const SELECTED_COLOUR: Color = Color.YELLOW

const RAINBOW: Array[Color] = [
	NEUTRAL_COLOUR,
	Color.RED,
	Color.ORANGE,
	Color.BLUE,
	Color.PURPLE
]

var galaxy: Galaxy
var highlighted: Dictionary 
var selected: ActionSelection
var action_queue: Array[FactionAction]

func init(new_galaxy: Galaxy, new_selected: ActionSelection, new_highlighted: Dictionary = {}, new_actions: Array[FactionAction] = []) -> Galaxy:
	
	self.galaxy = new_galaxy
	self.selected = new_selected
	self.highlighted = new_highlighted
	self.action_queue = new_actions
	
	self.apply_draw_scale(self.galaxy)
	self.galaxy.init_display_paths()
	
	self.queue_redraw()

	return self.galaxy

func apply_draw_scale(unscaled_galaxy: Galaxy) -> void:
	
	var map_box_size: Vector2 = self.size
	
	#print(map_box_size)
	#print(galaxy.size)
	
	var draw_scale: Vector2 = map_box_size / galaxy.size
	#print(draw_scale)
	
	for system in unscaled_galaxy.systems:
		system.pos = system.gal_pos * draw_scale
		system.radius = SYSTEM_RADIUS
		#print(system.gal_pos)
		#print(system.pos)

func _draw() -> void:

	if self.galaxy != null:
		
		for system in self.galaxy.systems:
			for neighbour in system.neighbours:
				var starpath: Array[Vector2] = system.get_starpath(neighbour)
				var system_arrow: bool = false
				var neighbour_arrow: bool = false
				
				for action in action_queue:
					var system_index: int = -1
					var neighbour_index: int = -1
					for index in range(0, action.bound_action_selection.selected_systems.size()):
						var selected_system: StarSystem = action.bound_action_selection.selected_systems[index]
						if selected_system.is_system_identical(system):
							system_index = index
						elif selected_system.is_system_identical(neighbour):
							neighbour_index = index
					
					if system_index < 0 or neighbour_index < 0:
						system_index = -1
						neighbour_index = -1
						#TODO: also draw an arrow between systems if they're highlighted in the right order
					
					if system_index >= 0 and neighbour_index >= 0:
						if system_index > neighbour_index:
							system_arrow = true
						if neighbour_index > system_index:
							neighbour_arrow = true
				
				if system_arrow:
					self.draw_line(system.pos, neighbour.pos, SELECTED_COLOUR, 4.0, true)
					if system_arrow:
						var neigh_to_sys_angle = neighbour.pos.angle_to_point(system.pos)
						var angle_vector: Vector2 = Vector2.from_angle(neigh_to_sys_angle)
						var arrow_pos: Vector2 = system.pos - angle_vector * (SYSTEM_RADIUS+2.0+23.0)
						var arrow_vector_1: Vector2 = angle_vector.rotated(deg_to_rad(90+45))
						var arrow_vector_2: Vector2 = angle_vector.rotated(deg_to_rad(-45-90))
						self.draw_line(arrow_pos, arrow_pos + 20.0 * arrow_vector_1, SELECTED_COLOUR, 2.0, true)
						self.draw_line(arrow_pos, arrow_pos + 20.0 * arrow_vector_2, SELECTED_COLOUR, 2.0, true)
				elif self.highlighted["highlight_type"] == "starpath" and self.highlighted["highlight_id"] == starpath:
					self.draw_line(system.pos, neighbour.pos, HIGHLIGHTED_COLOUR, 4.0, true)
				else:
					self.draw_dashed_line(system.pos, neighbour.pos, NEUTRAL_COLOUR, 0.5, 4.0, true, true)
				#TODO: draw the starpath in green if the selection has exactly the two systems in the starpath selected
			
		for system in self.galaxy.systems:
			
			var owner_colour: Color = galaxy.players[system.player_id].colour
			
			self.draw_circle(system.pos, SYSTEM_RADIUS+2.0+23.0, Color.BLACK, true, -1.0, true)
			
			if self.highlighted["highlight_type"] == "system" and self.highlighted["highlight_id"] == system.sys_id:
				self.draw_circle(system.pos, SYSTEM_RADIUS, HIGHLIGHTED_COLOUR, false, 4.0, true)
			elif selected.get_system_index(self.galaxy, system) != -1:
				#print(selected.get_system_index(self.galaxy, system))
				self.draw_circle(system.pos, SYSTEM_RADIUS, SELECTED_COLOUR, false, 4.0, true)
			else:
				self.draw_circle(system.pos, SYSTEM_RADIUS, owner_colour, false, 2.0, true)
			#self.draw_string(get_theme_default_font(), system.pos, str(system.sys_id))
			
			var construction_type: StarSystem.CONSTRUCTIONS
			construction_type = system.construction
			#construction_type = StarSystem.CONSTRUCTIONS.values().pick_random()
			var polygon: PackedVector2Array = display_polygons[construction_type].duplicate()
			for i in range(polygon.size()):
				var vec: Vector2 = polygon[i]
				vec = vec * SYSTEM_RADIUS * 0.55
				vec += system.pos
				polygon.set(i, vec)
			
			if polygon.size() > 2:
				self.draw_polyline(polygon, owner_colour, 1.0, true)
			else:
				var line_mult: float =  SYSTEM_RADIUS * 0.55
				self.draw_line(system.pos+Vector2(-1, -1)*line_mult, system.pos+Vector2(1, 1)*line_mult, owner_colour, 1.0, true)
				self.draw_line(system.pos+Vector2(-1, 1)*line_mult, system.pos+Vector2(1, -1)*line_mult, owner_colour, 1.0, true)
			
			var ships_dict: Dictionary = galaxy.get_ships_in_system(system.sys_id)
			
			const max_ships: int = 45
			var ship_start_radius: float = SYSTEM_RADIUS + 5.0
			var ship_radius: float = ship_start_radius + 12.0
	
			var num_ships: int = 0
			var num_reserved_ships: int = galaxy.get_reserved_ships(system.sys_id, action_queue)
			
			#TODO: check highlighted ships in the selection as well
	
			for player_id in ships_dict.keys():
				for i in range(0, ships_dict[player_id].size()):
						var ship: Ship = ships_dict[player_id][i]
						var angle: float = num_ships * 360 / max_ships - 90
						angle = deg_to_rad(angle)
						var ship_colour: Color = self.galaxy.players[ship.player_id].colour
						if player_id == galaxy.player_id and i < num_reserved_ships:
							ship_colour = SELECTED_COLOUR
						
						var ship_dir: Vector2 = Vector2(cos(angle), sin(angle))
				
						self.draw_line(system.pos+ship_start_radius*ship_dir, system.pos+ship_radius*ship_dir, ship_colour, 1.0, true)
						num_ships += 1

		#var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		#self.draw_circle(mouse_pos, 5.0, Color.PURPLE, false, 2.0, true)

		#var draw_scale: Vector2 = self.size / galaxy.size
		for key in self.galaxy.invalid_paths:
			
			#self.draw_circle(key * draw_scale, 9.0, Color.RED)
			#self.draw_line(self.galaxy.invalid_paths[key][0] * draw_scale, self.galaxy.invalid_paths[key][1] * draw_scale, Color.RED)
			pass
