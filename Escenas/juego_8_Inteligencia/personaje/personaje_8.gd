extends CharacterBody2D

@export var move_distance: float = 10.0

var _pending_moves: Array[Vector2] = []


func move_up() -> void:
	_pending_moves.append(Vector2.UP)


func move_down() -> void:
	_pending_moves.append(Vector2.DOWN)


func move_left() -> void:
	_pending_moves.append(Vector2.LEFT)


func move_right() -> void:
	_pending_moves.append(Vector2.RIGHT)


func _physics_process(_delta: float) -> void:
	if not _pending_moves.is_empty():
		var direction: Vector2 = _pending_moves.pop_front()
		move_and_collide(direction * move_distance)
