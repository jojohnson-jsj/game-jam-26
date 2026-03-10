class_name Cat
extends Resource

enum CatType { TABLE, NON_TABLE }
enum AbilityType { NONE, HERMES, MONEY, QR, QUEUE }

@export var cat_name: String = ""
@export var cat_type: CatType = CatType.NON_TABLE
@export var ability_type: AbilityType = AbilityType.NONE
@export var buff_value: float = 0.0
@export var sprite: Texture2D
