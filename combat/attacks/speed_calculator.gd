class_name SpeedCalculator
extends RefCounted
## PURE speed formulas (no nodes), easy to test. All numbers are provisional.
##
## Attack Speed (AS) and Cast Speed (CS) are percentage bonuses. The EFFECTIVE rate only changes when
## a bonus reaches the next breakpoint (Diablo II style): stacking modifiers between breakpoints does
## nothing. Each weapon defines its own thresholds/rates, and the last entry is its cap.
##
##   rate     = attacks (or casts) per base interval:  1.0 = "1/1",  1.5 = "3/2",  2.0 = "2/1"
##   interval = base_interval / rate


## Cast Speed breakpoints: more conservative than attack speed.
static func cast_thresholds() -> PackedFloat32Array:
	return PackedFloat32Array([0.0, 40.0, 100.0])


static func cast_rates() -> PackedFloat32Array:
	return PackedFloat32Array([1.0, 1.25, 1.5])


static func tier_index(bonus: float, thresholds: PackedFloat32Array) -> int:
	var tier: int = 0
	for i in thresholds.size():
		if bonus >= thresholds[i]:
			tier = i
	return tier


static func rate_for(bonus: float, thresholds: PackedFloat32Array, rates: PackedFloat32Array) -> float:
	if rates.is_empty():
		return 1.0
	return rates[mini(tier_index(bonus, thresholds), rates.size() - 1)]


static func interval(base_interval: float, rate: float) -> float:
	return base_interval / maxf(rate, 0.01)


## Bonus needed to reach the next breakpoint, or -1.0 if already at the cap.
static func next_threshold(bonus: float, thresholds: PackedFloat32Array, rates: PackedFloat32Array) -> float:
	var next: int = mini(tier_index(bonus, thresholds), rates.size() - 1) + 1
	if next >= mini(thresholds.size(), rates.size()):
		return -1.0
	return thresholds[next]


## 1.0 -> "1/1", 1.5 -> "3/2", 2.0 -> "2/1", 1.25 -> "5/4".
static func rate_label(rate: float) -> String:
	for denominator in range(1, 5):
		var numerator: int = roundi(rate * denominator)
		if absf(rate - float(numerator) / float(denominator)) < 0.001:
			return "%d/%d" % [numerator, denominator]
	return "%.2f" % rate
