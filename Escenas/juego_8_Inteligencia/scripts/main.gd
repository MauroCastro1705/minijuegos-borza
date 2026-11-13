extends Node2D

@export_subgroup("Properties")
@export var width: int = 8
@export var height: int = 8
@export var offset: int = 68

@export_subgroup("Scenes")
@export var tile_scene: PackedScene 
@export var sparkles_scene: PackedScene

@export_group("Tile sprites")
@export var left_tile_sprite: Texture2D
@export var right_tile_sprite: Texture2D
@export var up_tile_sprite: Texture2D
@export var down_tile_sprite: Texture2D
@export var special_tile_sprite: Texture2D

@export_subgroup("Hints")
@export_range(1.0, 60.0, 0.5) var hint_delay_seconds: float = 6.0

@export_subgroup("Scoring")
@export var special_tile_score: int = 5

@export_subgroup("Cursors")
@export var open_hand_cursor: Texture2D
@export var closed_hand_cursor: Texture2D

@onready var board_panel: PanelContainer = %board_container
@onready var container: Node2D = $board_container/MarginContainer/BoardArea/BoardTiles
@onready var player: CharacterBody2D = $Personaje8
@onready var maze = $Maze
@onready var player_start: Marker2D = $Maze/PlayerStart

const TILE_TYPES := ["LEFT", "RIGHT", "UP", "DOWN", "SPECIAL"]
const MOVEMENT_TILE_TYPES := ["LEFT", "RIGHT", "UP", "DOWN"]
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var vhs_efecto: ColorRect = $CanvasLayer/vhs_efecto

@onready var level_label: Label = %nivel_label
@onready var score_label: Label = %score_label

# State

var score: int = 0
var grid = []
var first_touch = Vector2i(-1, -1)
var is_swapping = false
var combo_count: int = 0
var _idle_time: float = 0.0
var _active_hint_tiles: Array = []
var _hint_visible: bool = false
var _current_level: int = 1
var _level_transitioning: bool = false

# Functions

func _process(delta: float) -> void:
	if grid.size() != width or is_swapping or _level_transitioning or first_touch != Vector2i(-1, -1) or _hint_visible:
		return

	_idle_time += delta
	if _idle_time >= hint_delay_seconds:
		_show_match_hint()


func _ready():
	canvas_layer.show()
	if left_tile_sprite == null or right_tile_sprite == null or up_tile_sprite == null or down_tile_sprite == null or special_tile_sprite == null:
		push_error("Assign a sprite for each tile type in the Main inspector.")
		return

	maze.level_exit_reached.connect(_on_maze_level_exit_reached)
	player.global_position = player_start.global_position
	_update_level_label()
	_update_score_label()
	board_panel.size = Vector2(width * offset + 32, height * offset + 32)
	set_cursor(open_hand_cursor)
	
	randomize()
	
	setup_grid_array() 
	process_board_state(false)

# Initialize grid

func setup_grid_array():
	
	grid = []
	for x in width:
		grid.append([])
		grid[x].resize(height)
		grid[x].fill(null)
		
	# Spawn initial pieces
	
	for x in width:
		for y in height:
			spawn_at(x, y)

# Spawn a new tile at a certain grid position

func spawn_at(x, y):
	
	var created_piece = tile_scene.instantiate() 
	var random_index = randi_range(0, TILE_TYPES.size() - 1)
	var tile_type = TILE_TYPES[random_index]
	
	container.add_child(created_piece) 
	
	created_piece.set_tile_type(tile_type, _get_tile_sprite(tile_type))
	created_piece.tile_pressed.connect(_on_tile_pressed) 
	created_piece.grid_position = Vector2i(x, y) 
	created_piece.position = grid_to_pixel(x, y) 
	
	grid[x][y] = created_piece

# Interaction

func _on_tile_pressed(grid_position: Vector2i):
	
	if not is_swapping:
		_reset_hint_timer()
		first_touch = grid_position
		set_cursor(closed_hand_cursor)

