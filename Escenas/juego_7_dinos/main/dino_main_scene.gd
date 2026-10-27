extends Node2D

signal tile_damaged(cell: Vector2i, remaining_health: int)
signal tile_mined(cell: Vector2i)
signal score_changed(new_score: int)
signal fossil_excavated(fossil_texture: Texture2D, score_awarded: int, total_score: int)
@onready var score_label: Label = %score_label
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var pickaxe: TextureRect = $pickaxe

@onready var fossils_area: Area2D = $Fossils_area

var picar_piedra: PackedScene = preload("res://particulas/picar_piedra.tscn")
var _pickaxe_swing_tween: Tween

@export_group("Mining")
@export_range(1, 100, 1) var mining_power: int = 1
@export_range(1, 100, 1) var tile_health: int = 1
@export_range(0, 100, 1) var max_damage_numbers_per_swing: int = 5
@export_range(0.0, 1.0, 0.05) var damaged_tile_darkening: float = 0.4

@export_group("Progression")
@export_range(1, 10000, 1) var starting_level: int = 1
@export_range(0, 10000, 1) var tile_health_increase_per_level: int = 1
@export_range(0, 100000, 1) var dirt_money_reward: int = 1
@export_range(0, 100000, 1) var fossil_money_reward: int = 50
@export_range(0.0, 10.0, 0.05) var level_transition_delay: float = 0.4

@export_group("Terrain")
@export_range(0, 31, 1) var terrain_set_id: int = 0
@export_range(0, 255, 1) var terrain_id: int = 0

@export_group("Fossil spawning")
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
@onready var level_label: Label = %level_label
@onready var damage_label: Label = %damage
@onready var size_label: Label = %size
@onready var multiplier_label: Label = %multiplier
@onready var upgrade_1: Button = %upgrade_1
@onready var upgrade_2: Button = %upgrade_2
@onready var upgrade_3: Button = %upgrade_3
@onready var money_label: Label = %money_label
@onready var money_texture: TextureRect = $money/money_texture



var fossils_array: Array[PackedScene] = []

var _tile_health_by_cell: Dictionary[Vector2i, int] = {}
var _damaged_tile_overlays: Dictionary[Vector2i, Polygon2D] = {}
var _initial_tile_data: Dictionary = {}
var score: int = 0
var money: int = 0
var level: int = 1
var money_multiplier: int = 1
var mining_width: int = 1
var mining_height: int = 1
var _remaining_fossils: int = 0
var _level_transition_pending: bool = false
var damage_upgrade_cost: int = 10
var size_upgrade_cost: int = 25
var multiplier_upgrade_cost: int = 50


func _ready() -> void:
	canvas_layer.show()
	#level_texture.hide()
	pickaxe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pickaxe.z_index = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_update_pickaxe_position()
	level = starting_level
	_capture_initial_terrain()
	update_score()
	_update_upgrade_ui()
	_build_fossils_array()
	_spawn_fossils()
	_setup_fossils()


func _setup_fossils() -> void:
	_remaining_fossils = 0
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
		_remaining_fossils += 1


func _capture_initial_terrain() -> void:
	_initial_tile_data.clear()
	for cell in tile_map_layer.get_used_cells():
		_initial_tile_data[cell] = {
			"source_id": tile_map_layer.get_cell_source_id(cell),
			"atlas_coords": tile_map_layer.get_cell_atlas_coords(cell),
			"alternative_tile": tile_map_layer.get_cell_alternative_tile(cell)
		}


func _process(_delta: float) -> void:
	_update_pickaxe_position()


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _update_pickaxe_position() -> void:
	pickaxe.position = get_global_mouse_position() - pickaxe.pivot_offset


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
		if _level_transition_pending:
			return
		_swing_pickaxe()
		mine_at_global_position(get_global_mouse_position())


