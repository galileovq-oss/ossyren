class_name AttackResult
extends RefCounted
## Full result of a resolved attack. Used to apply damage, feedback and logs.

var attacker: Node3D = null
var defender: Node3D = null
var attacker_name: String = "?"
var defender_name: String = "?"
var ranged: bool = false
## false = ENERGY damage (ignores armour).
var physical: bool = true

var hit: bool = false
var hit_chance: float = 0.0
var hit_roll: float = 0.0

var raw_damage: float = 0.0
var armour_multiplier: float = 1.0
var dr_multiplier: float = 1.0
var final_damage: int = 0
## Part of final_damage soaked up by a barrier (does not reduce health).
var absorbed: int = 0
var killed: bool = false


func describe() -> String:
	if not hit:
		return "%s -> %s: MISS (chance %.0f%%, roll %.2f)" % [
			attacker_name, defender_name, hit_chance * 100.0, hit_roll]
	return "%s -> %s: HIT (chance %.0f%%, roll %.2f) %.1f x armour %.2f x DR %.2f = %d%s%s" % [
		attacker_name, defender_name, hit_chance * 100.0, hit_roll,
		raw_damage, armour_multiplier, dr_multiplier, final_damage,
		(" (%d absorbed)" % absorbed) if absorbed > 0 else "",
		" [KILLED]" if killed else ""]
