-- ==========================================================
-- IVOSAM: TICKETS SYSTEM - SERVER BACKEND
-- ==========================================================

util.AddNetworkString("IVOSAM_Ticket_Nuevo")
util.AddNetworkString("IVOSAM_Ticket_ChatAdmin")
util.AddNetworkString("IVOSAM_Ticket_Accion")
util.AddNetworkString("IVOSAM_Ticket_Update")
util.AddNetworkString("IVOSAM_Ticket_Cerrado")
util.AddNetworkString("IVOSAM_Ticket_Notificar_Claim")

my_admin = my_admin or {}
IVOSAM_Tickets = IVOSAM_Tickets or {}
IVOSAM_Tickets_Estado = IVOSAM_Tickets_Estado or {}

-- Función para procesar la entrada de texto centralizada
local function ProcesarEntradaTicket(ply, mensaje)
    if not IsValid(ply) then return end
    if not mensaje or string.Trim(mensaje) == "" then return end

    if IVO_SAM.HasPermission(ply, "tickets") then
        net.Start("IVOSAM_Ticket_ChatAdmin")
            net.WriteEntity(ply)
            net.WriteString(mensaje)
        net.Broadcast() 
    else
        local ticketID = math.random(1000, 9999)
        local ticketData = {
            id = ticketID,
            creador = ply,
            nombre = ply:Nick(),
            steamid = ply:SteamID(),
            msg = mensaje,
            tiempo = CurTime()
        }

        IVOSAM_Tickets[ticketID] = ticketData

        net.Start("IVOSAM_Ticket_Nuevo")
            net.WriteTable(ticketData)
        net.Broadcast()

        ply:ChatPrint("[IVOSAM] Tu reporte ha sido enviado al staff activo.")
    end
end

-- Registro del comando !asay
hook.Add("InitPostEntity", "IVOSAM_Register_Asay_Command", function()
    if not my_admin or not my_admin.RegisterCommand then return end
    my_admin.RegisterCommand("asay", function(ply, args)
        local mensaje = table.concat(args, " ")
        ProcesarEntradaTicket(ply, mensaje)
    end)
end)

hook.Add("PlayerSay", "IVOSAM_Ticket_At_Shortcut", function(ply, text, teamChat)
    if string.sub(text, 1, 1) == "@" then
        local mensaje = string.sub(text, 2)
        ProcesarEntradaTicket(ply, string.Trim(mensaje))
        return ""
    end
end)

-- Receptor de las acciones del HUD interactivo
net.Receive("IVOSAM_Ticket_Accion", function(len, ply)
    if not IsValid(ply) or not IVO_SAM.HasPermission(ply, "tickets") then return end

    local accion = net.ReadString()
    local ticketID = net.ReadInt(16)
    local ticket = IVOSAM_Tickets[ticketID]

    if not ticket then return end

    if accion == "claim" then
        if IVOSAM_Tickets_Estado[ticketID] then
            ply:ChatPrint("[IVOSAM] Este ticket ya está siendo atendido por " .. IVOSAM_Tickets_Estado[ticketID])
            return
        end

        IVOSAM_Tickets_Estado[ticketID] = ply:Nick()
        
        -- Notificamos a todos para que actualicen su HUD (Cambiar botón de ATENDER a GOTO/BRING)
        net.Start("IVOSAM_Ticket_Notificar_Claim")
            net.WriteInt(ticketID, 16)
            net.WriteString(ply:Nick())
        net.Broadcast()

    elseif accion == "goto" then
        -- Solo el que reclamó puede usar Goto
        if IVOSAM_Tickets_Estado[ticketID] ~= ply:Nick() then return end
        if IsValid(ticket.creador) then
            ply:SetPos(ticket.creador:GetPos() + Vector(40, 40, 5))
            ply:ChatPrint("[IVOSAM] Teletransportado.")
        end
    
    elseif accion == "cerrar" then
        IVOSAM_Tickets[ticketID] = nil
        IVOSAM_Tickets_Estado[ticketID] = nil
        net.Start("IVOSAM_Ticket_Cerrado")
            net.WriteInt(ticketID, 16)
        net.Broadcast()
    end
end)