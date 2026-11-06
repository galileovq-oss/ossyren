class_name ClassData
extends Resource
## A playable class: base stats, starting weapon sets, ability slots and passives.
## Classes have AFFINITIES, not restrictions: any class can use any weapon later (GDD).
## Minimum kit per class: passive(s) + an active defence (slot 1) + a representative offensive (slot 2).

@export var id: StringName = &"class"
@export var display_name: String = "Class"
@export_multiline var description: String = ""
@export_multiline var kit_summary: String = ""
@export var stats: StatBlock
@export var weapon_set_1: WeaponData
@export var weapon_set_2: WeaponData
## Active abilities by slot (max 4).
@export var abilities: Array[AbilityData] = []
@export var passives: Array[AbilityData] = []


func get_weapon_sets() -> Array[WeaponData]:
	var sets: Array[WeaponData] = []
	sets.append(weapon_set_1)
	sets.append(weapon_set_2)
	return sets
