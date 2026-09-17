class_name DropSocket extends StaticBody2D

@onready var highlight: CPUParticles2D = $DropHighlight

var special_socket: bool = false
var occupied_item: Item = null
var stat_target: Node = null
var interaction_locked: bool = false

const COLOR_IDLE     := Color(0.68, 0.85, 0.9, 0.5)
const COLOR_HOVER    := Color(1, 1, 1, 1)
const COLOR_OCCUPIED := Color(0.4, 1.0, 0.4, 0.7)


func _ready() -> void:
	_apply_color(COLOR_IDLE)


func _process(_delta: float) -> void:
	highlight.emitting = Global.is_dragging


func set_hover(hovering: bool) -> void:
	if occupied_item != null:
		return
	_apply_color(COLOR_HOVER if hovering else COLOR_IDLE)


func set_occupied(occupied: bool) -> void:
	_apply_color(COLOR_OCCUPIED if occupied else COLOR_IDLE)


func set_stat_target(target: Node) -> void:
	stat_target = target


func set_interaction_locked(locked: bool) -> void:
	interaction_locked = locked
	if locked:
		_apply_color(COLOR_OCCUPIED if has_item() else COLOR_IDLE)


func can_interact() -> bool:
	return not interaction_locked


func equip_item(item: Item) -> void:
	if item == null or stat_target == null or item.already_applied:
		return

	stat_target.aplicar_item(item.data)
	item.already_applied = true


func remove_item() -> void:
	if not has_item():
		return

	var item := occupied_item
	if stat_target != null and item.already_applied:
		stat_target.remover_item(item.data)
	item.already_applied = false


func _apply_color(c: Color) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", c, 0.1)


func has_item() -> bool:
	return is_instance_valid(occupied_item)


func get_item_data() -> ItemData:
	if has_item():
		return occupied_item.data
	return null


func get_item() -> Item:
	if has_item():
		return occupied_item
	return null


func clear_item() -> void:
	remove_item()
	occupied_item = null
	get_node("CollisionShape2D").set_deferred("disabled", false)
	_apply_color(COLOR_IDLE)


func _on_something(mutante) -> void:
	if has_item():
		var item_data := get_item_data()
		var item := get_item()

		if item.already_applied:
			print("mutageno ya usado")
			return

		mutante.aplicar_item(item_data)
		item.already_applied = true
		print("Mutágeno aplicado: ", item_data.item_name)
