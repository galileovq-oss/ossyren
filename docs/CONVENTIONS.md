# Convenciones — Ossyren

## Idioma
- **Inglés británico (en-GB) es la base del proyecto**: textos del juego, UI, nombres de datos e identificadores propios (`armour`, no `armor`). Ver [`STYLE_GUIDE.md`](STYLE_GUIDE.md).
- Los nombres de la API de Godot no se tocan (`Color`, `center`…).
- **Código y comentarios en inglés; commits y documentos de trabajo en español.**

## Godot / GDScript
- Versión fija: **4.7.2-stable**. Sin C#. No actualizar motor a mitad de fase; antes de hacerlo: commit limpio + branch de respaldo.
- GDScript tipado siempre que sea posible (`var x: int`, `-> void`).
- Indentación con **tabs** (ver `.editorconfig`).
- Archivos `.gd`: `snake_case.gd`. `class_name` en `PascalCase`.
- Escenas `.tscn` y Resources `.tres`: `PascalCase` para escenas reutilizables (`Player.tscn`, `EnemyBase.tscn`); `snake_case` para datos concretos (`rifle_standard.tres`).
- Variables/funciones: `snake_case`. Constantes: `UPPER_SNAKE`. Señales: pasado (`target_died`, `attack_resolved`). Privados con `_` inicial.
- Nodos en escena: `PascalCase`.
- Valores de balance fuera del código: en `Resource` (WeaponData, AbilityData, EnemyData…) o `@export`.
- Evitar un `Player.gd` gigante: composición de nodos + componentes pequeños.
- Capas de física 3D: 1 world, 2 player, 3 enemies, 4 projectiles, 5 interactables, 6 targetable.
- Acciones de input (nombres estables): `click_primary`, `click_secondary`, `pause_tactical`, `skill_1..4`, `weapon_set_swap`, `open_inventory`, `open_character`, `open_map`, `open_quests`, `use_potion` (esta última se registra desde `core/input_setup.gd`).
- Nodos que deben funcionar durante la pausa táctica usan `process_mode = ALWAYS` (se fija en su `_ready`): `TacticalPause`, `PlayerController`, `TargetingController`, `HUD`, `DebugTools`. Todo lo demás se congela con la pausa.
- Componentes de combate se localizan por nombre fijo bajo la entidad: `StatsComponent`, `HealthComponent`, `MovementController`, `CombatController`, `AbilityController`.

## Git
- Rama principal: `main`. Un commit por unidad funcional pequeña.
- Prefijos: `feat:` `fix:` `refactor:` `art:` `data:` `docs:` `test:`.
- Tag al cerrar cada hito (ver README). Tags anotados (`git tag -a`).
- Antes de refactor grande o cambio de motor: commit limpio y rama de respaldo.
- No mezclar cambios de arte, arquitectura y balance en un mismo commit.
- Commitear los archivos `.uid` que Godot 4.4+ genera junto a scripts/recursos. **No** commitear `.godot/`.

## Definition of Done (por hito)
- La escena abre sin errores ni warnings críticos.
- El flujo del hito funciona en una build ejecutable.
- Casos normales + al menos dos casos límite probados.
- Valores importantes editables desde datos/Inspector.
- README/notas actualizados (cómo probar, qué queda pendiente).
- Commit + tag creados y proyecto respaldado.

## Regla de producción
Si una decisión no es necesaria para el hito actual, se documenta como pendiente y no se construye.