func _swing_pickaxe() -> void:
	if _pickaxe_swing_tween != null and _pickaxe_swing_tween.is_running():
		_pickaxe_swing_tween.kill()

	pickaxe.rotation = 0.0
	_pickaxe_swing_tween = create_tween()
	_pickaxe_swing_tween.tween_property(pickaxe, "rotation", deg_to_rad(-45.0), 0.04)
	_pickaxe_swing_tween.tween_property(pickaxe, "rotation", deg_to_rad(18.0), 0.08)
	_pickaxe_swing_tween.tween_property(pickaxe, "rotation", 0.0, 0.1)


func mine_at_global_position(global_position_new: Vector2) -> bool:
	var local_position := tile_map_layer.to_local(global_position_new)
	var cell := tile_map_layer.local_to_map(local_position)

	var mined_any := false
	var damage_numbers_displayed := 0
	@warning_ignore("integer_division")
	var start_cell := cell - Vector2i(mining_width / 2, mining_height / 2)
	for y in range(start_cell.y, start_cell.y + mining_height):
		for x in range(start_cell.x, start_cell.x + mining_width):
			var target_cell := Vector2i(x, y)
			var has_dirt := tile_map_layer.get_cell_source_id(target_cell) >= 0
			var show_damage_number := damage_numbers_displayed < max_damage_numbers_per_swing
			if has_dirt and show_damage_number:
				damage_numbers_displayed += 1
			if not mine_cell(target_cell, show_damage_number):
				continue

			var cell_position := tile_map_layer.to_global(tile_map_layer.map_to_local(target_cell))
			_play_cell_destroy_particles(cell_position)
			mined_any = true

	return mined_any


func mine_cell(cell: Vector2i, show_damage_number: bool = true) -> bool:
	if tile_map_layer.get_cell_source_id(cell) < 0:
		_tile_health_by_cell.erase(cell)
		return false

	var level_tile_health := tile_health + (level - 1) * tile_health_increase_per_level
	var remaining_health: int = _tile_health_by_cell.get(cell, level_tile_health)
	var damage_dealt: int = mini(mining_power, remaining_health)
	var cell_global_position := tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
	if show_damage_number:
		DamageNumbers.display_numbers(damage_dealt, cell_global_position)
	remaining_health -= mining_power
	if remaining_health > 0:
		_tile_health_by_cell[cell] = remaining_health
		_darkened_tile(cell)
		tile_damaged.emit(cell, remaining_health)
		return false

	tile_map_layer.erase_cell(cell)
	_tile_health_by_cell.erase(cell)
	_clear_damaged_tile_overlay(cell)
	_update_surrounding_terrain(cell)
	money += dirt_money_reward
	_update_upgrade_ui()
	tile_mined.emit(cell)
	return true


func _darkened_tile(cell: Vector2i) -> void:
	if _damaged_tile_overlays.has(cell):
		return

	var tile_size := Vector2(tile_map_layer.tile_set.tile_size)
	var half_tile := tile_size / 2.0
	var center := tile_map_layer.map_to_local(cell)
	var overlay := Polygon2D.new()
	overlay.polygon = PackedVector2Array([
		center + Vector2(-half_tile.x, -half_tile.y),
		center + Vector2(half_tile.x, -half_tile.y),
		center + Vector2(half_tile.x, half_tile.y),
		center + Vector2(-half_tile.x, half_tile.y)
	])
	overlay.color = Color(0.0, 0.0, 0.0, damaged_tile_darkening)
	overlay.z_index = 1
	tile_map_layer.add_child(overlay)
	_damaged_tile_overlays[cell] = overlay


func _clear_damaged_tile_overlay(cell: Vector2i) -> void:
	var overlay := _damaged_tile_overlays.get(cell) as Polygon2D
	if overlay == null:
		return

	overlay.queue_free()
	_damaged_tile_overlays.erase(cell)


