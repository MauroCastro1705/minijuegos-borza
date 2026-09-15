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


func clear_item() -> void:
	occupied_item = null
	
func _on_something() -> void:
	#var item_name: String
	#var item_description: String
	if has_item():
		var item_data := get_item_data()
		print("El socket contiene: ", item_data.item_name)
