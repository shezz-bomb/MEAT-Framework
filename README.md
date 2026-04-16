MEAT Framework — Roblox Developer Portfolio

Sistemas modulares para juegos de combate en Luau. Código autocontenido y listo para producción.


ESTRUCTURA DEL REPOSITORIO

MEAT-Framework/
├── backend/
│   ├── DirectorSystem/
│   │   ├── DirectorMemory.lua
│   │   ├── DirectorMonitor.lua
│   │   ├── DirectorDecider.lua
│   │   └── DirectorExecutor.lua
│   ├── Economy/
│   │   ├── RelicsManager.lua
│   │   └── MysteryBoxes.lua
│   └── Init.lua
├── powers/
│   ├── CadenaDeCarne_Server.lua
│   ├── CadenaDeCarne_Client.lua
│   ├── TransformacionVacaHumana.lua
│   ├── AbrazoMasaLlorosa.lua
│   ├── OndaOlorPutrefacto.lua
│   ├── DesmembramientoVoluntario.lua
│   └── NamNamFinal.lua
├── ui/
│   └── HUDScript.lua
├── README.md
└── LICENSE


HABILIDADES (POWERS)

Cada habilidad es autocontenida. Copia el archivo .lua, ajusta los IDs de sonido si quieres, y funciona.

Cadena de Carne — Gancho
Atrae al enemigo más cercano con una cadena helicoidal procedural. Incluye cliente con aiming por Beam.

Transformacion Vaca Humana — Buff
+50 HP máximo, +30% daño durante 8s. Aura visual pulsante, tinte rojo y sonidos 3D.

Abrazo Masa Llorosa — Stun
Inmoviliza a un enemigo 3s. Efectos de masa viscosa, lágrimas en UI y blur de pantalla.

Onda Olor Putrefacto — AoE + DoT
Daño inicial (25) + veneno (5/s durante 3s) en radio 12. Onda expansiva y partículas de gas.

Desmembramiento Voluntario — Proyectil
Lanza un brazo que causa 35 de daño al impactar. Trail de sangre e impacto alineado a superficies.

Nam Nam Final — Ejecución
Si el enemigo tiene menos del 30% de HP, muerte instantánea. Explosión de sangre, trozos de carne y flash rojo.


BACKEND

DirectorSystem
IA que monitoriza métricas de jugadores, calcula "ira" y decide eventos dinámicos (meteoros, tormentas, cacerías).

Economy
Gestión de reliquias (RelicsManager) y cajas de loot con probabilidades ponderadas (MysteryBoxes).


UI

HUDScript
Interfaz generada dinámicamente por código. Muestra recursos (Entropía, Fragmentos) con cálculo de +/seg y panel de inventario desplegable.


POR QUÉ ESTE PORTAFOLIO

- Modular: cada sistema funciona de forma independiente.
- Autocontenido: las habilidades no requieren módulos externos.
- Limpio y comentado: --!strict, validaciones anti-exploit, limpieza automática de recursos.
- Game Feel AAA: VFX procedurales, sonidos 3D, efectos de cámara y luces dinámicas.


AUTOR

(Bombito / shezz-bomb)
Roblox: @shezz-bomb
Twitter/X: @Siposo1222
GitHub: shezz-bomb

"No cuento años. Cuento sistemas complejos entregados."


LICENCIA

MIT (c) 2026 Cristhian Ayala (Bombito)

El código es libre para usar, modificar y distribuir. Mi tiempo y experiencia para adaptarlo a tu proyecto son de pago.
