extends Node2D

signal excavated(fossil_texture: Texture2D, score_award: int, fossil_global_position: Vector2)
@onready var excavated_effect: CPUParticles2D = $excavated_effect

enum ExcavationState {
	BURIED,
	EXCAVATED
}

@export var fossil_texture: Texture2D
@export_range(0, 100000, 1) var score_value: int = 100

@onready var texture_rect: TextureRect = $TextureRect
@onready var area_2d: Area2D = $Area2D
@onready var collision_polygon_2d: CollisionPolygon2D = $Area2D/CollisionPolygon2D

var state: ExcavationState = ExcavationState.BURIED
var _cells_to_mine: Dictionary[Vector2i, bool] = {}


func _ready() -> void:
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fossil_texture != null:
		texture_rect.texture = fossil_texture
	else:
		fossil_texture = texture_rect.texture


func setup_excavation(tile_map_layer: TileMapLayer) -> void:
	_cells_to_mine.clear()
	state = ExcavationState.BURIED

	if collision_polygon_2d.polygon.size() < 3:
		push_error("Fossil excavation requires a CollisionPolygon2D with at least three points.")
		return

	var fossil_polygon := PackedVector2Array()
	for point in collision_polygon_2d.polygon:
		var global_point: Vector2 = collision_polygon_2d.global_transform * point
		fossil_polygon.append(tile_map_layer.to_local(global_point))

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
	animate_excavation()
	excavated.emit(get_fossil_texture(), score_value, global_position)


func animate_excavation() -> void:
	area_2d.monitoring = false
	area_2d.monitorable = false
	collision_polygon_2d.set_deferred("disabled", true)
	show()
	z_index = 1

	var tween := create_tween()
	excavated_effect.emitting = true
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2.UP * 32.0, 0.18)
	tween.tween_property(self, "scale", scale * 1.2, 0.18)

	tween.chain().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", position + Vector2.UP * 48.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(hide)
