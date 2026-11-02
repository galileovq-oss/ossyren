class_name StatsComponent
extends Node
## Punto UNICO de lectura de estadisticas. Hoy devuelve los valores base; en Fase 7 sumara
## equipo, atributos y talentos aqui, sin tocar al resto de sistemas.

@export var base: StatBlock


func _ready() -> void:
	if base == null:
		# Las entidades con datos en la raiz (EnemyBase) exponen 'stats'.
		var inherited: Variant = get_parent().get("stats")
		if inherited is StatBlock:
			base = inherited
	if base == null:
		push_warning("StatsComponent en '%s' sin StatBlock; usando valores por defecto." % get_parent().name)
		base = StatBlock.new()


func get_display_name() -> String:
	return base.display_name


func get_max_health() -> int:
	return base.max_health


func get_accuracy() -> float:
	return base.accuracy


func get_evasion() -> float:
	return base.evasion


func get_armor() -> float:
	return base.armor


func get_armor_penetration() -> float:
	return 0.0  # Hook para equipo/talentos (Fase 7). El arma aporta la suya.


func get_damage_reduction() -> float:
	return base.damage_reduction


func get_move_speed() -> float:
	return base.move_speed


func get_body_radius() -> float:
	return base.body_radius
