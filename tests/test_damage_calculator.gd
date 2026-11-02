extends SceneTree
## Pruebas de las formulas de combate. Ejecutar desde la carpeta del proyecto:
##   godot --headless -s res://tests/test_damage_calculator.gd
## (usa el ejecutable de Godot 4.7.2). Sale con codigo 1 si algo falla.

var _failures: int = 0


func _initialize() -> void:
	_near("hit_chance limitado a 95% (evasion 0)", DamageCalculator.hit_chance(100.0, 0.0), 0.95)
	_near("hit_chance 50% (100 vs 100)", DamageCalculator.hit_chance(100.0, 100.0), 0.5)
	_near("hit_chance 80% (100 vs 25)", DamageCalculator.hit_chance(100.0, 25.0), 0.8)
	_near("hit_chance minimo 5%", DamageCalculator.hit_chance(0.0, 100.0), 0.05)
	_near("armadura 100 pasa 50%", DamageCalculator.armor_multiplier(100.0, 0.0), 0.5)
	_near("armadura 100 con pen 50 pasa 66.7%", DamageCalculator.armor_multiplier(100.0, 50.0), 1.0 - 50.0 / 150.0)
	_near("pen > armadura => sin reduccion", DamageCalculator.armor_multiplier(30.0, 100.0), 1.0)
	_near("DR 20% pasa 80%", DamageCalculator.dr_multiplier(0.2), 0.8)
	_near("DR limitada a 75%", DamageCalculator.dr_multiplier(0.9), 0.25)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345

	# Daño determinista: 10 * 0.5 (armadura 100) * 0.8 (DR 20%) = 4
	var forced: AttackResult = _force_hit(rng, 10.0, 100.0, 0.0, 0.2)
	_check("daño combinado = 4", forced.final_damage == 4)
	# Minimo 1 si conecta
	var tiny: AttackResult = _force_hit(rng, 1.0, 900.0, 0.0, 0.0)
	_check("daño minimo 1", tiny.final_damage == 1)

	# Estadistica: 20000 ataques con 100 vs 25 de evasion => ~80% de aciertos
	var hits: int = 0
	for i in 20000:
		if DamageCalculator.resolve_attack(100.0, 5.0, 5.0, 0.0, 25.0, 0.0, 0.0, rng).hit:
			hits += 1
	_near("tasa de acierto ~0.80", float(hits) / 20000.0, 0.8, 0.015)

	# Siempre existe probabilidad de fallo (evasion 0)
	var misses: int = 0
	for i in 20000:
		if not DamageCalculator.resolve_attack(100.0, 5.0, 5.0, 0.0, 0.0, 0.0, 0.0, rng).hit:
			misses += 1
	_check("hay fallos aun con evasion 0 (~5%)", misses > 0 and absf(float(misses) / 20000.0 - 0.05) < 0.01)

	print("\n%s (%d fallo(s))" % ["OK" if _failures == 0 else "FALLO", _failures])
	quit(1 if _failures > 0 else 0)


func _force_hit(rng: RandomNumberGenerator, dmg: float, armor: float, pen: float, dr: float) -> AttackResult:
	# Accuracy enorme + evasion 0 => 95% de acierto; repetimos hasta conectar.
	var result: AttackResult = AttackResult.new()
	for i in 200:
		result = DamageCalculator.resolve_attack(1000.0, dmg, dmg, pen, 0.0, armor, dr, rng)
		if result.hit:
			break
	return result


func _near(label: String, value: float, expected: float, tolerance: float = 0.0001) -> void:
	_check("%s (obtenido %.4f, esperado %.4f)" % [label, value, expected], absf(value - expected) <= tolerance)


func _check(label: String, ok: bool) -> void:
	if ok:
		print("  PASS  ", label)
	else:
		print("  FAIL  ", label)
		_failures += 1
