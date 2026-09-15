class_name ItemData extends Resource

enum ItemType {
	STR,
	AGI,
	INT,
	DEF,
	HP,
	SP
}

@export var sprite: Texture2D
@export var sfx: AudioStream
@export var vfx: PackedScene

@export var item_name: String
@export var item_description: String
@export var type: ItemType = ItemType.STR