func _input(event):
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if first_touch != Vector2i(-1, -1):
				var local_mouse_pos = container.get_local_mouse_position()
				calculate_swipe(local_mouse_pos)

func calculate_swipe(final_pos: Vector2):
	
	var difference = final_pos - grid_to_pixel(first_touch.x, first_touch.y)
	
	if difference.length() > 32:
		var other_touch = first_touch
		if abs(difference.x) > abs(difference.y): # Horizontal dragging
			other_touch.x += 1 if difference.x > 0 else -1
		else: # Vertical dragging
			other_touch.y += 1 if difference.y > 0 else -1
		
		if is_within_grid(other_touch):
			handle_swap_logic(first_touch, other_touch)

	
	set_cursor(open_hand_cursor)
	first_touch = Vector2i(-1, -1)

# Game loop

func handle_swap_logic(pos_a: Vector2i, pos_b: Vector2i):
	
	_reset_hint_timer()
	is_swapping = true
	swap_pieces(pos_a, pos_b)
	
	await get_tree().create_timer(0.3).timeout
	
	if find_matches().size() > 0:
		process_board_state()
	else:
		swap_pieces(pos_a, pos_b)
		await get_tree().create_timer(0.3).timeout
		is_swapping = false

func swap_pieces(a: Vector2i, b: Vector2i):
	
	var piece_a = grid[a.x][a.y]
	var piece_b = grid[b.x][b.y]
	
	if piece_a and piece_b:
		grid[a.x][a.y] = piece_b
		grid[b.x][b.y] = piece_a
		
		piece_a.grid_position = b
		piece_b.grid_position = a
		
		piece_a.move_to(grid_to_pixel(b.x, b.y), false)
		piece_b.move_to(grid_to_pixel(a.x, a.y), false)

func find_matches() -> Array:
	
	var matched_dict = {}

	for y in height:
		for x in range(width - 2):
			var p1 = grid[x][y]; var p2 = grid[x+1][y]; var p3 = grid[x+2][y]
			if p1 and p2 and p3 and p1.type == p2.type and p1.type == p3.type:
				for p in [p1, p2, p3]: matched_dict[p] = true

	for x in width:
		for y in range(height - 2):
			var p1 = grid[x][y]; var p2 = grid[x][y+1]; var p3 = grid[x][y+2]
			if p1 and p2 and p3 and p1.type == p2.type and p1.type == p3.type:
				for p in [p1, p2, p3]: matched_dict[p] = true

	return matched_dict.keys()

func process_board_state(move_player: bool = true):
	
	is_swapping = true
	_clear_match_hint()
	_idle_time = 0.0
	combo_count = 0 
	var matches = find_matches()
	
	while matches.size() > 0:
		combo_count += 1
		if move_player:
			_add_match_score(matches)
		if move_player:
			_move_player_for_matches(matches)
		
		for piece in matches:
			var effect = sparkles_scene.instantiate()
			effect.position = piece.position
			container.add_child(effect)
			
			grid[piece.grid_position.x][piece.grid_position.y] = null
			
			var tween = piece.create_tween()
			tween.tween_property(piece, "scale", Vector2.ZERO, 0.2)
			tween.finished.connect(piece.queue_free)
		
		await get_tree().create_timer(0.3).timeout
		await collapse_columns()
		await refill_board()
		
		matches = find_matches()
	
	is_swapping = false

func _on_maze_level_exit_reached() -> void:
	if _level_transitioning:
		return

	player.clear_pending_moves()
	if _current_level >= maze.get_level_count():
		_level_transitioning = true
		return

	_level_transitioning = true
	while is_swapping:
		await get_tree().process_frame
	await get_tree().process_frame

	_current_level += 1
	maze.load_level(_current_level - 1)
	player.global_position = player_start.global_position
	player.clear_pending_moves()
	_update_level_label()
	await _rebuild_board()
	_level_transitioning = false

