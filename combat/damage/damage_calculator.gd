class_name DamageCalculator
extends RefCounted
## Formulas de combate PURAS (sin nodos), faciles de probar. Todos los numeros son provisionales.
##
## 1) Impacto:  hit = clamp(Accuracy / (Accuracy + Evasion), MIN_HIT, MAX_HIT)   (nunca 0% ni 100%)
## 2) Armadura: armadura efectiva = max(0, Armor - ArmorPenetration)
##              fraccion que pasa = 1 - ef / (ef + ARMOR_CONSTANT)
## 3) DR:       fraccion que pasa = 1 - clamp(DR, 0, MAX_DR)   (capa separada, tras la armadura)
## 4) Final:    max(1, round(dano_base * armadura * DR))  si conecta

const ARMOR_CONSTANT: float = 100.0
const MIN_HIT_CHANCE: float = 0.05
const MAX_HIT_CHANCE: float = 0.95
const MAX_DAMAGE_REDUCTION: float = 0.75


static func hit_chance(accuracy: float, evasion: float) -> float:
	var total: float = maxf(accuracy, 0.0) + maxf(evasion, 0.0)
	if total <= 0.0:
		return MIN_HIT_CHANCE
	return clampf(maxf(accuracy, 0.0) / total, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


## Fraccion del daño fisico que atraviesa la armadura (1.0 = sin reduccion).
static func armor_multiplier(armor: float, armor_penetration: float) -> float:
	var effective: float = maxf(armor - armor_penetration, 0.0)
	return 1.0 - effective / (effective + ARMOR_CONSTANT)


## Fraccion del daño que pasa tras la Damage Reduction (1.0 = sin reduccion).
static func dr_multiplier(damage_reduction: float) -> float:
	return 1.0 - clampf(damage_reduction, 0.0, MAX_DAMAGE_REDUCTION)


static func resolve_attack(
		accuracy: float, damage_min: float, damage_max: float, armor_penetration: float,
		evasion: float, armor: float, damage_reduction: float,
		rng: RandomNumberGenerator) -> AttackResult:
	var result: AttackResult = AttackResult.new()
	result.hit_chance = hit_chance(accuracy, evasion)
	result.hit_roll = rng.randf()
	result.hit = result.hit_roll < result.hit_chance
	if not result.hit:
		return result
	result.raw_damage = rng.randf_range(minf(damage_min, damage_max), maxf(damage_min, damage_max))
	result.armor_multiplier = armor_multiplier(armor, armor_penetration)
	result.dr_multiplier = dr_multiplier(damage_reduction)
	result.final_damage = maxi(1, roundi(result.raw_damage * result.armor_multiplier * result.dr_multiplier))
	return result
