extends StaticBody2D
# Socket especial con funcionalidades

@onready var special_socket: bool = false
@onready var highlight: CPUParticles2D = $DropHighlight

# Referencia al item que ocupa este socket (null si está libre)
var occupied_item: Item = null

# --- Colores de estado ---
const COLOR_IDLE     := Color(0.68, 0.85, 0.9, 0.5)   # verde-amarillo bajito
const COLOR_HOVER    := Color(1, 1, 1, 1)             # blanco brillante
const COLOR_OCCUPIED := Color(0.4, 1.0, 0.4, 0.7)     # verde cuando tiene item


func _ready() -> void:
	# Estado inicial correcto desde el primer frame
	_apply_color(COLOR_IDLE)


func _process(_delta: float) -> void:
	highlight.emitting = true if Global.is_dragging else false


# --- API de estado visual (llamadas desde el Item) ---

func set_hover(hovering: bool) -> void:
	# Si ya tiene un item puesto, no cambia con hover
	if occupied_item != null:
		return
	_apply_color(COLOR_HOVER if hovering else COLOR_IDLE)


func set_occupied(occupied: bool) -> void:
	if occupied:
		_apply_color(COLOR_OCCUPIED)
	else:
		_apply_color(COLOR_IDLE)


func _apply_color(c: Color) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", c, 0.1)


# --- API útil para consultar el contenido ---

func has_item() -> bool:
	return occupied_item != null


func get_item_data() -> ItemData:
	if occupied_item:
		return occupied_item.data
	return null


func get_item():
	if occupied_item:
		return occupied_item
	return null


func clear_item() -> void:
	occupied_item = null
	_apply_color(COLOR_IDLE)


func _on_something(mutante) -> void:
	if has_item():
		var item_data := get_item_data()
		var item = get_item()

		# Si este item ya fue aplicado, no hacemos nada
		if item.already_applied:
			print("mutageno ya usado")
			return

		mutante.aplicar_item(item_data)
		item.already_applied = true
		print("Mutágeno aplicado: ", item_data.item_name)
