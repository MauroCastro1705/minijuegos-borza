extends Node
var damage_label  = preload("res://themas/texto_pixelart.tres")
var mucho_borde = preload("res://themas/texto_pixelart_muchoborde.tres")
##como usar = DamageNumbers.display_numbers(value:float, position:Vector2)

func display_numbers(value:float, position:Vector2):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 15
	# Duplicamos el estilo y lo modificamos
	var label_settings = damage_label.duplicate()
	
	# Ajuste del color según el daño
	if value == 0:
		label_settings.font_color = Color("#FFFFFF88")  # Blanco translúcido
	elif value < 5:
		label_settings.font_color = Color("white")
	elif value < 25:
		label_settings.font_color = Color("yellow")
	else:
		label_settings.font_color = Color("red")

	# Ajuste del tamaño de fuente según el daño
	var base_size = 18
	var size_multiplier = clamp(value / 50.0, 0.8, 2.0)
	label_settings.font_size = base_size * size_multiplier
	number.label_settings = label_settings
	
	call_deferred("add_child", number)
	await number.resized
	
	number.pivot_offset = Vector2(number.size / 2)
	var tween  = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.25
		).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		number, "position:y", number.position.y, 0.5 
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(
		number, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number.queue_free()

func display_numbers_random(value: float, position: Vector2):
	var number = Label.new()
	
	var random_offset = Vector2(
		randf_range(-30, 30),
		randf_range(-20, 10)
	)
	number.global_position = position + random_offset
	
	number.text = str(value)
	number.z_index = 15
	var label_settings = damage_label.duplicate()
	
	if value == 0:
		label_settings.font_color = Color("#FFFFFF88")
	elif value < 10:
		label_settings.font_color = Color("lightgreen")
	elif value < 30:
		label_settings.font_color = Color("yellow")
	else:
		label_settings.font_color = Color("red")

	var base_size = 25
	var size_multiplier = clamp(value / 50.0, 0.8, 2.0)
	label_settings.font_size = base_size * size_multiplier
	number.label_settings = label_settings
	
	call_deferred("add_child", number)
	await number.resized
	
	number.pivot_offset = Vector2(number.size / 2)
	
	# Ángulo aleatorio apuntando hacia arriba (entre 210° y 330° en radianes)
	var angle = randf_range(deg_to_rad(210), deg_to_rad(330))
	var distance = randf_range(40, 70)
	var direction = Vector2(cos(angle), sin(angle)) * distance
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(
		number, "position", number.position + direction, 0.25
	).set_ease(Tween.EASE_OUT)
	
		# Sube en dirección aleatoria
	tween.tween_property(
		number, "position", number.position + direction, 0.25
	).set_ease(Tween.EASE_OUT)
	
	# Cae hacia abajo desde donde llegó
	var peak_position = number.position + direction
	tween.tween_property(
		number, "position:y", peak_position.y + randf_range(30, 60), 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	
	tween.tween_property(
		number, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number.queue_free()
	
	
func display_text(text: String, position: Vector2, color: Color = Color.WHITE, font_size: int = 18):
	var label = Label.new()
	label.global_position = position
	label.text = text
	label.z_index = 15
	
	# Crear configuraciones de fuente
	var label_settings = mucho_borde.duplicate()
	label_settings.font_color = color
	label_settings.font_size = font_size
	label.label_settings = label_settings
	
	call_deferred("add_child", label)
	await label.resized
	
	label.pivot_offset = Vector2(label.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	# Movimiento hacia arriba
	tween.tween_property(
		label, "position:y", label.position.y - 24, 0.25
	).set_ease(Tween.EASE_OUT)
	
	# Pausa en el punto más alto
	tween.tween_property(
		label, "position:y", label.position.y, 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	
	# Desvanecimiento y escalado
	tween.tween_property(
		label, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	label.queue_free()



func flash_sprite(sprite: CanvasItem) -> void:
	if not sprite: return
	
	var tween = sprite.get_tree().create_tween()
	tween.set_loops(2)  # Titila dos veces (apagado y encendido)
	tween.set_parallel(false)  # Que sea secuencial
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	
func display_numbers_heal(value:float, position:Vector2):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 15
	# Duplicamos el estilo y lo modificamos
	var label_settings = damage_label.duplicate()
	label_settings.font_color = Color("green")
	var base_size = 25
	var size_multiplier = clamp(value / 50.0, 0.8, 2.0)
	label_settings.font_size = base_size * size_multiplier
	number.label_settings = label_settings
	
	call_deferred("add_child", number)
	await number.resized
	
	number.pivot_offset = Vector2(number.size / 2)
	var tween  = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.25
		).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		number, "position:y", number.position.y, 0.5 
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(
		number, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number.queue_free()
