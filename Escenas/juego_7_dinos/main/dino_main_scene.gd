extends Node2D

signal tile_damaged(cell: Vector2i, remaining_health: int)
signal tile_mined(cell: Vector2i)
signal score_changed(new_score: int)
signal fossil_excavated(fossil_texture: Texture2D, score_awarded: int, total_score: int)
@onready var score_label: Label = %score_label

@onready var fossils_area: Area2D = $Fossils_area

@export_range(1, 100, 1) var mining_power: int = 1
@export_range(1, 100, 1) var tile_health: int = 1
@export_range(0, 31, 1) var terrain_set_id: int = 0
@export_range(0, 255, 1) var terrain_id: int = 0
@export_range(0, 50, 1) var fossil_spawn_count: int = 5
@export_range(0.0, 256.0, 1.0) var fossil_spacing: float = 24.0
@export_range(1, 500, 1) var fossil_placement_attempts: int = 100

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var fosiles: Node2D = $fosiles
@onready var fossil_area_shape: CollisionShape2D = $Fossils_area/CollisionShape2D

@export var fossil_1:PackedScene
@export var fossil_2:PackedScene
@export var fossil_3:PackedScene
@export var fossil_4:PackedScene
@export var fossil_5:PackedScene
@export var fossil_6:PackedScene
@export var fossil_7:PackedScene

var fossils_array: Array[PackedScene] = []

var _tile_health_by_cell: Dictionary[Vector2i, int] = {}
var score: int = 0


func _ready() -> void:
	update_score()
	_build_fossils_array()
	_spawn_fossils()

	for fossil_node in fosiles.get_children():
		var fossil := fossil_node as Node
		if not fossil.has_method("on_tile_mined") \
		or not fossil.has_method("setup_excavation") \
		or not fossil.has_signal("excavated"):
			push_error("Every child of fosiles must support fossil excavation.")
			continue

		tile_mined.connect(Callable(fossil, "on_tile_mined"))
		fossil.connect("excavated", Callable(self, "_on_fossil_excavated"))
		fossil.call("setup_excavation", tile_map_layer)


func _build_fossils_array() -> void:
	fossils_array.clear()
	for fossil_scene in [fossil_1, fossil_2, fossil_3, fossil_4, fossil_5, fossil_6, fossil_7]:
		if fossil_scene != null:
			fossils_array.append(fossil_scene)


func _spawn_fossils() -> void:
	if fossils_array.is_empty():
		if fossil_spawn_count > 0:
			push_error("Cannot spawn fossils: assign at least one fossil scene.")
		return

	var rectangle := fossil_area_shape.shape as RectangleShape2D
	if rectangle == null:
		push_error("Fossils_area requires a RectangleShape2D collision shape.")
		return

	var area_rect := Rect2(fossil_area_shape.position - rectangle.size / 2.0, rectangle.size)
	var spawned_outlines: Array[PackedVector2Array] = []

	for _i in range(fossil_spawn_count):
		var fossil_scene = fossils_array.pick_random()
		var fossil := fossil_scene.instantiate() as Node2D
		var outline := _get_fossil_outline(fossil)
		if outline.size() < 3:
			push_error("Fossil scene '%s' has no valid CollisionPolygon2D outline." % fossil_scene.resource_path)
			fossil.free()
			continue

		var placed := false
		for _attempt in range(fossil_placement_attempts):
			var area_position := Vector2(
				randf_range(area_rect.position.x, area_rect.end.x),
				randf_range(area_rect.position.y, area_rect.end.y)
			)
			var candidate_global := fossils_area.to_global(area_position)
			var candidate_position := fosiles.to_local(candidate_global)
			var candidate_outline := _offset_polygon(outline, candidate_position)
			if not _polygon_fits_in_area(candidate_outline, area_rect):
				continue
			if _overlaps_spawned_fossil(candidate_outline, spawned_outlines):
				continue

			fossil.position = candidate_position
			fosiles.add_child(fossil)
			spawned_outlines.append(candidate_outline)
			placed = true
			break

		if not placed:
			push_warning("Could not find a non-overlapping position for fossil '%s'." % fossil_scene.resource_path)
			fossil.free()


