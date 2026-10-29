extends Node2D

const RETRO_UI_FONT: FontFile = preload("res://assets/fonts/VT323-Regular.ttf")
const MIN_MANUAL_MINING_INTERVAL: float = 0.05
const DINO_VICTORY_SCENE: String = "res://Escenas/juego_7_dinos/main/game_over_dino.tscn"

signal tile_damaged(cell: Vector2i, remaining_health: int)
signal tile_mined(cell: Vector2i)
signal score_changed(new_score: int)
signal fossil_excavated(fossil_texture: Texture2D, score_awarded: int, total_score: int)
@onready var score_label: Label = %score_label
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var pickaxe: TextureRect = $pickaxe
@onready var money_counter: Control = $money

@onready var fossils_area: Area2D = $Fossils_area
@onready var musica: AudioStreamPlayer2D = $musica
@onready var button_click: AudioStreamPlayer2D = $button_click

var picar_piedra: PackedScene = preload("res://particulas/picar_piedra.tscn")
var _pickaxe_swing_tween: Tween
var _money_pulse_tween: Tween
@onready var upgrade_menu_button: Button = $upgrade_menu_button
@onready var upgrade_menu: Control = $Upgrade_menu
@onready var upgrade_panel: PanelContainer = $Upgrade_menu/CenterContainer/PanelContainer
@onready var upgrade_close_button: Button = \
	$Upgrade_menu/CenterContainer/PanelContainer/MenuContent/Header/CloseButton
@onready var info_panel: PanelContainer = $info_text
@onready var upgrade_money_label: Label = %upgrade_money_label
@onready var upgrade_stats_label: Label = %upgrade_stats_label
var _upgrade_menu_tween: Tween
var _upgrade_wallet_tween: Tween

@onready var pickaxe_sound: AudioStreamPlayer2D = $pickaxe/pickaxe_sound
var _pickaxe_sound_volume_db: float

@onready var enemys: Node2D = $enemys
@onready var dinoenemigo_1: DinoEnemy = $enemys/Dinoenemigo1



@export_group("Mining")
@export_range(1, 100, 1) var mining_power: int = 1
@export_range(1, 100, 1) var tile_health: int = 1
@export_range(0.0, 1.0, 0.05) var damaged_tile_darkening: float = 0.4
@export_range(0.05, 1.0, 0.01) var manual_mining_interval: float = 0.15

@export_group("Progression")
@export_range(1, 10000, 1) var starting_level: int = 1
@export_range(0, 10000, 1) var tile_health_increase_per_level: int = 1
@export_range(0, 100000, 1) var dirt_money_reward: int = 1
@export_range(0, 100000, 1) var fossil_money_reward: int = 50
@export_range(0.0, 10.0, 0.05) var level_transition_delay: float = 0.4

@export_group("Economy")
@export_range(1.0, 3.0, 0.05) var upgrade_cost_growth_multiplier: float = 1.5

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
@onready var manual_mining_label: Label = %manual_mining
@onready var upgrade_1: Button = %upgrade_1
@onready var upgrade_2: Button = %upgrade_2
@onready var upgrade_3: Button = %upgrade_3
@onready var upgrade_4: Button = %upgrade_4
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
var _manual_mining: bool = false
var _manual_mining_cooldown: float = 0.0
var _game_finished: bool = false
var manual_speed_upgrade_cost: int = 10
var damage_upgrade_cost: int = 10
var size_upgrade_cost: int = 25
var multiplier_upgrade_cost: int = 50


func _ready() -> void:
	canvas_layer.show()
	#level_texture.hide()
	pickaxe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pickaxe.z_index = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_pickaxe_sound_volume_db = pickaxe_sound.volume_db
	_update_pickaxe_position()
	upgrade_menu.hide()
	_connect_button_click_sounds()
	upgrade_menu_button.focus_mode = Control.FOCUS_ALL
	upgrade_menu_button.offset_transform_enabled = true
	upgrade_panel.offset_transform_enabled = true
	upgrade_panel.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	dinoenemigo_1.died.connect(_on_dino_defeated)
	_style_upgrade_menu()
	level = starting_level
	_capture_initial_terrain()
	update_score()
	_update_upgrade_ui()
	_build_fossils_array()
	_spawn_fossils()
	_setup_fossils()
	upgrade_menu_button.call_deferred("grab_focus")


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