func _play_cell_destroy_particles(global_position_new: Vector2) -> void:
	var particles := picar_piedra.instantiate() as CPUParticles2D
	add_child(particles)
	particles.global_position = global_position_new
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


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
	money += fossil_money_reward * money_multiplier
	update_score()
	_update_upgrade_ui()
	fossil_excavated.emit(fossil_texture, score_awarded, score)
	_play_fossil_excavated_particles(fossil_global_position, fossil_texture)
	print("excavaste: " + str(score))
	_remaining_fossils -= 1
	if _remaining_fossils == 0 and not _level_transition_pending:
		_level_transition_pending = true
		call_deferred("_start_next_level")


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
	_update_upgrade_ui()


func _on_upgrade_1_pressed() -> void:
	if not _try_purchase_upgrade(damage_upgrade_cost):
		return

	apply_mining_upgrade(1)
	damage_upgrade_cost = _get_next_upgrade_cost(damage_upgrade_cost)
	_update_upgrade_ui()


func _on_upgrade_2_pressed() -> void:
	if not _try_purchase_upgrade(size_upgrade_cost):
		return

	if mining_width == mining_height:
		mining_height += 1
	else:
		mining_width += 1
	size_upgrade_cost = _get_next_upgrade_cost(size_upgrade_cost)
	_update_upgrade_ui()


func _on_upgrade_3_pressed() -> void:
	if not _try_purchase_upgrade(multiplier_upgrade_cost):
		return

	money_multiplier *= 2
	multiplier_upgrade_cost = _get_next_upgrade_cost(multiplier_upgrade_cost)
	_update_upgrade_ui()


func _try_purchase_upgrade(cost: int) -> bool:
	if money < cost:
		return false

	money -= cost
	_update_upgrade_ui()
	return true


func _get_next_upgrade_cost(current_cost: int) -> int:
	return ceili(current_cost * 1.5)


func _start_next_level() -> void:
	await get_tree().create_timer(level_transition_delay).timeout

	level += 1
	_tile_health_by_cell.clear()
	for overlay_value in _damaged_tile_overlays.values():
		var overlay := overlay_value as Polygon2D
		if is_instance_valid(overlay):
			overlay.queue_free()
	_damaged_tile_overlays.clear()
	var terrain_tint := tile_map_layer.self_modulate
	tile_map_layer.self_modulate = Color(terrain_tint.r, terrain_tint.g, terrain_tint.b, 0.0)
	tile_map_layer.clear()
	for cell_variant in _initial_tile_data:
		var cell: Vector2i = cell_variant
		var tile: Dictionary = _initial_tile_data[cell]
		var source_id: int = tile["source_id"]
		var atlas_coords: Vector2i = tile["atlas_coords"]
		var alternative_tile: int = tile["alternative_tile"]
		tile_map_layer.set_cell(
			cell,
			source_id,
			atlas_coords,
			alternative_tile
		)

	var terrain_tween := create_tween()
	terrain_tween.tween_property(tile_map_layer, "self_modulate", terrain_tint, 0.35)
	await terrain_tween.finished

	for fossil_node in fosiles.get_children():
		fosiles.remove_child(fossil_node)
		fossil_node.queue_free()

	_spawn_fossils()
	_setup_fossils()
	_level_transition_pending = false
	_update_upgrade_ui()


func _update_upgrade_ui() -> void:
	money_label.text = str(money)
	level_label.text = "Level: %d" % level
	damage_label.text = "Damage: %d" % mining_power
	size_label.text = "Size: %dx%d" % [mining_width, mining_height]
	multiplier_label.text = "Multiplier: x%d" % money_multiplier

	upgrade_1.text = "Damage +1 ($%d)" % damage_upgrade_cost
	upgrade_2.text = "Size +1 ($%d)" % size_upgrade_cost
	upgrade_3.text = "Income x2 ($%d)" % multiplier_upgrade_cost
	upgrade_1.disabled = money < damage_upgrade_cost
	upgrade_2.disabled = money < size_upgrade_cost
	upgrade_3.disabled = money < multiplier_upgrade_cost
