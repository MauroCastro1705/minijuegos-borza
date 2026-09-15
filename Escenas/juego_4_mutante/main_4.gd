extends Node2D
@onready var reference_rect: ReferenceRect = $ReferenceRect

@onready var mutante: CharacterBody2D = $Mutante
@onready var countdown_timer: CustomTimer = $CountdownTimer
@onready var item_tooltip: Panel = $CanvasLayer/ItemTooltip
@onready var item: Item = $Item

func _ready() -> void:
	Global.drag_limits = reference_rect.get_global_rect()
	item.tooltip_requested.connect(item_tooltip._on_item_tooltip_requested)
	item.tooltip_hidden.connect(item_tooltip._on_item_tooltip_hidden)
