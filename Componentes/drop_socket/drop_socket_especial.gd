extends StaticBody2D
#especial con funcionalidades

@onready var highlight: CPUParticles2D = $DropHighlight

# Referencia al item que ocupa este socket (null si está libre)
var occupied_item: Item = null


func _process(_delta: float) -> void:
	highlight.emitting = true if Global.is_dragging else false


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
	
func _on_something(mutante) -> void:
	#var item_name: String
	#var item_description: String
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
