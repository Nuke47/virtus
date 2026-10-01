# IVO Framework
Este es el núcleo visual y de interfaz de usuario del servidor.

**Módulos Incluidos:**
- **Core:** Funciones de utilidad (`sh_utils.lua`), colores y temas estandarizados (`cl_theme.lua`).
- **HUD:** 
  - `cl_hud_main.lua` / `cl_hud2.lua` (El HUD principal de vida y escudo).
  - `cl_defcon_hud.lua` (HUD del nivel de Defcon, portado de SAM).
  - `cl_netgraph.lua` (HUD de FPS y Ping, portado de custom_netgraph).
  - `cl_sw_gas_hud.lua` (HUD del nivel de gas para armas).
  - `cl_xp_hud.lua` (HUD de subida de experiencia).
  - `cl_tickets_hud.lua` y `cl_vote_hud.lua` (HUDs administrativos).
  - `cl_compass.lua` (Brújula).
  - `cl_gunselector.lua` (Selector de armas en pantalla).
  - `cl_overhead_voice.lua` (Iconos 3D de micrófono sobre la cabeza).
  - `cl_scoreboard.lua` (La tabla de puntuaciones/jugadores).
  - `cl_virtus_notifications.lua` (Sistema de notificaciones emergentes).
  - `cl_virtus_sway.lua` (Movimiento inmersivo de la cámara al caminar).
- **Chatbox:** `virtus_chatbox` completamente integrado, junto con el comando `/roll`.
- **Menú de Escape:** `virtus_esc_menu` integrado con sus materiales (Imperio/Rebelde) y sonidos.
