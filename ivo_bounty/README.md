# ☠ Bounty Hunter System — GLua Addon para Garry's Mod

Sistema completo de cazarrecompensas con UI, persistencia de datos y hooks para integración.

---

## 📁 Estructura de archivos

```
bounty_hunter/
├── addon.json
└── lua/
    ├── autorun/
    │   └── bounty_hunter_loader.lua        ← Punto de entrada
    └── bounty_hunter/
        ├── shared/
        │   └── config.lua                  ← Configuración global
        ├── server/
        │   └── sv_bounty.lua               ← Lógica servidor
        └── client/
            └── cl_bounty.lua               ← UI y HUD cliente
```

---

## 🚀 Instalación

1. Copia la carpeta `bounty_hunter/` dentro de `garrysmod/addons/`
2. Reinicia el servidor o usa `lua_openscript_cl` / `lua_openscript` para recargar.
3. Los datos se guardan automáticamente en `garrysmod/data/bounty_hunter/bounties.txt`

---

## ⚙️ Configuración (`shared/config.lua`)

| Variable              | Por defecto | Descripción                                          |
|-----------------------|-------------|------------------------------------------------------|
| `MinBounty`           | 100         | Recompensa mínima permitida                          |
| `MaxBounty`           | 100000      | Recompensa máxima permitida                          |
| `BountyDuration`      | 3600        | Segundos antes de que expire (0 = sin límite)        |
| `TaxRate`             | 0.05        | Porcentaje de comisión al cobrar (5%)                |
| `MaxBountiesPerTarget`| 3           | Máximo de recompensas activas por objetivo           |
| `PlaceCooldown`       | 300         | Cooldown (segundos) mismo emisor → mismo objetivo    |
| `NotifyAll`           | true        | Notificar a todos al colocar/cobrar                  |
| `CurrencySymbol`      | "$"         | Símbolo de moneda mostrado en UI                     |

---

## 🎮 Controles

| Acción                            | Método                          |
|-----------------------------------|---------------------------------|
| Abrir menú de recompensas         | `F3` o `!bounty` en el chat     |
| Comandos de consola               | `bounty_menu`, `bounty_list`    |
| Admin: cancelar todas             | `bounty_cancel_all` (superadmin)|

---

## 🔗 Integración DarkRP / economía

El addon incluye soporte nativo para DarkRP. Al cobrar una recompensa:

```lua
-- En sv_bounty.lua, ya incluido:
if attacker.addMoney then
    attacker:addMoney(payout)
end
```

Para otros sistemas de economía, usa el hook:

```lua
hook.Add("BountySystem_OnClaimed", "MiSistema_Pago", function(bountyID, bounty, claimer, payout)
    MiEconomia.DarDinero(claimer, payout)
end)
```

---

## 🪝 Hooks disponibles

```lua
-- Al colocar una recompensa
hook.Add("BountySystem_OnPlaced", "nombre", function(id, bountyData) end)

-- Al cobrar una recompensa
hook.Add("BountySystem_OnClaimed", "nombre", function(id, bountyData, claimer, payout) end)

-- Validación personalizada antes de cobrar (retorna false, "razón" para bloquear)
hook.Add("BountySystem_CanClaim", "nombre", function(claimer, bountyData)
    -- return false, "No puedes cobrar esto"
end)
```

---

## 📡 Network Strings

| String                        | Descripción                              |
|-------------------------------|------------------------------------------|
| `BountySystem_OpenMenu`       | Servidor → Cliente: abrir menú           |
| `BountySystem_SyncBounties`   | Servidor → Cliente: sincronizar lista    |
| `BountySystem_PlaceBounty`    | Cliente → Servidor: colocar recompensa   |
| `BountySystem_ClaimBounty`    | Cliente → Servidor: cobrar recompensa    |
| `BountySystem_CancelBounty`   | Cliente → Servidor: cancelar recompensa  |
| `BountySystem_Notify`         | Servidor → Cliente: notificación         |

---

## 🛡️ Seguridad

- Todas las acciones se validan en el servidor (nunca confiar en el cliente).
- El cobro de recompensas se dispara en `PlayerDeath` para evitar exploits.
- Los admins pueden cancelar cualquier recompensa con `bounty_cancel_all`.

---

## 📝 Licencia

Libre para uso en servidores privados y públicos. Créditos apreciados.
