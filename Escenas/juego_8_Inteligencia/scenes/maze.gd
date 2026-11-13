extends Node2D

@export var cell_size: float = 48.0

const MAZE_LAYOUT: Array[String] = [
	"#############",
	"#S....#....E#",
	"###.#.......#",
	"#.....#.....#",
	"#############",
]

const FLOOR_COLOR := Color("#222b43")
const WALL_COLOR := Color("#8194bc")
const EXIT_COLOR := Color("#70d6a5")


func _ready() -> void:
	for row in range(MAZE_LAYOUT.size()):
		for column in range(MAZE_LAYOUT[row].length()):
			var cell := MAZE_LAYOUT[row].substr(column, 1)
			var cell_position := Vector2(column, row) * cell_size
			var cell_color := WALL_COLOR if cell == "#" else FLOOR_COLOR
			if cell == "E":
				cell_color = EXIT_COLOR

			_add_cell_visual(cell_position, cell_color)
			if cell == "#":
				_add_wall(cell_position + Vector2.ONE * cell_size / 2.0)


func _add_cell_visual(cell_position: Vector2, cell_color: Color) -> void:
	var visual := ColorRect.new()
	visual.position = cell_position
	visual.size = Vector2.ONE * cell_size
	visual.color = cell_color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)


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
	add_child(wall)
