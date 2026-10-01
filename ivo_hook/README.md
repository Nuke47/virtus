# SW:RP Grappling Hook Addon
### Versión 1.0.0 — Garry's Mod

Un arma de gancho con cable profesional y completamente funcional para servidores **Star Wars RP / DarkRP**.

---

## 📁 Estructura del Addon

```
grapple_hook_swrp/
├── addon.json
├── README.md
└── lua/
    ├── autorun/
    │   ├── grapple_hook_cl.lua     ← Hooks globales cliente
    │   └── grapple_hook_sv.lua     ← Integración DarkRP, comandos admin
    └── weapons/
        └── weapon_grapple_hook/
            ├── shared.lua          ← Configuración, base SWEP
            ├── init.lua            ← Lógica servidor (física, cuerda)
            └── cl_init.lua         ← HUD, partículas, render cuerda
```

---

## 🚀 Instalación

1. Copia la carpeta `grapple_hook_swrp/` completa a:
   ```
   garrysmod/addons/grapple_hook_swrp/
   ```
2. Reinicia el servidor o ejecuta `lua_openscript` si tienes acceso.
3. El arma aparecerá en el menú de spawn bajo la categoría **"SW:RP Equipment"**.

---

## 🎮 Controles

| Tecla            | Acción                            |
|------------------|-----------------------------------|
| **Click Izq.**   | Disparar el gancho                |
| **Click Der.**   | Soltar / retraer el gancho        |
| **DUCK (Ctrl)**  | Enrollar cable (acercarte)        |
| **WALK (Alt)**   | Desenrollar cable (alejarte)      |
| **RELOAD (R)**   | Activar/desactivar visibilidad    |
| `!grapple help`  | Ayuda en el chat en juego         |

---

## ⚙️ Configuración (`shared.lua` → `SWEP.GrappleConfig`)

| Parámetro            | Valor por defecto | Descripción                                      |
|----------------------|-------------------|--------------------------------------------------|
| `MaxRopeLength`      | `1200`            | Longitud máxima del cable (unidades GMod)        |
| `MinRopeLength`      | `80`              | Longitud mínima (evita atravesar geometría)      |
| `PullForce`          | `900`             | Fuerza de atracción hacia el ancla               |
| `SwingForce`         | `750`             | Fuerza lateral durante el balanceo               |
| `ReelSpeed`          | `120`             | Velocidad de enrollar/desenrollar (u/s)          |
| `AirControl`         | `0.35`            | Control en el aire mientras te balanceas (0–1)   |
| `MaxAttachDistance`  | `3000`            | Distancia máxima de alcance del gancho           |
| `FireCooldown`       | `0.6`             | Tiempo entre disparos (segundos)                 |
| `LandingGrace`       | `180`             | Unidades al suelo para auto-soltar               |
| `RopeColor`          | `(220, 190, 130)` | Color del cable (dorado/metálico por defecto)    |
| `AllowNonAdmins`     | `true`            | `false` = solo admins pueden usarlo              |
| `DarkRPJobWhitelist` | `{}`              | Lista de trabajos permitidos (vacía = todos)     |

### Ejemplo: Solo para Jedi y Mandalorianos
```lua
DarkRPJobWhitelist = { "Jedi Knight", "Jedi Master", "Mandalorian" },
```

### Ejemplo: Solo admins
```lua
AllowNonAdmins = false,
```

---

## 🛡️ Comandos de Administrador

Ejecutar desde consola del servidor o en-juego (requiere Super Admin):

```
grapple_give <nombre_jugador>   → Da el arma a un jugador
grapple_take <nombre_jugador>   → Quita el arma a un jugador
```

---

## 🔧 Integración con DarkRP Custom Shipments

En `grapple_hook_sv.lua`, descomenta el bloque `CustomShipments.AddEntity(...)` y ajusta:
- **precio** (`price`)
- **cantidad por envío** (`amount`)
- **trabajos permitidos** (`allowed`)

---

## ✨ Características

- ✅ Física realista de cuerda con tensión y elasticidad
- ✅ Sistema de balanceo (swing) con control de aire ajustable
- ✅ Enrollar/desenrollar cable en tiempo real
- ✅ HUD profesional con estética Star Wars
- ✅ Partículas de chispa al impactar
- ✅ Limpeza automática al morir/desconectarse
- ✅ Auto-soltar al aterrizar en el suelo
- ✅ Whitelist de trabajos DarkRP
- ✅ Comandos de administrador integrados
- ✅ Brillo pulsante en el punto de anclaje
- ✅ Viñeta de pantalla sutil durante el balanceo
- ✅ Comando de ayuda por chat (`!grapple help`)
- ✅ Crosshair personalizado

---

## 📝 Notas de Compatibilidad

- Probado con **DarkRP 2.8+** y frameworks **StarWarsRP**.
- Compatible con **ULX / SAM / Serverguard** para permisos.
- Si usas un framework de armas custom (ArcCW, TFA), puede requerir ajuste del `Base`.
- Los modelos de viewmodel/worldmodel usan la pistola de HL2 por defecto. Reemplaza `SWEP.ViewModel` y `SWEP.WorldModel` por tus modelos preferidos.

---

## 📄 Licencia

Libre para uso en servidores de Garry's Mod. No redistribuir como propio.
