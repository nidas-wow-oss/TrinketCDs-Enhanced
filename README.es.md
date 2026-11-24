# TrinketCDs Enhanced

Muestra el tiempo de reutilización y los procs de tus abalorios, anillos, capa, arma y encantamientos de manos, botas y cinturón, y también los abalorios de tu grupo y de los enemigos de arena. Para World of Warcraft 3.3.5a (WotLK).

Basado en **TrinketCDs** de **Ridepad** ([Ridepad/TrinketCDs](https://github.com/Ridepad/TrinketCDs)) y su fork de **suprepupre** ([suprepupre/TrinketCDs](https://github.com/suprepupre/TrinketCDs)). La detección de abalorios enemigos se basa en el addon **TCT**. Todo el crédito del trabajo original es de sus autores.

*Read in English: [README.md](README.md)*

## Qué hace distinto esta versión

- **Abalorios de los enemigos de arena**: abalorio PvP y los dos abalorios de arena1 a arena5, cada uno con su propio marco para mover. Se ocultan fuera de arena.
- **Abalorios del grupo**: lo mismo para tus compañeros, si querés solo dentro de arena.
- **Menú propio** con `/tcd`, en inglés o en español según el idioma del cliente del juego.
- **Bloquear / desbloquear** para arrastrar cada marco, y un **Modo prueba** que muestra cómo queda con brillos y tiempos.
- **Brillo por objeto**: cada objeto elige su estilo de brillo (Action Button, Pixel o Proc Glow), y el brillo puede ir por fuera del borde.

## Instalación

1. Descargá este repositorio (**Code → Download ZIP**).
2. Copiá la carpeta `TrinketCDs` en `World of Warcraft/Interface/AddOns/`.
3. Reiniciá el juego o escribí `/reload`.

## Comandos

| Comando | Qué hace |
|---|---|
| `/tcd` | Abre el menú |
| `/tcd drag` | Bloquea o desbloquea los marcos |
| `/tcd test` | Modo prueba |
| `/tcd save <nombre>` / `/tcd load <nombre>` / `/tcd delete <nombre>` | Perfiles |
| `/tcd profiles` | Lista los perfiles |
| `/tcd help` | Todos los comandos |
