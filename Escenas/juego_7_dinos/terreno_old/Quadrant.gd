extends Node2D

var default_quadrant_polygon: PackedVector2Array = PackedVector2Array()
var show_polygon_visuals: bool = true
@onready var static_body: StaticBody2D = $StaticBody2D
var ColPol = preload("res://Escenas/juego_7_dinos/terreno/ColPol.tscn")

func _ready():
	init_quadrant()


func init_quadrant():
	"""
	Initiates the default (square) ColPol
	"""
	static_body.add_child(_new_colpol(default_quadrant_polygon))


func reset_quadrant():
	"""
	Removes all collision polygons
	and initiates the default ColPol
	"""
	for colpol in static_body.get_children():
		colpol.free()
	init_quadrant()


func carve(clipping_polygon: PackedVector2Array) -> void:
	"""
	Carves the clipping_polygon away from the quadrant
	"""
	for colpol_node in static_body.get_children():
		var colpol := colpol_node as CollisionPolygon2D
		var colpol_polygon := colpol.polygon
		var clipped_polygons = Geometry2D.clip_polygons(colpol_polygon, clipping_polygon)
		var n_clipped_polygons = len(clipped_polygons)
		match n_clipped_polygons:
			0:
				# clipping_polygon completely overlaps colpol
				colpol.free()
			1:
				# Clipping produces only one polygon
				colpol.call("update_pol", clipped_polygons[0])
			2:
				# Check if you carved a hole (one of the two polygons
				# is clockwise). If so, split the polygon in two that
				# together make a "hollow" collision shape
				if _is_hole(clipped_polygons):
					# split and add
					for p in _split_polygon(clipping_polygon):
						for intersection in Geometry2D.intersect_polygons(p, colpol_polygon):
							static_body.add_child(_new_colpol(intersection))
					colpol.free()
				# if its not a hole, behave as in match _
				else:
					colpol.call("update_pol", clipped_polygons[0])
					for i in range(n_clipped_polygons-1):
						static_body.add_child(_new_colpol(clipped_polygons[i+1]))
			
			# if more than two polygons, simply add all of
			# them to the quadrant
			_:
				colpol.call("update_pol", clipped_polygons[0])
				for i in range(n_clipped_polygons-1):
					static_body.add_child(_new_colpol(clipped_polygons[i+1]))


func add(_adding_polygon: PackedVector2Array) -> void:
	"""
	TODO
	"""
	pass


func _split_polygon(clip_polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	"""
	Returns two polygons produced by vertically
	splitting split_polygon in half
	"""
	var avg_x = _avg_position(clip_polygon).x
	var left_subquadrant: PackedVector2Array = default_quadrant_polygon.duplicate()
	left_subquadrant[1] = Vector2(avg_x, left_subquadrant[1].y)
	left_subquadrant[2] = Vector2(avg_x, left_subquadrant[2].y)
	var right_subquadrant: PackedVector2Array = default_quadrant_polygon.duplicate()
	right_subquadrant[0] = Vector2(avg_x, right_subquadrant[0].y)
	right_subquadrant[3] = Vector2(avg_x, right_subquadrant[3].y)
	var polygons: Array[PackedVector2Array] = []
	polygons.append_array(Geometry2D.clip_polygons(left_subquadrant, clip_polygon))
	polygons.append_array(Geometry2D.clip_polygons(right_subquadrant, clip_polygon))
	return polygons


func _is_hole(clipped_polygons: Array[PackedVector2Array]) -> bool:
	"""
	If either of the two polygons after clipping
	are clockwise, then you have carved a hole
	"""
	return Geometry2D.is_polygon_clockwise(clipped_polygons[0]) or Geometry2D.is_polygon_clockwise(clipped_polygons[1])


func _avg_position(array: PackedVector2Array) -> Vector2:
	"""
	Average 2D position in an
	array of positions
	"""
	var sum := Vector2.ZERO
	for p in array:
		sum += p
	return sum / array.size()


func _new_colpol(polygon: PackedVector2Array) -> CollisionPolygon2D:
	"""
	Returns ColPol instance
	with assigned polygon
	"""
	var colpol := ColPol.instantiate() as CollisionPolygon2D
	colpol.polygon = polygon
	colpol.get_node("Polygon2D").visible = show_polygon_visuals
	return colpol