func _rebuild_board() -> void:
	_reset_hint_timer()
	first_touch = Vector2i(-1, -1)
	set_cursor(open_hand_cursor)
	for piece in container.get_children():
		piece.queue_free()

	setup_grid_array()
	await process_board_state(false)

func _update_level_label() -> void:
	level_label.text = "Nivel %d" % _current_level

func _add_match_score(matches: Array) -> void:
	for piece in matches:
		score += special_tile_score if piece.type == "SPECIAL" else 1
	_update_score_label()

func _update_score_label() -> void:
	score_label.text = "Score: %d" % score

func collapse_columns():
	
	for x in width:
		for y in range(height - 1, -1, -1):
			if grid[x][y] == null:
				for k in range(y - 1, -1, -1):
					if grid[x][k] != null:
						grid[x][y] = grid[x][k]
						grid[x][k] = null
						grid[x][y].grid_position = Vector2i(x, y)
						grid[x][y].move_to(grid_to_pixel(x, y))
						break
	await get_tree().create_timer(0.3).timeout

func refill_board():
	
	for x in width:
		for y in height:
			if grid[x][y] == null:
				spawn_at(x, y)
				grid[x][y].position.y -= offset * 2 
				grid[x][y].move_to(grid_to_pixel(x, y))
	await get_tree().create_timer(0.3).timeout

# Utilities for coordinates

func grid_to_pixel(column: int, row: int) -> Vector2:
	return Vector2(offset * column, offset * row) + Vector2.ONE * offset / 2.0

func is_within_grid(pos: Vector2i) -> bool:
	
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

# Utilities

func set_cursor(cursor_texture: Texture2D):
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, Vector2(16, 16))

func _get_tile_sprite(tile_type: String) -> Texture2D:
	match tile_type:
		"LEFT":
			return left_tile_sprite
		"RIGHT":
			return right_tile_sprite
		"UP":
			return up_tile_sprite
		"DOWN":
			return down_tile_sprite
		"SPECIAL":
			return special_tile_sprite
	return null

func _move_player_for_matches(matches: Array) -> void:
	if _level_transitioning:
		return

	var matched_types := {}
	for piece in matches:
		matched_types[piece.type] = true

	for tile_type in MOVEMENT_TILE_TYPES:
		if not matched_types.has(tile_type):
			continue
		match tile_type:
			"LEFT":
				player.move_left()
			"RIGHT":
				player.move_right()
			"UP":
				player.move_up()
			"DOWN":
				player.move_down()

func _show_match_hint() -> void:
	var possible_matches := _find_possible_matches()
	if possible_matches.is_empty():
		_idle_time = 0.0
		return

	_active_hint_tiles = possible_matches[randi_range(0, possible_matches.size() - 1)]
	for piece in _active_hint_tiles:
		piece.play_match_hint()
	_hint_visible = true

func _find_possible_matches() -> Array:
	var possible_matches: Array = []
	for y in range(height):
		for x in range(width):
			for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + Vector2i(direction)
				if not is_within_grid(neighbor):
					continue

				var first_piece = grid[x][y]
				var second_piece = grid[neighbor.x][neighbor.y]
				if first_piece == null or second_piece == null:
					continue

				grid[x][y] = second_piece
				grid[neighbor.x][neighbor.y] = first_piece
				var matches := find_matches()
				grid[x][y] = first_piece
				grid[neighbor.x][neighbor.y] = second_piece

				if not matches.is_empty():
					possible_matches.append(matches)

	return possible_matches

func _reset_hint_timer() -> void:
	_clear_match_hint()
	_idle_time = 0.0

func _clear_match_hint() -> void:
	for piece in _active_hint_tiles:
		if is_instance_valid(piece):
			piece.stop_match_hint()
	_active_hint_tiles.clear()
	_hint_visible = false
