extends SceneTree
## Combat formula tests. Run from the project folder:
##   godot --headless -s res://tests/test_damage_calculator.gd
## (use the Godot 4.7.2 executable). Exits with code 1 if anything fails.

var _failures: int = 0


func _initialize() -> void:
	_near("hit_chance capped at 95% (evasion 0)", DamageCalculator.hit_chance(100.0, 0.0), 0.95)
	_near("hit_chance 50% (100 vs 100)", DamageCalculator.hit_chance(100.0, 100.0), 0.5)
	_near("hit_chance 80% (100 vs 25)", DamageCalculator.hit_chance(100.0, 25.0), 0.8)
	_near("hit_chance minimum 5%", DamageCalculator.hit_chance(0.0, 100.0), 0.05)
	_near("armour 100 lets 50% through", DamageCalculator.armour_multiplier(100.0, 0.0), 0.5)
	_near("armour 100 with pen 50 lets 66.7% through", DamageCalculator.armour_multiplier(100.0, 50.0), 1.0 - 50.0 / 150.0)
	_near("pen > armour => no reduction", DamageCalculator.armour_multiplier(30.0, 100.0), 1.0)
	_near("DR 20% lets 80% through", DamageCalculator.dr_multiplier(0.2), 0.8)
	_near("DR capped at 75%", DamageCalculator.dr_multiplier(0.9), 0.25)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345

	# Deterministic damage: 10 * 0.5 (armour 100) * 0.8 (DR 20%) = 4
	var forced: AttackResult = _force_hit(rng, 10.0, 100.0, 0.0, 0.2)
	_check("combined damage = 4", forced.final_damage == 4)
	# Minimum 1 if it hits
	var tiny: AttackResult = _force_hit(rng, 1.0, 900.0, 0.0, 0.0)
	_check("minimum damage 1", tiny.final_damage == 1)

	# Statistics: 20000 attacks at 100 vs 25 evasion => ~80% hits
	var hits: int = 0
	for i in 20000:
		if DamageCalculator.resolve_attack(100.0, 5.0, 5.0, 0.0, 25.0, 0.0, 0.0, rng).hit:
			hits += 1
	_near("hit rate ~0.80", float(hits) / 20000.0, 0.8, 0.015)

	# A miss chance always exists (evasion 0)
	var misses: int = 0
	for i in 20000:
		if not DamageCalculator.resolve_attack(100.0, 5.0, 5.0, 0.0, 0.0, 0.0, 0.0, rng).hit:
			misses += 1
	_check("misses still happen with evasion 0 (~5%)", misses > 0 and absf(float(misses) / 20000.0 - 0.05) < 0.01)

	print("\n%s (%d failure(s))" % ["OK" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


func _force_hit(rng: RandomNumberGenerator, dmg: float, armour: float, pen: float, dr: float) -> AttackResult:
	# Huge accuracy + evasion 0 => 95% hit chance; retry until it hits.
	var result: AttackResult = AttackResult.new()
	for i in 200:
		result = DamageCalculator.resolve_attack(1000.0, dmg, dmg, pen, 0.0, armour, dr, rng)
		if result.hit:
			break
	return result


func _near(label: String, value: float, expected: float, tolerance: float = 0.0001) -> void:
	_check("%s (got %.4f, expected %.4f)" % [label, value, expected], absf(value - expected) <= tolerance)


func _check(label: String, ok: bool) -> void:
	if ok:
		print("  PASS  ", label)
	else:
		print("  FAIL  ", label)
		_failures += 1