func _connect_button_click_sounds() -> void:
	var buttons: Array[Button] = [
		upgrade_menu_button,
		upgrade_close_button,
		upgrade_1,
		upgrade_2,
		upgrade_3,
		upgrade_4
	]
	for button in buttons:
		if not button.pressed.is_connected(_play_button_click):
			button.pressed.connect(_play_button_click)


func _play_button_click() -> void:
	button_click.pitch_scale = randf_range(0.96, 1.04)
	button_click.play()


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
	if _level_transition_pending or _game_finished:
		return

	_manual_mining_cooldown = maxf(_manual_mining_cooldown - _delta, 0.0)
	if _manual_mining and _manual_mining_cooldown == 0.0:
		_mine_from_pointer()
		_manual_mining_cooldown = manual_mining_interval

func _input(event: InputEvent) -> void:
	if upgrade_menu.visible and event.is_action_pressed("ui_cancel"):
		_close_upgrade_menu()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.pressed:
		_manual_mining = false


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
		if _level_transition_pending or _game_finished or upgrade_menu.visible:
			return
		_manual_mining = true
		_manual_mining_cooldown = manual_mining_interval
		_mine_from_pointer()


func _mine_from_pointer() -> void:
	var mining_position := get_global_mouse_position()
	_swing_pickaxe()
	_play_pickaxe_sound(_has_available_tile_at(mining_position))
	mine_at_global_position(mining_position)


func _play_pickaxe_sound(hit_available_tile: bool) -> void:
	pickaxe_sound.pitch_scale = randf_range(0.84, 1.2)
	pickaxe_sound.volume_db = _pickaxe_sound_volume_db if hit_available_tile else -80.0
	pickaxe_sound.play()


