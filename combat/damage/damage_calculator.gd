class_name DamageCalculator
extends RefCounted
## PURE combat formulas (no nodes), easy to test. All numbers are provisional.
##
## 1) Hit:       hit = clamp(Accuracy / (Accuracy + Evasion), MIN_HIT, MAX_HIT)   (never 0% or 100%)
## 2) Armour:    effective armour = max(0, Armour - ArmourPenetration)
##              fraction that gets through = 1 - ef / (ef + ARMOUR_CONSTANT)
## 3) DR:        fraction that gets through = 1 - clamp(DR, 0, MAX_DR)   (separate layer, after armour)
## 4) Final:     max(1, round(base_damage * armour * DR))  if it hits
##
## Abilities can be ENERGY (physical = false: ignores armour, DR still applies) and can be
## unavoidable (can_miss = false: no hit roll, e.g. area effects the player dodges by moving).

const ARMOUR_CONSTANT: float = 100.0
const MIN_HIT_CHANCE: float = 0.05
const MAX_HIT_CHANCE: float = 0.95
const MAX_DAMAGE_REDUCTION: float = 0.75


static func hit_chance(accuracy: float, evasion: float) -> float:
	var total: float = maxf(accuracy, 0.0) + maxf(evasion, 0.0)
	if total <= 0.0:
		return MIN_HIT_CHANCE
	return clampf(maxf(accuracy, 0.0) / total, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


## Fraction of physical damage that gets through armour (1.0 = no reduction).
static func armour_multiplier(armour: float, armour_penetration: float) -> float:
	var effective: float = maxf(armour - armour_penetration, 0.0)
	return 1.0 - effective / (effective + ARMOUR_CONSTANT)


## Fraction of damage that gets through Damage Reduction (1.0 = no reduction).
static func dr_multiplier(damage_reduction: float) -> float:
	return 1.0 - clampf(damage_reduction, 0.0, MAX_DAMAGE_REDUCTION)


static func resolve_attack(
		accuracy: float, damage_min: float, damage_max: float, armour_penetration: float,
		evasion: float, armour: float, damage_reduction: float,
		rng: RandomNumberGenerator, physical: bool = true, can_miss: bool = true) -> AttackResult:
	var result: AttackResult = AttackResult.new()
	if can_miss:
		result.hit_chance = hit_chance(accuracy, evasion)
		result.hit_roll = rng.randf()
		result.hit = result.hit_roll < result.hit_chance
	else:
		result.hit_chance = 1.0
		result.hit = true
	if not result.hit:
		return result
	result.raw_damage = rng.randf_range(minf(damage_min, damage_max), maxf(damage_min, damage_max))
	result.armour_multiplier = armour_multiplier(armour, armour_penetration) if physical else 1.0
	result.dr_multiplier = dr_multiplier(damage_reduction)
	result.final_damage = maxi(1, roundi(result.raw_damage * result.armour_multiplier * result.dr_multiplier))
	return result
