-- ==========================================================
-- IVOSAM: TICKETS SYSTEM - ADMIN CHAT RECEIVER
-- ==========================================================

net.Receive("IVOSAM_Ticket_ChatAdmin", function()
    local sender = net.ReadEntity()
    local mensaje = net.ReadString()

    -- Verificamos que el jugador sea válido por seguridad
    if not IsValid(sender) then return end

    local chatLines = {}

    -- 1. Nombre (Azul o "Tu" en Naranja)
    if sender == LocalPlayer() then
        table.insert(chatLines, Color(255, 128, 0)) -- Naranja
        table.insert(chatLines, "Tu")
    else
        table.insert(chatLines, Color(0, 150, 255)) -- Azul
        table.insert(chatLines, sender:Nick())
    end

    -- 2. El texto intermedio fijo (en Blanco)
    table.insert(chatLines, Color(255, 255, 255))
    table.insert(chatLines, " para admins: ")

    -- 3. El mensaje ingresado (en Verde)
    table.insert(chatLines, Color(0, 255, 0)) -- Verde
    table.insert(chatLines, mensaje)

    -- Enviamos todo a la caja de chat local
    chat.AddText(unpack(chatLines))
    
end)