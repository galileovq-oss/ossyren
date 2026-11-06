extends SceneTree
## Design-rule checks on game data. Run from the project folder:
##   godot --headless -s res://tests/test_game_data.gd
## Exits with code 1 if anything fails.

const CLASS_PATHS: Array[String] = [
	"res://data/classes/vanguard.tres",
	"res://data/classes/ranger.tres",
	"res://data/classes/aether.tres",
]

var _failures: int = 0


func _initialize() -> void:
	for path in CLASS_PATHS:
		var data: ClassData = load(path) as ClassData
		_check("%s loads" % path, data != null)
		if data == null:
			continue
		var n: String = data.display_name
		_check("%s has stats" % n, data.stats != null and data.stats.max_health > 0)
		_check("%s has two weapon sets" % n, data.weapon_set_1 != null and data.weapon_set_2 != null)
		_check("%s has 1-4 active abilities" % n, data.abilities.size() >= 1 and data.abilities.size() <= 4)
		_check("%s has a passive" % n, data.passives.size() >= 1)
		if data.abilities.size() >= 1:
			var defence: AbilityData = data.abilities[0]
			_check("%s slot 1 is a defence (barrier, buff or evasive dash)" % n,
					(defence.targeting == AbilityData.Targeting.SELF
						and (defence.effect == AbilityData.Effect.BARRIER or defence.effect == AbilityData.Effect.BUFF))
					or defence.effect == AbilityData.Effect.DASH)
		if data.abilities.size() >= 2:
			_check("%s slot 2 is an offensive area" % n, data.abilities[1].effect == AbilityData.Effect.AREA)
		for ability in data.abilities:
			_check("%s/%s costs mana" % [n, ability.display_name], ability.mana_cost > 0.0)
			_check("%s/%s has a SHORT cooldown (<= 5 s)" % [n, ability.display_name], ability.cooldown <= 5.0)
			_check("%s/%s total preparation <= 3 attack intervals (~3.6 s)" % [n, ability.display_name],
					ability.cast_time + ability.area_wind_up <= 3.6)
		for passive in data.passives:
			_check("%s/%s is a passive" % [n, passive.display_name], passive.kind == AbilityData.Kind.PASSIVE)

	var boss_stats: StatBlock = load("res://data/enemies/overseer_stats.tres") as StatBlock
	_check("overseer stats load", boss_stats != null and boss_stats.max_health >= 300)
	var blight: AbilityData = load("res://data/abilities/blight.tres") as AbilityData
	_check("blight is a phase-2 persistent zone", blight != null and blight.min_enemy_phase == 2 and blight.area_duration > 0.0)

	print("\n%s (%d failure(s))" % ["OK" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


func _check(label: String, ok: bool) -> void:
	if ok:
		print("  PASS  ", label)
	else:
		print("  FAIL  ", label)
		_failures += 1
