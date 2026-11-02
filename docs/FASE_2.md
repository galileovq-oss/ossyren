# Fase 2 — Combate automático

Salida: combate 1 contra 1 y 1 contra varios sin input continuo. Tag: `v0.2-auto-combat`.

## Decisiones tomadas
- Click en el suelo **deselecciona** al objetivo y cancela el ataque en curso.
- Evitación entre agentes **RVO** (NavigationAgent3D): jugador prioridad 1.0, enemigos 0.5.
- Click en enemigo = auto-ataque continuo mientras el objetivo sea válido y esté en rango. Al morir, el personaje se detiene (no adquiere otro).
- Un ataque tiene **impacto diferido** (`impact_delay`). Si antes del impacto el objetivo muere, sale de rango/LoS o das una orden de movimiento, el ataque se **cancela sin daño**.

## Fórmulas (provisionales, en `combat/damage/damage_calculator.gd`)
| Paso | Regla |
|---|---|
| Impacto | `clamp(Accuracy / (Accuracy + Evasion), 5%, 95%)` — siempre hay fallo posible |
| Armadura | efectiva = `max(0, Armour − ArmourPen)`; pasa `1 − ef/(ef+100)` |
| DR | pasa `1 − clamp(DR, 0, 75%)`, capa separada tras la armadura |
| Final | `max(1, round(base × armadura × DR))` |

## Arquitectura
```
PlayerController / EnemyAI  --órdenes-->  MovementController (persigue, in_range) + CombatController (ciclo de ataque)
CombatController -> DamageCalculator.resolve_attack() -> AttackResult -> HealthComponent.receive_attack()
HealthComponent: attack_received / health_changed / died  -> CombatFeedback, EnemyBase, PlayerController
StatsComponent: único punto de lectura de stats (Fase 7 sumará equipo/atributos/talentos aquí)
```
Convención: toda entidad de combate tiene hijos con nombres fijos `StatsComponent`, `HealthComponent`, `MovementController`, `CombatController`.
Variantes de enemigo = `EnemyBase.tscn` con otros datos (`stats`, `weapon`, `aggressive`).

## Escena de pruebas
| Nodo | Para qué |
|---|---|
| DummyNear | Maniquí normal: tasa de acierto ~91% con melee |
| DummyArmoured | Armadura 100: el daño base se reduce a la mitad; el rifle (pen 15) pierde menos |
| DummyEvasive | Evasión 100: acierto ~50% |
| DummyBehindWall | Probar LoS del rifle |
| GruntSolo | Combate 1 contra 1 (aggro a 9 m o si le disparas) |
| GruntPackA/B/C | 1 contra varios: te rodean, RVO evita que se apilen |

## Plan de pruebas
- [ ] Pruebas de fórmulas: `godot --headless -s res://tests/test_damage_calculator.gd` (todas PASS).
- [ ] Click en maniquí: se acerca, ataca solo y aparecen números/“Fallo”. Log en el overlay.
- [ ] Hay fallos ocasionales incluso contra el maniquí normal.
- [ ] DummyArmoured: daño visiblemente menor; con rifle algo mayor (penetración).
- [ ] DummyEvasive: ~50% de fallos.
- [ ] Mover durante el wind-up: el ataque se cancela sin daño.
- [ ] K sobre el objetivo mientras te acercas: te detienes, no eliges otro.
- [ ] GruntSolo: te persigue, ataca; ganas o pierdes sin tocar nada tras el click inicial.
- [ ] Pack de 3: te rodean sin solaparse; puedes huir (tu velocidad 6 > 4,5).
- [ ] Rifle: aggro de un grunt desde >9 m al dispararle.
- [ ] Morir: overlay indica “ha caído”, el input se desactiva, R reinicia.
- [ ] Sin errores ni warnings en la consola.

## Pendiente / fuera de alcance
- Animaciones reales (hoy el feedback es procedural), AS/CS y breakpoints (Fase 4), defensas activas (Fase 3).
- Barras de vida (UI real en Fase 9): hoy solo overlay y números flotantes.
- La regla de DR es provisional; revisar cuando existan clases y equipo.
