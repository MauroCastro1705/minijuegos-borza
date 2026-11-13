extends Node2D

signal level_exit_reached

@export var cell_size: float = 48.0

const MAZE_LEVELS = [
	[
		"#############",
		"#S....#....E#",
		"#.....#.....#",
		"#...........#",
		"#############",
	],
	[
		"#############",
		"#S..#.......#",
		"#.#.#.#####.#",
		"#.#.........#",
		"#..........E#",
		"#############",
	],
	[
		"#############",
		"#S..........#",
		"#####.#####.#",
		"#...........#",
		"#..........E#",
		"#############",
	],
]

const FLOOR_COLOR := Color("#222b43")
const WALL_COLOR := Color("#8194bc")
const EXIT_COLOR := Color("#70d6a5")

@onready var player_start: Marker2D = $PlayerStart

var _level_nodes: Node2D


func _ready() -> void:
	load_level(0)


func get_level_count() -> int:
	return MAZE_LEVELS.size()


func load_level(level_index: int) -> void:
	if level_index < 0 or level_index >= MAZE_LEVELS.size():
		push_error("Maze level index is out of range: %d" % level_index)
		return

	if is_instance_valid(_level_nodes):
		_level_nodes.queue_free()

	_level_nodes = Node2D.new()
	_level_nodes.name = "LevelGeometry"
	add_child(_level_nodes)

	var layout: Array = MAZE_LEVELS[level_index]
	for row in range(layout.size()):
		for column in range(layout[row].length()):
			var cell = layout[row].substr(column, 1)
			var cell_position := Vector2(column, row) * cell_size
			var cell_color := WALL_COLOR if cell == "#" else FLOOR_COLOR
			if cell == "E":
				cell_color = EXIT_COLOR

			_add_cell_visual(cell_position, cell_color)
			match cell:
				"#":
					_add_wall(cell_position + Vector2.ONE * cell_size / 2.0)
				"S":
					player_start.position = cell_position + Vector2.ONE * cell_size / 2.0
				"E":
					_add_exit(cell_position + Vector2.ONE * cell_size / 2.0)


func _add_cell_visual(cell_position: Vector2, cell_color: Color) -> void:
	var visual := ColorRect.new()
	visual.position = cell_position
	visual.size = Vector2.ONE * cell_size
	visual.color = cell_color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_nodes.add_child(visual)


func _add_wall(wall_position: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = wall_position
	wall.collision_layer = 2
	wall.collision_mask = 0

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2.ONE * cell_size
	collision.shape = shape
	wall.add_child(collision)
	_level_nodes.add_child(wall)


func _add_exit(exit_position: Vector2) -> void:
	var exit_area := Area2D.new()
	exit_area.name = "Exit"
	exit_area.position = exit_position
	exit_area.collision_layer = 0
	exit_area.collision_mask = 1
	exit_area.body_entered.connect(_on_exit_body_entered)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = cell_size * 0.3
	collision.shape = shape
	exit_area.add_child(collision)
	_level_nodes.add_child(exit_area)


func _on_exit_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		level_exit_reached.emit()
