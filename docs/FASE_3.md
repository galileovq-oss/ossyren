# Fase 3 — Pausa táctica y defensas

Salida: loop RTwP controlable. Tag: `v0.3-rtwp`.

## Controles (provisionales)
| Entrada | Acción |
|---|---|
| Space | Pausa táctica on/off |
| Click izq. suelo / enemigo | Mover / atacar (también en pausa: se ejecuta al reanudar) |
| Click der. | Cancela orden, objetivo y acciones en cola |
| 1–4 | Ranuras de habilidad (solo la 1 tiene habilidad: **Brace**) |
| F | Poción de salud (siempre manual) |
| Botones del HUD | Igual que las teclas; el botón pequeño bajo la ranura alterna Auto / Manual |
| K / R / G / U | *Debug*: matar objetivo / reiniciar / recargar pociones (hub) / mejorar poción |

## Qué se construyó
- `TacticalPause`: pausa la simulación; HUD, hover/picking y `PlayerController` siguen activos (`PROCESS_MODE_ALWAYS`).
- `AbilityData` + `AbilityController`: cooldowns, Auto/Manual (regla: usar si la salud ≤ umbral), pasivas como bonos planos.
- **Brace** (activa): barrera de 40 puntos durante 6 s, cooldown 20 s. **Hardened** (pasiva): +10 % Damage Reduction.
- `HealthComponent`: barrera (absorbe primero y caduca) y curación. `StatsComponent`: modificadores aditivos por fuente.
- Pociones: ver modelo abajo. HUD mínimo en código. Las acciones pedidas en pausa se **encolan** y se ejecutan al reanudar.

## Decisiones tomadas
- Acciones en pausa: **se encolan y se ejecutan al reanudar** (estilo Baldur's Gate). Bandera `PlayerController.queue_actions_while_paused`.
- Habilidades: solo cooldown por ahora (sin coste de recurso).
- Idioma: inglés en código y comentarios; español en commits y documentos de trabajo. Texto del juego en inglés británico (ver `STYLE_GUIDE.md`).
- **Modelo de pociones:** un único tipo con **5 cargas máx.**; no es un "potionfest" ni algo ultra limitado.
  - Las cargas se recuperan con **drops de enemigos y cofres** (autopickup) y en el **hub** (punto de recarga).
  - Sin tiers: la poción **mejora** como un Estus (nivel de mejora ↑ cura), con un recurso o sidequest que siempre aparece. Los drops no se eliminan.
  - Frecuencia de drops y fuente de mejoras: a definir en balance (Fase 7/8). Hoy: 30 % de los grunts sueltan 1 carga (`potion_drop_chance`), el pickup solo se recoge si hay hueco.

## Plan de pruebas
- [ ] Space: banner + oscurecido; enemigos, cooldowns y textos flotantes se congelan; Space reanuda.
- [ ] En pausa: el hover funciona, click en enemigo lo selecciona, click en suelo muestra el marcador, los botones del HUD responden.
- [ ] Las órdenes dadas en pausa se ejecutan al reanudar (mover / perseguir / atacar).
- [ ] Click der. en pausa borra la orden y la cola.
- [ ] Brace: burbuja cian, texto "Absorbed N", caduca a los 6 s, el botón muestra el cooldown.
- [ ] Pulsar 1 en pausa → "Queued"; al reanudar se activa. En cooldown no hace nada.
- [ ] Brace en Auto se activa sola con ≤ 50 % de salud; las pociones nunca se usan solas.
- [ ] F cura 50 (hasta 5 cargas, 8 s entre usos); se rechaza con salud completa; se puede encolar en pausa.
- [ ] Un grunt muerto puede soltar una esfera verde; al pasar cerca recupera 1 carga solo si no está llena.
- [ ] G recarga al máximo; U sube el nivel de mejora y la cura (+10 por nivel, máx. 5).
- [ ] Hardened: el log muestra `x DR 0.90` en los golpes al jugador.
- [ ] K en el objetivo durante la pausa → se deselecciona y no elige otro.
- [ ] R en pausa reinicia sin pausa. Morir quita la pausa y bloquea pausar.
- [ ] Spam de Space, pausar durante el wind-up, pausar con acciones en cola: sin errores en consola.

## Pendiente
- Costes de habilidades (¿energía?) y kits por clase: Fases 5–6.
- Reglas finales de drops, cofres, recarga en el hub y fuente de mejoras: Fases 7–8.
- Gamepad queda para después del vertical slice.
