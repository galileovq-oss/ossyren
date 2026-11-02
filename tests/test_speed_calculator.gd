extends SceneTree
## Speed breakpoint tests. Run from the project folder:
##   godot --headless -s res://tests/test_speed_calculator.gd
## Exits with code 1 if anything fails.

var _failures: int = 0


func _initialize() -> void:
	var fast_t: PackedFloat32Array = PackedFloat32Array([0.0, 25.0, 60.0])
	var fast_r: PackedFloat32Array = PackedFloat32Array([1.0, 1.5, 2.0])
	var heavy_t: PackedFloat32Array = PackedFloat32Array([0.0, 60.0])
	var heavy_r: PackedFloat32Array = PackedFloat32Array([1.0, 1.5])

	_near("fast: +0% -> 1/1", SpeedCalculator.rate_for(0.0, fast_t, fast_r), 1.0)
	_near("fast: +24.9% still 1/1 (stacking between breakpoints does nothing)", SpeedCalculator.rate_for(24.9, fast_t, fast_r), 1.0)
	_near("fast: +25% -> 3/2", SpeedCalculator.rate_for(25.0, fast_t, fast_r), 1.5)
	_near("fast: +59% still 3/2", SpeedCalculator.rate_for(59.0, fast_t, fast_r), 1.5)
	_near("fast: +60% -> 2/1", SpeedCalculator.rate_for(60.0, fast_t, fast_r), 2.0)
	_near("fast: +500% capped at 2/1", SpeedCalculator.rate_for(500.0, fast_t, fast_r), 2.0)
	_near("heavy: +500% capped at 3/2 (identity of slow weapons)", SpeedCalculator.rate_for(500.0, heavy_t, heavy_r), 1.5)
	_near("negative bonus -> tier 0", SpeedCalculator.rate_for(-20.0, fast_t, fast_r), 1.0)
	_near("interval 0.9 at 3/2 = 0.6", SpeedCalculator.interval(0.9, 1.5), 0.6)
	_near("interval 0.9 at 2/1 = 0.45", SpeedCalculator.interval(0.9, 2.0), 0.45)
	_near("next threshold from +10% = 25", SpeedCalculator.next_threshold(10.0, fast_t, fast_r), 25.0)
	_near("next threshold from +70% = -1 (cap)", SpeedCalculator.next_threshold(70.0, fast_t, fast_r), -1.0)
	_near("heavy next threshold from +0% = 60", SpeedCalculator.next_threshold(0.0, heavy_t, heavy_r), 60.0)
	_near("cast: +39% still 1/1", SpeedCalculator.rate_for(39.0, SpeedCalculator.cast_thresholds(), SpeedCalculator.cast_rates()), 1.0)
	_near("cast: +40% -> 1.25", SpeedCalculator.rate_for(40.0, SpeedCalculator.cast_thresholds(), SpeedCalculator.cast_rates()), 1.25)
	_near("cast: +999% capped at 1.5", SpeedCalculator.rate_for(999.0, SpeedCalculator.cast_thresholds(), SpeedCalculator.cast_rates()), 1.5)
	_check("label 1.0 = 1/1", SpeedCalculator.rate_label(1.0) == "1/1")
	_check("label 1.5 = 3/2", SpeedCalculator.rate_label(1.5) == "3/2")
	_check("label 2.0 = 2/1", SpeedCalculator.rate_label(2.0) == "2/1")
	_check("label 1.25 = 5/4", SpeedCalculator.rate_label(1.25) == "5/4")

	print("\n%s (%d failure(s))" % ["OK" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


func _near(label: String, value: float, expected: float, tolerance: float = 0.0001) -> void:
	_check("%s (got %.4f, expected %.4f)" % [label, value, expected], absf(value - expected) <= tolerance)


func _check(label: String, ok: bool) -> void:
	if ok:
		print("  PASS  ", label)
	else:
		print("  FAIL  ", label)
		_failures += 1
