extends DropSocket
# Socket especial con funcionalidades

func _ready() -> void:
	super() # ejecuta el _ready del DropSocket (color idle, etc.)
	special_socket = true