func _swing_pickaxe() -> void:
	if _pickaxe_swing_tween != null and _pickaxe_swing_tween.is_running():
		_pickaxe_swing_tween.kill()

	pickaxe.rotation = 0.0
	_pickaxe_swing_tween = create_tween()
	_pickaxe_swing_tween.tween_property(pickaxe, "rotation", deg_to_rad(-45.0), 0.04) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pickaxe_swing_tween.tween_property(pickaxe, "rotation", deg_to_rad(18.0), 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pickaxe_swing_tween.tween_property(pickaxe, "rotation", 0.0, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func mine_at_global_position(global_position_new: Vector2) -> bool:
	var start_cell := _get_mining_start_cell(global_position_new)
	var mined_any := false
	var total_damage_dealt := 0
	for y in range(start_cell.y, start_cell.y + mining_height):
		for x in range(start_cell.x, start_cell.x + mining_width):
			var target_cell := Vector2i(x, y)
			total_damage_dealt += _get_cell_damage(target_cell)
			if not mine_cell(target_cell, false):
				continue

			var cell_position := tile_map_layer.to_global(tile_map_layer.map_to_local(target_cell))
			_play_cell_destroy_particles(cell_position)
			mined_any = true

	if total_damage_dealt > 0:
		dinoenemigo_1.take_damage(total_damage_dealt)
		DamageNumbers.display_numbers(total_damage_dealt, global_position_new)

	return mined_any


func _on_dino_defeated() -> void:
	if _game_finished:
		return

	_game_finished = true
	_manual_mining = false
	upgrade_menu.hide()
	await get_tree().create_timer(0.65).timeout
	TransitionManager.change_scene(DINO_VICTORY_SCENE)


func _has_available_tile_at(world_position: Vector2) -> bool:
	var start_cell := _get_mining_start_cell(world_position)
	for y in range(start_cell.y, start_cell.y + mining_height):
		for x in range(start_cell.x, start_cell.x + mining_width):
			if tile_map_layer.get_cell_source_id(Vector2i(x, y)) >= 0:
				return true
	return false


func _get_mining_start_cell(world_position: Vector2) -> Vector2i:
	var local_position := tile_map_layer.to_local(world_position)
	var cell := tile_map_layer.local_to_map(local_position)
	@warning_ignore("integer_division")
	return cell - Vector2i(mining_width / 2, mining_height / 2)


func _get_cell_damage(cell: Vector2i) -> int:
	if tile_map_layer.get_cell_source_id(cell) < 0:
		return 0

	var level_tile_health := tile_health + (level - 1) * tile_health_increase_per_level
	var remaining_health: int = _tile_health_by_cell.get(cell, level_tile_health)
	return mini(mining_power, remaining_health)


func mine_cell(cell: Vector2i, show_damage_number: bool = true) -> bool:
	if tile_map_layer.get_cell_source_id(cell) < 0:
		_tile_health_by_cell.erase(cell)
		return false

	var level_tile_health := tile_health + (level - 1) * tile_health_increase_per_level
	var remaining_health: int = _tile_health_by_cell.get(cell, level_tile_health)
	var damage_dealt := _get_cell_damage(cell)
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
	money += dirt_money_reward * money_multiplier
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
	DamageNumbers.display_text(
		"Fossil! +%d points  +$%d" % [score_awarded, fossil_money_reward * money_multiplier],
		fossil_global_position,
		Color("#ffe45e"),
		24
	)
	_remaining_fossils -= 1
	if _remaining_fossils == 0 and not _level_transition_pending:
		_level_transition_pending = true
		call_deferred("_start_next_level")


func update_score():
	score_label.text = "Puntaje: " + str(score)
	score_changed.emit(score)

func _play_fossil_excavated_particles(_global_position: Vector2,_fossil_texture: Texture2D
) -> void:
	var particles := picar_piedra.instantiate() as CPUParticles2D
	particles.texture = _fossil_texture
	particles.amount = 16
	particles.lifetime = 0.75
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0.0, 300.0)
	add_child(particles)
	particles.global_position = _global_position
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


func apply_mining_upgrade(power_increase: int) -> void:
	if power_increase <= 0:
		push_error("Mining upgrade power must be greater than zero.")
		return
	mining_power += power_increase
	_update_upgrade_ui()


func _on_upgrade_1_pressed() -> void:
	if manual_mining_interval <= MIN_MANUAL_MINING_INTERVAL:
		return
	if not _try_purchase_upgrade(manual_speed_upgrade_cost):
		return

	manual_mining_interval = maxf(
		manual_mining_interval * 0.85,
		MIN_MANUAL_MINING_INTERVAL
	)
	manual_speed_upgrade_cost = _get_next_upgrade_cost(manual_speed_upgrade_cost)
	_update_upgrade_ui()
	_play_upgrade_purchase_feedback(upgrade_1)


func _on_upgrade_2_pressed() -> void:
	if not _try_purchase_upgrade(damage_upgrade_cost):
		return

	apply_mining_upgrade(1)
	damage_upgrade_cost = _get_next_upgrade_cost(damage_upgrade_cost)
	_update_upgrade_ui()
	_play_upgrade_purchase_feedback(upgrade_2)


func _on_upgrade_3_pressed() -> void:
	if not _try_purchase_upgrade(size_upgrade_cost):
		return

	if mining_width == mining_height:
		mining_height += 1
	else:
		mining_width += 1
	size_upgrade_cost = _get_next_upgrade_cost(size_upgrade_cost)
	_update_upgrade_ui()
	_play_upgrade_purchase_feedback(upgrade_3)


func _on_upgrade_4_pressed() -> void:
	if not _try_purchase_upgrade(multiplier_upgrade_cost):
		return

	money_multiplier *= 2
	multiplier_upgrade_cost = _get_next_upgrade_cost(multiplier_upgrade_cost)
	_update_upgrade_ui()
	_play_upgrade_purchase_feedback(upgrade_4)


func _try_purchase_upgrade(cost: int) -> bool:
	if money < cost:
		return false

	money -= cost
	_update_upgrade_ui()
	return true


func _get_next_upgrade_cost(current_cost: int) -> int:
	return ceili(current_cost * upgrade_cost_growth_multiplier)


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
	level_label.text = "DIG Site: %d" % level
	damage_label.text = "POWER: %d" % mining_power
	size_label.text = "AREA: %dx%d" % [mining_width, mining_height]
	multiplier_label.text = "INCOME: x%d" % money_multiplier
	manual_mining_label.text = "MANUAL DIG: %.1f/s" % (1.0 / manual_mining_interval)

	if manual_mining_interval <= MIN_MANUAL_MINING_INTERVAL:
		upgrade_1.text = "QUICKER PICKAXE   |   MAX SPEED REACHED"
	else:
		var next_interval := maxf(
			manual_mining_interval * 0.85,
			MIN_MANUAL_MINING_INTERVAL
		)
		upgrade_1.text = "QUICKER PICKAXE   |   %.1f > %.1f DIGS/SEC   |   $%d" % [
			1.0 / manual_mining_interval,
			1.0 / next_interval,
			manual_speed_upgrade_cost
		]
	upgrade_2.text = "PICKAXE POWER   |   +1 DAMAGE   |   $%d" % damage_upgrade_cost
	upgrade_3.text = "EXCAVATION AREA   |   +1 TILE   |   $%d" % size_upgrade_cost
	upgrade_4.text = "COIN VALUE   |   INCOME x2   |   $%d" % multiplier_upgrade_cost
	upgrade_1.disabled = money < manual_speed_upgrade_cost \
		or manual_mining_interval <= MIN_MANUAL_MINING_INTERVAL
	upgrade_2.disabled = money < damage_upgrade_cost
	upgrade_3.disabled = money < size_upgrade_cost
	upgrade_4.disabled = money < multiplier_upgrade_cost

	upgrade_stats_label.text = (
		"LEVEL  %d       POWER  %d       AREA  %d x %d\nINCOME  x%d       MANUAL DIG  %.1f / sec"
		% [
			level, mining_power, mining_width, mining_height,
			money_multiplier, 1.0 / manual_mining_interval
		]
	)
	var upgrade_money_text := str(money)
	if upgrade_money_label.text != upgrade_money_text:
		upgrade_money_label.text = upgrade_money_text
		_pulse_upgrade_wallet()
	upgrade_menu_button.text = "CLOSE UPGRADES" if upgrade_menu.visible else "UPGRADES"

	var money_text := str(money)
	if money_label.text != money_text:
		money_label.text = money_text
		_pulse_money_counter()


func _pulse_money_counter() -> void:
	if _money_pulse_tween != null and _money_pulse_tween.is_running():
		_money_pulse_tween.kill()

	money_counter.scale = Vector2.ONE
	_money_pulse_tween = create_tween()
	_money_pulse_tween.tween_property(money_counter, "scale", Vector2(1.15, 1.15), 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_money_pulse_tween.tween_property(money_counter, "scale", Vector2.ONE, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_upgrade_menu_button_pressed() -> void:
	if upgrade_menu.visible:
		_close_upgrade_menu()
		return

	_manual_mining = false
	upgrade_menu.show()
	upgrade_menu_button.text = "CLOSE UPGRADES"
	pickaxe.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	upgrade_menu.modulate.a = 0.0
	upgrade_panel.offset_transform_scale = Vector2(0.94, 0.94)
	if _upgrade_menu_tween != null and _upgrade_menu_tween.is_running():
		_upgrade_menu_tween.kill()
	_upgrade_menu_tween = create_tween()
	_upgrade_menu_tween.set_parallel(true)
	_upgrade_menu_tween.tween_property(upgrade_menu, "modulate:a", 1.0, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_upgrade_menu_tween.tween_property(upgrade_panel, "offset_transform_scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	upgrade_1.call_deferred("grab_focus")


func _close_upgrade_menu() -> void:
	if not upgrade_menu.visible:
		return

	if _upgrade_menu_tween != null and _upgrade_menu_tween.is_running():
		_upgrade_menu_tween.kill()
	upgrade_menu.hide()
	upgrade_menu.modulate.a = 1.0
	upgrade_panel.offset_transform_scale = Vector2.ONE
	upgrade_menu_button.text = "UPGRADES"
	pickaxe.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	upgrade_menu_button.grab_focus()


func _on_upgrade_close_button_pressed() -> void:
	_close_upgrade_menu()


func _on_upgrade_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		get_viewport().set_input_as_handled()
		_close_upgrade_menu()


func _style_upgrade_menu() -> void:
	var menu_theme := Theme.new()
	menu_theme.set_font("font", "Button", RETRO_UI_FONT)
	menu_theme.set_font("font", "Label", RETRO_UI_FONT)
	menu_theme.set_font_size("font_size", "Button", 23)
	menu_theme.set_font_size("font_size", "Label", 21)
	menu_theme.set_color("font_color", "Button", Color("#f4dcc0"))
	menu_theme.set_color("font_hover_color", "Button", Color("#fff0cf"))
	menu_theme.set_color("font_pressed_color", "Button", Color("#fff8e4"))
	menu_theme.set_color("font_disabled_color", "Button", Color("#95736f"))
	menu_theme.set_color("font_focus_color", "Button", Color("#fff0cf"))
	menu_theme.set_color("font_outline_color", "Button", Color("#170e14"))
	menu_theme.set_color("font_outline_color", "Label", Color("#170e14"))
	menu_theme.set_constant("outline_size", "Button", 1)
	menu_theme.set_constant("outline_size", "Label", 1)
	menu_theme.set_stylebox("normal", "Button", _make_upgrade_button_style(
		Color("#4d2931"), Color("#9b5146")
	))
	menu_theme.set_stylebox("hover", "Button", _make_upgrade_button_style(
		Color("#783942"), Color("#f5b75b"), 3
	))
	menu_theme.set_stylebox("pressed", "Button", _make_upgrade_button_style(
		Color("#321d25"), Color("#e88b4c"), 3
	))
	menu_theme.set_stylebox("disabled", "Button", _make_upgrade_button_style(
		Color("#302329"), Color("#50333a")
	))
	menu_theme.set_stylebox("focus", "Button", _make_upgrade_button_style(
		Color("#783942"), Color("#ffe28a"), 3
	))
	upgrade_menu.theme = menu_theme
	info_panel.theme = menu_theme
	money_counter.theme = menu_theme
	upgrade_menu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	info_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	money_counter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#28171e")
	panel_style.border_color = Color("#c76048")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(0)
	panel_style.set_content_margin_all(22.0)
	panel_style.shadow_color = Color("#110b10")
	panel_style.shadow_size = 2
	panel_style.shadow_offset = Vector2(5.0, 5.0)
	upgrade_panel.add_theme_stylebox_override("panel", panel_style)

	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color("#28171e")
	info_style.border_color = Color("#c76048")
	info_style.set_border_width_all(3)
	info_style.set_corner_radius_all(0)
	info_style.set_content_margin_all(15.0)
	info_style.shadow_color = Color("#110b10")
	info_style.shadow_size = 2
	info_style.shadow_offset = Vector2(4.0, 4.0)
	info_panel.add_theme_stylebox_override("panel", info_style)

	$info_text/StatsContent/Heading \
		.add_theme_color_override("font_color", Color("#f5b75b"))
	level_label.add_theme_color_override("font_color", Color("#f5b75b"))
	damage_label.add_theme_color_override("font_color", Color("#f4dcc0"))
	size_label.add_theme_color_override("font_color", Color("#f4dcc0"))
	multiplier_label.add_theme_color_override("font_color", Color("#f4dcc0"))
	manual_mining_label.add_theme_color_override("font_color", Color("#f4dcc0"))
	var stat_labels: Array[Label] = [
		level_label, damage_label, size_label, multiplier_label, manual_mining_label
	]
	for stat_label in stat_labels:
		stat_label.add_theme_font_size_override("font_size", 22)

	var wallet_style := StyleBoxFlat.new()
	wallet_style.bg_color = Color("#442630")
	wallet_style.border_color = Color("#895044")
	wallet_style.set_border_width_all(2)
	wallet_style.set_corner_radius_all(0)
	wallet_style.set_content_margin_all(10.0)
	$Upgrade_menu/CenterContainer/PanelContainer/MenuContent/WalletStrip \
		.add_theme_stylebox_override("panel", wallet_style)

	$Upgrade_menu/CenterContainer/PanelContainer/MenuContent/Header/Heading \
		.add_theme_color_override("font_color", Color("#f5b75b"))
	$Upgrade_menu/CenterContainer/PanelContainer/MenuContent/Subtitle \
		.add_theme_color_override("font_color", Color("#c47d68"))
	$Upgrade_menu/CenterContainer/PanelContainer/MenuContent/upgrade_stats_label \
		.add_theme_color_override("font_color", Color("#f4dcc0"))
	$Upgrade_menu/CenterContainer/PanelContainer/MenuContent/WalletStrip/WalletRow/WalletTitle \
		.add_theme_color_override("font_color", Color("#c47d68"))
	upgrade_money_label.add_theme_color_override("font_color", Color("#f5b75b"))

	var launcher_style := _make_upgrade_button_style(Color("#c7603f"), Color("#f5b75b"), 3)
	launcher_style.set_content_margin_all(14.0)
	upgrade_menu_button.add_theme_stylebox_override("normal", launcher_style)
	upgrade_menu_button.add_theme_stylebox_override(
		"hover", _make_upgrade_button_style(Color("#df7950"), Color("#ffe28a"), 3)
	)
	upgrade_menu_button.add_theme_stylebox_override(
		"pressed", _make_upgrade_button_style(Color("#8e3f38"), Color("#f5b75b"), 3)
	)
	upgrade_menu_button.add_theme_color_override("font_color", Color("#211319"))
	upgrade_menu_button.add_theme_color_override("font_hover_color", Color("#211319"))
	upgrade_menu_button.add_theme_color_override("font_pressed_color", Color("#fff0cf"))
	upgrade_menu_button.add_theme_font_size_override("font_size", 25)
	upgrade_menu_button.add_theme_stylebox_override(
		"focus", _make_upgrade_button_style(Color("#df7950"), Color("#ffe28a"), 3)
	)


func _make_upgrade_button_style(
	background_color: Color,
	border_color: Color,
	border_width: int = 1
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(12.0)
	style.shadow_color = Color("#110b10")
	style.shadow_size = 2
	style.shadow_offset = Vector2(3.0, 3.0)
	return style


func _pulse_upgrade_wallet() -> void:
	if _upgrade_wallet_tween != null and _upgrade_wallet_tween.is_running():
		_upgrade_wallet_tween.kill()

	upgrade_money_label.offset_transform_enabled = true
	upgrade_money_label.offset_transform_scale = Vector2.ONE
	_upgrade_wallet_tween = create_tween()
	_upgrade_wallet_tween.tween_property(
		upgrade_money_label, "offset_transform_scale", Vector2(1.16, 1.16), 0.08
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_wallet_tween.tween_property(
		upgrade_money_label, "offset_transform_scale", Vector2.ONE, 0.14
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_upgrade_purchase_feedback(button: Button) -> void:
	button.offset_transform_enabled = true
	var purchase_tween := create_tween()
	purchase_tween.tween_property(
		button, "offset_transform_scale", Vector2(1.035, 1.035), 0.07
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	purchase_tween.tween_property(
		button, "offset_transform_scale", Vector2.ONE, 0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_musica_finished() -> void:
	musica.play()
