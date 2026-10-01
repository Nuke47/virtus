-- ==========================================================
-- IVOSAM: TICKETS SYSTEM - INTERACTIVE BUTTONS (SAM INTEGRATION)
-- ==========================================================
IVOSAM_Tickets_Reclamados = IVOSAM_Tickets_Reclamados or {}

local BotonesCreados = {}

local function EliminarBotonesTicket(id)
    if BotonesCreados[id] then
        if IsValid(BotonesCreados[id].btnClaim) then BotonesCreados[id].btnClaim:Remove() end
        if IsValid(BotonesCreados[id].btnGoto) then BotonesCreados[id].btnGoto:Remove() end
        if IsValid(BotonesCreados[id].btnBring) then BotonesCreados[id].btnBring:Remove() end
        if IsValid(BotonesCreados[id].btnReturn) then BotonesCreados[id].btnReturn:Remove() end
        BotonesCreados[id] = nil
    end
end

hook.Add("IVOSAM_Ticket_Expirado", "Menu_Limpieza_Botones", function(id)
    EliminarBotonesTicket(id)
end)

-- CORRECCIÓN: Esta función crea los botones UNA SOLA VEZ de forma segura
function IVOSAM_CrearBotonesTicketEstatico(ticket)
    local id = ticket.id
    local steamid = ticket.steamid

    -- 1. LIMPIEZA TOTAL: Antes de crear nada nuevo, eliminamos cualquier residuo previo.
    -- Esto soluciona el "bug" donde los botones viejos se quedan pegados.
    EliminarBotonesTicket(id)
    
    -- 2. Inicializamos la tabla para este ID
    BotonesCreados[id] = {}

    -- Función auxiliar para crear botones
    local function CrearBotonTactivo(texto, colorHover)
        local btn = vgui.Create("DButton")
        btn:SetText(texto)
        btn:SetFont("Ticket_Id")
        btn:SetTextColor(color_white)
        btn.Paint = function(self, w, h)
            local bg = self:IsHovered() and colorHover or Color(25, 25, 30)
            draw.RoundedBox(2, 0, 0, w, h, bg)
        end
        return btn
    end

    -- 3. Lógica de creación según estado
    if not IVOSAM_Tickets_Reclamados[id] then
        -- CREAR BOTÓN ATENDER
        local btnClaim = CrearBotonTactivo("ATENDER", Color(100, 100, 100))
        btnClaim.DoClick = function()
            net.Start("IVOSAM_Ticket_Accion")
                net.WriteString("claim")
                net.WriteInt(id, 16)
            net.SendToServer()
        end
        BotonesCreados[id].btnClaim = btnClaim
    else
        -- CREAR GOTO/BRING/RETURN solo si YO soy el dueño
        if IVOSAM_Tickets_Reclamados[id] == LocalPlayer():Nick() then
            BotonesCreados[id].btnGoto = CrearBotonTactivo("GOTO", Color(0, 120, 255))
            BotonesCreados[id].btnGoto.DoClick = function() 
                LocalPlayer():ConCommand('sam_goto "' .. steamid .. '"') 
            end
            
            BotonesCreados[id].btnBring = CrearBotonTactivo("BRING", Color(0, 180, 100))
            BotonesCreados[id].btnBring.DoClick = function() 
                LocalPlayer():ConCommand('sam_bring "' .. steamid .. '"') 
            end

            BotonesCreados[id].btnReturn = CrearBotonTactivo("RETURN", Color(200, 60, 60))
            BotonesCreados[id].btnReturn.DoClick = function() 
                LocalPlayer():ConCommand('sam_return "' .. steamid .. '"') 
            end
        end
    end
end

-- El Think ahora SOLO cambia la posición de los botones existentes, consume 0 recursos
hook.Add("Think", "IVOSAM_Mapear_Botones_Tickets", function()
    -- Variables constantes para los botones
    local btnW, btnH = 84, 16

    for _, ticket in ipairs(IVOSAM_Tickets_Visibles or {}) do
        local id = ticket.id
        -- Si no existen botones para este ID, saltamos
        if not BotonesCreados[id] then continue end
        if not ticket.lastRenderX then continue end

        local x, y, h = ticket.lastRenderX, ticket.lastRenderY, ticket.lastRenderH
        local isClaimed = (IVOSAM_Tickets_Reclamados[id] ~= nil)

        if not isClaimed then
            -- Lógica para el botón ATENDER
            if IsValid(BotonesCreados[id].btnClaim) then
                BotonesCreados[id].btnClaim:SetPos(x + 12, y + h - 22)
                BotonesCreados[id].btnClaim:SetSize(256, 16)
                BotonesCreados[id].btnClaim:SetVisible(true)
            end
        else
            -- Lógica para botones de ADMIN (Ocultamos btnClaim por seguridad)
            if IsValid(BotonesCreados[id].btnClaim) then BotonesCreados[id].btnClaim:SetVisible(false) end

            if IsValid(BotonesCreados[id].btnGoto) then
                BotonesCreados[id].btnGoto:SetPos(x + 12, y + h - 22)
                BotonesCreados[id].btnGoto:SetSize(btnW, btnH)
            end

            if IsValid(BotonesCreados[id].btnBring) then
                BotonesCreados[id].btnBring:SetPos(x + 12 + btnW + 4, y + h - 22)
                BotonesCreados[id].btnBring:SetSize(btnW, btnH)
            end

            if IsValid(BotonesCreados[id].btnReturn) then
                BotonesCreados[id].btnReturn:SetPos(x + 12 + (btnW * 2) + 8, y + h - 22)
                BotonesCreados[id].btnReturn:SetSize(btnW, btnH)
            end
        end
    end
end)

net.Receive("IVOSAM_Ticket_Notificar_Claim", function()
    local id = net.ReadInt(16)
    local nombreAdmin = net.ReadString()
    
    IVOSAM_Tickets_Reclamados[id] = nombreAdmin
    
    -- PASO CRÍTICO: Eliminamos los botones anteriores (el de "ATENDER")
    EliminarBotonesTicket(id)
    
    -- Buscamos el ticket en la lista para pasárselo de nuevo a la función de creación
    for _, ticket in ipairs(IVOSAM_Tickets_Visibles) do
        if ticket.id == id then
            IVOSAM_CrearBotonesTicketEstatico(ticket) -- Esto crea los botones de GOTO/BRING
            break
        end
    end
    
    surface.PlaySound("buttons/button14.wav")
end)

-- También necesitamos manejar el cierre del ticket para limpiar la memoria
net.Receive("IVOSAM_Ticket_Cerrado", function()
    local id = net.ReadInt(16)
    
    IVOSAM_Tickets_Reclamados[id] = nil
    EliminarBotonesTicket(id)
    
    -- Eliminamos el ticket de la tabla de visibles si existe
    for k, v in ipairs(IVOSAM_Tickets_Visibles) do
        if v.id == id then
            table.remove(IVOSAM_Tickets_Visibles, k)
            break
        end
    end
end)