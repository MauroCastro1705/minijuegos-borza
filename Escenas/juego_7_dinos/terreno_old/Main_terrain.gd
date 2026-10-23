extends Node2D


@export var quadrant_size: int = 100
@export var quadrant_grid_size: Vector2i = Vector2i(10, 5)
@export var carve_radius: int = 40
@export var min_movement_update: int = 5
@export var use_drawn_polygon: bool = false
@onready var drawn_polygon: Polygon2D = $Drawn_polygon


var old_mouse_pos: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO

var quadrants_grid: Array = []
var drawn_pieces: Array[PackedVector2Array] = []

@onready var carve_area: Polygon2D = $CarveArea
var Quadrant = preload("res://Escenas/juego_7_dinos/terreno/Quadrant.tscn")
var Rigid = preload("res://Escenas/juego_7_dinos/terreno/RigidBody.tscn")
var TerrainTexture = preload("res://Escenas/juego_7_dinos/terreno/texture.png")


func _ready():
	drawn_polygon.visible = use_drawn_polygon
	if drawn_polygon.texture == null:
		drawn_polygon.texture = TerrainTexture
	_spawn_quadrants()
	if use_drawn_polygon:
		_init_drawn_polygon()
	_make_mouse_circle()


func _process(_delta):
	if Input.is_action_pressed("left_click"):
		if old_mouse_pos.distance_to(mouse_pos) > min_movement_update:
			_carve()
			old_mouse_pos = mouse_pos
	
	elif Input.is_action_pressed("right_click"):
		if old_mouse_pos.distance_to(mouse_pos) > min_movement_update:
			_add()
			old_mouse_pos = mouse_pos
	
	if Input.is_action_pressed("ui_accept"):
		var rigid := Rigid.instantiate() as RigidBody2D
		rigid.position = get_global_mouse_position() + Vector2(randi()%10,0)
		$RigidBodies.add_child(rigid)


func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = get_global_mouse_position()
		carve_area.position = mouse_pos


func _spawn_quadrants():
	for i in range(quadrant_grid_size.x):
		quadrants_grid.push_back([])
		for j in range(quadrant_grid_size.y):
			var quadrant: Variant = Quadrant.instantiate()
			quadrant.show_polygon_visuals = not use_drawn_polygon
			var polygon := PackedVector2Array([
				Vector2(quadrant_size*i,quadrant_size*j),
				Vector2(quadrant_size*(i+1),quadrant_size*j),
				Vector2(quadrant_size*(i+1),quadrant_size*(j+1)),
				Vector2(quadrant_size*i,quadrant_size*(j+1))
			])
			quadrant.default_quadrant_polygon = polygon
			quadrants_grid[-1].push_back(quadrant)
			$Quadrants.add_child(quadrant)


func _make_mouse_circle():
	var nb_points = 15
	var pol := PackedVector2Array()
	for i in range(nb_points):
		var angle = lerp(-PI, PI, float(i)/nb_points)
		pol.append(Vector2(cos(angle), sin(angle)) * carve_radius)
	carve_area.polygon = pol


func _carve():
	var mouse_polygon = _get_global_carve_polygon()
	var four_quadrants = _get_affected_quadrants(mouse_pos)
	for quadrant in four_quadrants:
		quadrant.carve(mouse_polygon)
	if use_drawn_polygon:
		_carve_drawn_polygon(mouse_polygon)


func _add():
	var mouse_polygon = _get_global_carve_polygon()
	var four_quadrants = _get_affected_quadrants(mouse_pos)
	for quadrant in four_quadrants:
		quadrant.add(mouse_polygon)


func _get_global_carve_polygon() -> PackedVector2Array:
	var polygon := PackedVector2Array()
	var transformar = Transform2D(0.0, mouse_pos)
	for point in carve_area.polygon:
		polygon.append(transformar * point)
	return polygon


func _init_drawn_polygon() -> void:
	var terrain_width := quadrant_size * quadrant_grid_size.x
	var terrain_height := quadrant_size * quadrant_grid_size.y
	drawn_pieces = [PackedVector2Array([
		Vector2.ZERO,
		Vector2(terrain_width, 0),
		Vector2(terrain_width, terrain_height),
		Vector2(0, terrain_height)
	])]
	_render_drawn_pieces()


func _carve_drawn_polygon(global_clipping_polygon: PackedVector2Array) -> void:
	var clipping_polygon := PackedVector2Array()
	for point in global_clipping_polygon:
		clipping_polygon.append(to_local(point))

	var remaining_pieces: Array[PackedVector2Array] = []
	for piece in drawn_pieces:
		var clipped_pieces := Geometry2D.clip_polygons(piece, clipping_polygon)
		var has_hole := false
		for clipped_piece in clipped_pieces:
			if Geometry2D.is_polygon_clockwise(clipped_piece):
				has_hole = true
				break

		if has_hole:
			remaining_pieces.append_array(_split_drawn_piece(piece, clipping_polygon))
		else:
			remaining_pieces.append_array(clipped_pieces)

	drawn_pieces = remaining_pieces
	_render_drawn_pieces()


func _split_drawn_piece(piece: PackedVector2Array, clipping_polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var min_x := piece[0].x
	var max_x := piece[0].x
	var min_y := piece[0].y
	var max_y := piece[0].y
	var clipping_center_x := 0.0
	for point in piece:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	for point in clipping_polygon:
		clipping_center_x += point.x
	clipping_center_x /= clipping_polygon.size()

	var left_polygon := PackedVector2Array([
		Vector2(min_x, min_y),
		Vector2(clipping_center_x, min_y),
		Vector2(clipping_center_x, max_y),
		Vector2(min_x, max_y)
	])
	var right_polygon := PackedVector2Array([
		Vector2(clipping_center_x, min_y),
		Vector2(max_x, min_y),
		Vector2(max_x, max_y),
		Vector2(clipping_center_x, max_y)
	])
	var split_pieces: Array[PackedVector2Array] = []
	for half_polygon in [left_polygon, right_polygon]:
		for remaining_half in Geometry2D.clip_polygons(half_polygon, clipping_polygon):
			split_pieces.append_array(Geometry2D.intersect_polygons(piece, remaining_half))
	return split_pieces


func _render_drawn_pieces() -> void:
	for child in drawn_polygon.get_children():
		drawn_polygon.remove_child(child)
		child.queue_free()

	if drawn_pieces.is_empty():
		drawn_polygon.polygon = PackedVector2Array()
		return

	drawn_polygon.polygon = drawn_pieces[0]
	for i in range(1, drawn_pieces.size()):
		var fragment := drawn_polygon.duplicate() as Polygon2D
		fragment.name = "DrawnPolygonFragment%d" % i
		fragment.polygon = drawn_pieces[i]
		drawn_polygon.add_child(fragment)


func _get_affected_quadrants(pos: Vector2) -> Array:
	"""
	Returns array of Quadrants that are affected by
	the carving. Not the best function: sometimes it
	returns some quadrants that are not affected
	"""
	var affected_quadrants: Array = []
	var half_diag = sqrt(2)*quadrant_size/2
	for quadrant_node in $Quadrants.get_children():
		var quadrant := quadrant_node as Node2D
		var quadrant_polygon: PackedVector2Array = quadrant.get("default_quadrant_polygon")
		var quadrant_top_left = quadrant_polygon[0]
		var quadrant_center = quadrant_top_left + Vector2(quadrant_size, quadrant_size)/2
		if quadrant_center.distance_to(pos) <= carve_radius + half_diag:
			affected_quadrants.push_back(quadrant)
	return affected_quadrants
