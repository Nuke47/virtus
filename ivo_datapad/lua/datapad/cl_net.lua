-- cl_net.lua — Receptores de red del cliente
Datapad = Datapad or {}
Datapad.RT_ReportsCache  = Datapad.RT_ReportsCache  or {}
Datapad.ISB_ReportsCache = Datapad.ISB_ReportsCache or {}
Datapad.ISB_MessagesCache= Datapad.ISB_MessagesCache or {}
Datapad.ISB_TypingCache  = Datapad.ISB_TypingCache  or {}
Datapad.Shock_ArrestsCache = Datapad.Shock_ArrestsCache or {}

-- Actualización en tiempo real de la RT
net.Receive("Datapad_SendRTData", function()
    Datapad.RT_ReportsCache = net.ReadTable() or {}
    hook.Run("Datapad_RefreshRTUI")
end)

-- Actualización en tiempo real de la Shock DB
net.Receive("Datapad_SendShockData", function()
    Datapad.Shock_ArrestsCache = net.ReadTable() or {}
    hook.Run("Datapad_RefreshShockUI")
end)
