class_name EquipmentComponent
extends Node
## Two weapon sets (I and II). Swapping happens DURING combat (no pause) with a short delay; during the
## delay the character cannot start attacks, then automatic behaviour continues with the new weapon.
## Phase 7 extends this with armour slots, requirements and a real inventory.

signal swap_started(to_index: int, duration: float)
signal weapon_changed(weapon: WeaponData, set_index: int)

## Weapon in each set (index 0 = Set I, 1 = Set II).
@export var sets: Array[WeaponData] = []
## Seconds the swap takes.
@export var swap_time: float = 0.4
## Extra cooldown before the next swap, applied only when the swap happened IN COMBAT.
@export var combat_swap_cooldown: float = 1.5
## Debug only: weapons that can be cycled into a set.
@export var library: Array[WeaponData] = []

var active_set: int = 0
var swapping: bool = false

var _pending_set: int = 0
var _combat: CombatController
var _swap_in_combat: bool = false
var _cooldown_left: float = 0.0
var _swap_left: float = 0.0


func _ready() -> void:
	_combat = get_parent().get_node_or_null("CombatController") as CombatController
	if sets.is_empty():
		# The player root exposes 'weapon_sets' from its ClassData.
		var inherited: Variant = get_parent().get("weapon_sets")
		if inherited is Array:
			for item in inherited:
				if item is WeaponData:
					sets.append(item)


func get_active_weapon() -> WeaponData:
	return get_set_weapon(active_set)


func get_set_weapon(index: int) -> WeaponData:
	if index < 0 or index >= sets.size():
		return null
	return sets[index]


func get_swap_left() -> float:
	return _swap_left


func get_cooldown_left() -> float:
	return _cooldown_left


func can_swap() -> bool:
	return sets.size() >= 2 and not swapping and _cooldown_left <= 0.0


func request_swap() -> bool:
	if not can_swap():
		return false
	swapping = true
	_swap_in_combat = _combat != null and _combat.is_in_combat()
	_pending_set = (active_set + 1) % sets.size()
	_swap_left = swap_time
	swap_started.emit(_pending_set, swap_time)
	CombatLog.add("Swapping to Set %s (%s)" % ["I" if _pending_set == 0 else "II", sets[_pending_set].display_name])
	return true


## Debug: replaces the weapon of a set with the next one in `library`.
func debug_cycle_set(index: int) -> void:
	if library.is_empty() or index < 0 or index >= sets.size():
		return
	var current: int = library.find(sets[index])
	sets[index] = library[(current + 1) % library.size()]
	if index == active_set and not swapping:
		weapon_changed.emit(sets[index], index)
	CombatLog.add("Debug: Set %s is now %s" % ["I" if index == 0 else "II", sets[index].display_name])


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if not swapping:
		return
	_swap_left -= delta
	if _swap_left <= 0.0:
		swapping = false
		_swap_left = 0.0
		active_set = _pending_set
		if _swap_in_combat:
			_cooldown_left = combat_swap_cooldown
		weapon_changed.emit(get_active_weapon(), active_set)