func _get_fossil_outline(fossil: Node2D) -> PackedVector2Array:
	var collision := fossil.get_node_or_null("Area2D/CollisionPolygon2D") as CollisionPolygon2D
	if collision == null:
		return PackedVector2Array()

	var outline := PackedVector2Array()
	for point in collision.polygon:
		outline.append(fossil.to_local(collision.to_global(point)))
	return outline


func _offset_polygon(polygon: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in polygon:
		result.append(point + offset)
	return result


func _polygon_fits_in_area(polygon: PackedVector2Array, area_rect: Rect2) -> bool:
	for point in polygon:
		var area_point := fossils_area.to_local(fosiles.to_global(point))
		if not area_rect.has_point(area_point):
			return false
	return true


func _overlaps_spawned_fossil(polygon: PackedVector2Array, spawned_outlines: Array[PackedVector2Array]) -> bool:
	var polygon_bounds := _get_polygon_bounds(polygon).grow(fossil_spacing / 2.0)
	for spawned_outline in spawned_outlines:
		var spawned_bounds := _get_polygon_bounds(spawned_outline).grow(fossil_spacing / 2.0)
		if polygon_bounds.intersects(spawned_bounds):
			return true
	return false


func _get_polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	return bounds


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		mine_at_global_position(get_global_mouse_position())


func mine_at_global_position(global_position_new: Vector2) -> bool:
	var local_position := tile_map_layer.to_local(global_position_new)
	var cell := tile_map_layer.local_to_map(local_position)
	return mine_cell(cell)


func mine_cell(cell: Vector2i) -> bool:
	if tile_map_layer.get_cell_source_id(cell) < 0:
		_tile_health_by_cell.erase(cell)
		return false

	var remaining_health: int = _tile_health_by_cell.get(cell, tile_health)
	remaining_health -= mining_power
	if remaining_health > 0:
		_tile_health_by_cell[cell] = remaining_health
		tile_damaged.emit(cell, remaining_health)
		return false

	tile_map_layer.erase_cell(cell)
	_tile_health_by_cell.erase(cell)
	_update_surrounding_terrain(cell)
	tile_mined.emit(cell)
	_play_cell_destroy_particles(tile_map_layer.to_global(tile_map_layer.map_to_local(cell)))
	return true


func _play_cell_destroy_particles(_global_position: Vector2) -> void:
	pass


func _update_surrounding_terrain(cell: Vector2i) -> void:
	var connected_cells: Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue

			var neighbor := cell + Vector2i(x, y)
			if tile_map_layer.get_cell_source_id(neighbor) < 0:
				continue

			var tile_data := tile_map_layer.get_cell_tile_data(neighbor)
			if tile_data == null or tile_data.terrain_set != terrain_set_id:
				continue

			connected_cells.append(neighbor)

	for connected_cell in connected_cells:
		tile_map_layer.set_cells_terrain_connect([connected_cell], terrain_set_id, terrain_id, false)


func _on_fossil_excavated(
	fossil_texture: Texture2D,
	score_awarded: int,
	fossil_global_position: Vector2
) -> void:
	score += score_awarded
	update_score()
	fossil_excavated.emit(fossil_texture, score_awarded, score)
	_play_fossil_excavated_particles(fossil_global_position, fossil_texture)
	print("excavaste: " + str(score))


func update_score():
	score_label.text = "Puntaje: " + str(score)
	score_changed.emit(score)

func _play_fossil_excavated_particles(_global_position: Vector2,_fossil_texture: Texture2D
) -> void:
	pass


func apply_mining_upgrade(power_increase: int) -> void:
	if power_increase <= 0:
		push_error("Mining upgrade power must be greater than zero.")
		return
	mining_power += power_increase
