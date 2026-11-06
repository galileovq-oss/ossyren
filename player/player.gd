class_name Player
extends CharacterBody3D
## Root of the player. The class is chosen BEFORE the player enters the tree: assign `class_data`
## and the data components read ('stats', 'abilities', 'passives', 'weapon_sets') is ready when
## their _ready() runs (components read these properties from their parent).

@export var class_data: ClassData:
	set(value):
		class_data = value
		_apply_class()

var stats: StatBlock
var abilities: Array[AbilityData] = []
var passives: Array[AbilityData] = []
var weapon_sets: Array[WeaponData] = []


func _apply_class() -> void:
	if class_data == null:
		return
	stats = class_data.stats
	abilities = class_data.abilities.duplicate()
	passives = class_data.passives.duplicate()
	weapon_sets = class_data.get_weapon_sets()
