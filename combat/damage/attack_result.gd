class_name AttackResult
extends RefCounted
## Resultado completo de un ataque resuelto. Se usa para aplicar daño, feedback y logs.

var attacker: Node3D = null
var defender: Node3D = null
var attacker_name: String = "?"
var defender_name: String = "?"
var ranged: bool = false

var hit: bool = false
var hit_chance: float = 0.0
var hit_roll: float = 0.0

var raw_damage: float = 0.0
var armor_multiplier: float = 1.0
var dr_multiplier: float = 1.0
var final_damage: int = 0
var killed: bool = false


func describe() -> String:
	if not hit:
		return "%s -> %s: FALLO (prob %.0f%%, tirada %.2f)" % [
			attacker_name, defender_name, hit_chance * 100.0, hit_roll]
	return "%s -> %s: GOLPE (prob %.0f%%, tirada %.2f) %.1f x armadura %.2f x DR %.2f = %d%s" % [
		attacker_name, defender_name, hit_chance * 100.0, hit_roll,
		raw_damage, armor_multiplier, dr_multiplier, final_damage,
		" [MUERTE]" if killed else ""]
