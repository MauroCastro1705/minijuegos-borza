extends Node2D

signal tile_damaged(cell: Vector2i, remaining_health: int)
signal tile_mined(cell: Vector2i)
signal score_changed(new_score: int)
signal fossil_excavated(fossil_texture: Texture2D, score_awarded: int, total_score: int)

@export_range(1, 100, 1) var mining_power: int = 1
@export_range(1, 100, 1) var tile_health: int = 1
@export_range(0, 31, 1) var terrain_set_id: int = 0
@export_range(0, 255, 1) var terrain_id: int = 0

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var fosiles: Node2D = $fosiles

var _tile_health_by_cell: Dictionary[Vector2i, int] = {}
var score: int = 0


func _ready() -> void:
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
	return true


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


func _on_fossil_excavated(fossil_texture: Texture2D, score_awarded: int) -> void:
	score += score_awarded
	score_changed.emit(score)
	fossil_excavated.emit(fossil_texture, score_awarded, score)


func apply_mining_upgrade(power_increase: int) -> void:
	if power_increase <= 0:
		push_error("Mining upgrade power must be greater than zero.")
		return
	mining_power += power_increase
