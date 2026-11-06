# Fase 5 — Habilidades y AoE

Salida: habilidades diferenciadas y legibles. Tag: `v0.5-abilities-aoe`.

## Habilidades del jugador (provisionales)
| Tecla | Habilidad | Tipo | Mana | Cooldown | Detalle |
|---|---|---|---|---|---|
| 1 | **Brace** | Defensa propia | 20 | 3 s | Barrera 40 / 6 s. En Auto también se activa si una zona hostil va a impactarte en ≤ 0,8 s |
| 2 | **Burst** | AoE **instantáneo** | 12 | 0,5 s | En el cursor, radio 2,2, 14–20 de energía |
| 3 | **Collapse** | AoE con **wind-up** | 35 | 2,5 s | Cast 0,5 s (escala con CS) + telegraph 1,4 s, radio 3,0, 38–52 de energía. Preparación total ≈ 1,9 s |
| 4 | **Static Field** | Zona **persistente** | 25 | 1,5 s | Telegraph 0,6 s, dura 6 s, tick cada 0,5 s, radio 2,5, 5–7 por tick |

- Las habilidades 2–4 se apuntan con el **cursor** (si no hay suelo bajo el cursor, usan el objetivo seleccionado). Alcance 8–9 m y **línea de visión** requerida: si estás lejos o tapado, el personaje **camina hasta poder lanzar** ("Moving...") y luego lanza. Cualquier orden nueva lo cancela.
- Daño de **energía**: ignora armadura (la DR sí aplica). **No tiene tirada de impacto**: no se esquiva con Evasion, se esquiva saliendo de la zona.

## Enemigo con ataque telegráfico
- **Brute** (120 HP, armadura 30, lento): al tenerte a ≤ 3,5 m hace **Slam**: se ilumina en naranja 0,5 s (cast), y marca en rojo **donde estabas** durante 1,0 s antes de golpear (28–36 físico, radio 2,2). Hay tiempo razonable para reposicionarte; la pausa ayuda a planearlo.
- Brace en **Auto** funciona como defensa automática contra el Slam.

## Recurso: mana (nombre de trabajo)
- Recurso clásico: **100 de mana, regeneración lenta de 1,5/s**. Cada habilidad gasta mana **al resolverse** (un cast interrumpido no cuesta nada). Sin mana el botón muestra "No mana" y aparece el aviso flotante.
- **Cooldowns cortos** (0,5–3 s, estilo Diablo 2): el coste de mana es el limitador principal; el cooldown solo evita el spam inmediato.
- **Pociones de mana**, igual que las de vida: 5 cargas, +40 de mana (+8 por nivel de mejora), 6 s de cooldown, **tecla V**. Se recuperan con drops (esfera azul, 40 % de los drops de poción) y en el hub; se mejoran como un Estus. Siempre manuales.
- Los enemigos no usan mana: sus habilidades solo tienen cooldown propio (el Slam del Brute: 6 s).

## Arquitectura
```
AbilityData (datos) -> AbilityController.request_cast(slot, point)
   -> (opcional) caminar hasta rango/LoS (reusa MovementController.chase con un ancla)
   -> cast (quieto, sin atacar) -> efecto: BARRIER | AREA
AREA -> AreaEffect (nodo): instantáneo / wind-up / persistente; telegraph visual; daño vía DamageCalculator
AreaEffect se registra en el grupo "area_effects": la regla Auto de Brace lo consulta
EnemyAI usa la misma maquinaria (slot 0) con allow_approach = false
```
- `DamageCalculator.resolve_attack` ahora acepta `physical` (armadura sí/no) y `can_miss` (tirada sí/no).
- Wind-up de zona = tiempo propio (no depende de CS); el cast sí escala con CS.

## Escena de pruebas
Tres maniquíes agrupados cerca de (0,0) para probar AoE de grupo; `BruteSolo` en el rincón (10, −6); el muro y los pilares sirven para LoS.

## Pruebas automáticas
```
godot --headless -s res://tests/test_damage_calculator.gd
godot --headless -s res://tests/test_speed_calculator.gd
```

## Plan de pruebas
- [ ] Ambas suites en PASS.
- [ ] Mana: la barra azul baja al lanzar, regenera despacio, y sin mana el botón dice "No mana" y sale un aviso flotante. Un cast interrumpido no gasta mana.
- [ ] Mana potion (V): +40, 5 cargas, 6 s de cooldown; se rechaza con mana lleno; los grunts pueden soltar esferas azules.
- [ ] G rellena vida, mana y cargas de ambas pociones; U mejora ambas pociones.
- [ ] **Burst** sobre el grupo de maniquíes: anillo cian instantáneo, golpea a los 3 a la vez, el log muestra `armour 1.00` y nunca "MISS".
- [ ] Burst con el cursor lejos: "Moving...", camina hasta el alcance y lanza. Un click en el suelo lo cancela sin gastar cooldown.
- [ ] Burst apuntando detrás del muro: rodea hasta tener línea de visión antes de lanzar.
- [ ] **Collapse**: brillo cian 0,5 s quieto, telegraph morado que se llena 1,4 s, golpe fuerte. Con Inicio (+40 % CS) el cast baja a ~0,4 s pero el telegraph **no** cambia.
- [ ] **Static Field**: zona de 6 s con ticks; un enemigo que entra recibe ticks; al salir deja de recibir.
- [ ] Pausa durante un telegraph: se congela; las órdenes dadas en pausa se ejecutan al reanudar.
- [ ] Pausa + tecla 2 con el cursor sobre el grupo: queda "Queued" con ese punto; al reanudar lanza ahí.
- [ ] **Brute**: se acerca, brillo naranja, zona roja donde estabas; si te mueves fuera a tiempo no recibes daño; si te quedas, recibes ~22 (armadura aplica).
- [ ] Brace en **Auto** frente al Slam: la barrera salta unos 0,8 s antes del impacto y aparece "Absorbed N".
- [ ] Varios objetivos: Burst/Collapse alcanzan a los grunts del grupo y al Brute; los muertos no reciben daño ni errores.
- [ ] Pulsar un botón del HUD de una habilidad con un objetivo seleccionado lo usa como punto; sin objetivo, la acción se rechaza (log).
- [ ] Sin errores ni warnings en consola.

## Pendiente / decisiones abiertas
- Nombre final del recurso (hoy "mana"), valores de regeneración y costes, y kits por clase: Fase 6.
- Modo de apuntado (hoy: cursor directo, sin retícula), fuego amigo entre enemigos, resistencias elementales.
- Valores de daño, radios y tiempos: provisionales.
