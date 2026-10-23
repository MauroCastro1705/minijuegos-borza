extends Node2D

signal excavated(fossil_texture: Texture2D, score_award: int)

enum ExcavationState {
	BURIED,
	EXCAVATED
}

@export var fossil_texture: Texture2D
@export_range(0, 100000, 1) var score_value: int = 100

@onready var texture_rect: TextureRect = $TextureRect
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

var state: ExcavationState = ExcavationState.BURIED
var _cells_to_mine: Dictionary[Vector2i, bool] = {}


func _ready() -> void:
	if fossil_texture != null:
		texture_rect.texture = fossil_texture
	else:
		fossil_texture = texture_rect.texture


func setup_excavation(tile_map_layer: TileMapLayer) -> void:
	_cells_to_mine.clear()
	state = ExcavationState.BURIED

	var rectangle := collision_shape_2d.shape as RectangleShape2D
	if rectangle == null:
		push_error("Fossil excavation requires a RectangleShape2D collision shape.")
		return

	var half_size := rectangle.size / 2.0
	var fossil_polygon := PackedVector2Array()
	for corner in [
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	]:
		var global_corner: Vector2 = collision_shape_2d.global_transform * corner
		fossil_polygon.append(tile_map_layer.to_local(global_corner))

	var tile_size := Vector2(tile_map_layer.tile_set.tile_size)
	for cell in tile_map_layer.get_used_cells():
		var center := tile_map_layer.map_to_local(cell)
		var tile_polygon := PackedVector2Array([
			center + Vector2(-tile_size.x, -tile_size.y) / 2.0,
			center + Vector2(tile_size.x, -tile_size.y) / 2.0,
			center + tile_size / 2.0,
			center + Vector2(-tile_size.x, tile_size.y) / 2.0
		])
		if not Geometry2D.intersect_polygons(fossil_polygon, tile_polygon).is_empty():
			_cells_to_mine[cell] = true

	if _cells_to_mine.is_empty():
		push_warning("Fossil has no terrain tiles in its excavation area.")


func on_tile_mined(cell: Vector2i) -> void:
	if state != ExcavationState.BURIED or not _cells_to_mine.has(cell):
		return

	_cells_to_mine.erase(cell)
	if _cells_to_mine.is_empty():
		_mark_excavated()


func get_fossil_texture() -> Texture2D:
	return fossil_texture


func _mark_excavated() -> void:
	if state == ExcavationState.EXCAVATED:
		return

	state = ExcavationState.EXCAVATED
	disappear()
	excavated.emit(get_fossil_texture(), score_value)


func disappear() -> void:
	hide()
	area_2d.monitoring = false
	area_2d.monitorable = false
	collision_shape_2d.set_deferred("disabled", true)
