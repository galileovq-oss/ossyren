# Fase 4 — Armas y velocidad

Salida: dos sets de armas funcionales y velocidad escalable. Tag: `v0.4-weapons-speed`.

## Modelo de velocidad
- **Attack Speed (AS)** y **Cast Speed (CS)** son bonos en %. La cadencia efectiva solo cambia al alcanzar un **breakpoint**; acumular entre breakpoints no hace nada.
- Cada arma define sus umbrales y su techo (`speed_thresholds` / `speed_rates`, el último valor es el techo de ese tipo de arma).
- `intervalo = intervalo_base / tasa`. Tasas: `1/1` = 1,0 · `3/2` = 1,5 · `2/1` = 2,0 ataques por intervalo base.
- El impacto cae en `impact_fraction` del intervalo, así la animación queda sincronizada a cualquier velocidad.
- CS tiene breakpoints propios, más conservadores: +0 % → 1,0 · +40 % → 1,25 · +100 % → 1,5. Las habilidades instantáneas (`cast_time = 0`) nunca se retrasan. El cooldown es independiente de CS y empieza al terminar el cast.

## Armas de prueba (provisionales)
| Arma | Familia | Rango | Daño | Pen. | Intervalo base | Umbrales AS → tasa | Techo |
|---|---|---|---|---|---|---|---|
| Test Maul | Melee pesada | 2,3 m | 24–32 | 25 | 2,0 s | 0 / 60 → 1/1, 3/2 | 3/2 |
| Test Blade | Melee rápida | 1,8 m | 8–11 | 0 | 0,9 s | 0 / 25 / 60 → 1/1, 3/2, 2/1 | 2/1 |
| Test Rifle | Rifle | 10 m (LoS) | 9–13 | 15 | 1,4 s | 0 / 40 / 90 → 1/1, 3/2, 2/1 | 2/1 |

## Sets de armas
- `EquipmentComponent`: Set I (Maul) y Set II (Rifle). **Q/E** (o el botón del HUD) cambia de set **sin pausar**, con 0,4 s de demora.
- Durante el cambio no se puede iniciar un ataque y un wind-up en curso se cancela. Al terminar, el comportamiento automático continúa con la nueva arma (rango y línea de visión se reevalúan al vuelo).
- El cambio pedido en pausa se **encola** como el resto de acciones.
- **Cooldown de 1,5 s solo si el cambio ocurre en combate** (con objetivo engranado o hasta 4 s después de dar/recibir un ataque). Fuera de combate se puede cambiar libremente.

## Cast time (infraestructura)
- `AbilityData.cast_time` + `AbilityController`: mientras lanzas, el personaje se queda quieto y no ataca. Cualquier orden nueva **interrumpe** el cast (sin efecto ni cooldown). Morir también.
- Habilidad de prueba en la ranura 2: **Channelled Brace** (cast 1,5 s, barrera 60, cooldown 12 s).

## Controles nuevos / debug
| Entrada | Acción |
|---|---|
| Q / E | Cambiar set de armas |
| RePág / AvPág | AS +5 % / −5 % |
| Inicio / Fin | CS +5 % / −5 % |
| Retroceso | Reiniciar AS y CS |
| B / N | Cambiar el arma del Set I / Set II (Maul → Blade → Rifle) |

El overlay muestra AS, tasa (`1/1`, `3/2`, `2/1`), intervalo efectivo y el siguiente breakpoint.

## Pruebas automáticas
```
godot --headless -s res://tests/test_speed_calculator.gd
godot --headless -s res://tests/test_damage_calculator.gd
```

## Plan de pruebas
- [ ] Ambas suites de pruebas en PASS.
- [ ] Maul: golpes lentos y fuertes. Blade (B): rápido y ligero. Rifle: dispara desde 10 m y se detiene solo con LoS.
- [ ] AS con Blade: de +0 a +24 % el intervalo no cambia; a +25 % pasa a 0,60 s (3/2); a +60 % a 0,45 s (2/1); más allá no sube.
- [ ] AS con Maul: a +60 % pasa a 1,33 s (3/2) y **nunca** llega a 2/1, aunque subas +500 %.
- [ ] La embestida/disparo coincide con el golpe en 1/1, 3/2 y 2/1 (sin desfase visible).
- [ ] Q durante un combate: aparece "Swapping", no ataca durante 0,4 s, y sigue con el arma nueva sin tocar nada más.
- [ ] Q durante el wind-up: el ataque se cancela sin daño. Q mientras persigues: el rango cambia a la nueva arma.
- [ ] Q en pausa: queda "Queued" y se ejecuta al reanudar.
- [ ] Cambio en combate: el botón muestra "Cooldown 1.5s" y no deja volver a cambiar hasta que termina. Fuera de combate (≥4 s sin pelear) no hay cooldown.
- [ ] Channelled Brace: 1,5 s quieto, sin atacar. Home +40 % → ~1,2 s; +100 % → 1,0 s. Brace normal no cambia.
- [ ] Click en el suelo durante el cast: se interrumpe, sin efecto y sin cooldown. Terminarlo inicia el cooldown de 12 s.
- [ ] Sin errores ni warnings en consola.

## Pendiente / decisiones abiertas
- Valores de breakpoints, tiempos de cambio y daños: provisionales, a ajustar jugando.
- Decidido: casteo inmóvil (cualquier orden lo interrumpe) y cooldown de cambio de set solo en combate.
- Techo de velocidad de movimiento por equipo/talentos: se decide en la Fase 7, cuando exista el sistema de equipo.
- Fuentes reales de AS/CS (equipo, talentos): Fase 7.
