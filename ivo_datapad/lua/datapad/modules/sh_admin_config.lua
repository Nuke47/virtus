if not Datapad then return end

-- =========================================================================
-- [SERVIDOR] BACKEND DE ADMINISTRACIÓN
-- =========================================================================
if SERVER then
    util.AddNetworkString("Datapad_AdminAction")

    net.Receive("Datapad_AdminAction", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local action = net.ReadString()

        if     action == "clear_isb_messages" then
            sql.Query("DELETE FROM datapad_isb_messages")
            print("[Datapad] Mensajes ISB borrados por " .. ply:Nick())

        elseif action == "clear_isb_reports" then
            sql.Query("DELETE FROM datapad_isb_reports")
            print("[Datapad] Expedientes ISB borrados por " .. ply:Nick())

        elseif action == "clear_rt_reports" then
            sql.Query("DELETE FROM datapad_rt_reports")
            print("[Datapad] Informes RT borrados por " .. ply:Nick())

        elseif action == "clear_shock_arrests" then
            sql.Query("DELETE FROM datapad_shock_arrests")
            print("[Datapad] Arrestos Shock borrados por " .. ply:Nick())
        end

        -- Re-sincronizar datos vaciados
        local function Broadcast(netStr, tables)
            net.Start(netStr)
            for _, t in ipairs(tables) do net.WriteTable(t) end
            net.Broadcast()
        end

        if action == "clear_isb_messages" or action == "clear_isb_reports" then
            local reps = sql.Query("SELECT * FROM datapad_isb_reports ORDER BY id DESC LIMIT 50") or {}
            local msgs = sql.Query("SELECT * FROM datapad_isb_messages ORDER BY id DESC LIMIT 100") or {}
            net.Start("Datapad_SendISBData") net.WriteTable(reps) net.WriteTable(msgs) net.Broadcast()

        elseif action == "clear_rt_reports" then
            net.Start("Datapad_SendRTData") net.WriteTable({}) net.Broadcast()

        elseif action == "clear_shock_arrests" then
            net.Start("Datapad_SendShockData") net.WriteTable({}) net.Broadcast()
        end
    end)
end

-- =========================================================================
-- [CLIENTE] PANEL DE ADMINISTRACIÓN
-- =========================================================================
if CLIENT then
    -- Fuentes necesarias (reutilizamos prefijo Shock para no depender de módulos)
    surface.CreateFont("Admin_Title",  { font = "Roboto", size = 20, weight = 800, antialias = true })
    surface.CreateFont("Admin_Header", { font = "Roboto", size = 15, weight = 700, antialias = true })
    surface.CreateFont("Admin_Body",   { font = "Roboto", size = 13, weight = 500, antialias = true })

    local clrBg     = Color(10, 12, 18)
    local clrCardBg = Color(18, 22, 32)

    Datapad:RegisterModule("admin_config", {
        Name  = "Configuración",
        Icon  = "icon16/wrench.png",
        Order = 99,
        CanAccess = function(ply) return ply:IsSuperAdmin() end,

        UI = function(parent)
            local adminPanel = vgui.Create("DScrollPanel", parent)
            adminPanel:Dock(FILL)
            local sbar = adminPanel:GetVBar()
            if IsValid(sbar) then sbar:SetWide(4) sbar.Paint = function() end sbar.btnUp.Paint = function() end sbar.btnDown.Paint = function() end end
            adminPanel.Paint = function() end

            local title = adminPanel:Add("DLabel")
            title:SetText("GESTIÓN DE SISTEMAS — ACCESO RESTRINGIDO")
            title:SetFont("Admin_Title") title:SetTextColor(Color(200, 50, 50))
            title:Dock(TOP) title:DockMargin(20, 20, 20, 20)

            local function Section(label, color)
                local lbl = adminPanel:Add("DLabel")
                lbl:SetText("── " .. label .. " ──")
                lbl:SetFont("Admin_Header") lbl:SetTextColor(color)
                lbl:Dock(TOP) lbl:DockMargin(20, 15, 20, 5)
            end

            local function ActionBtn(text, btnColor, actionID)
                local btn = adminPanel:Add("DButton")
                btn:SetText(text) btn:SetFont("Admin_Header") btn:SetTextColor(color_white)
                btn:Dock(TOP) btn:SetTall(40) btn:DockMargin(20, 4, 20, 4)
                btn.Paint = function(s, w, h)
                    local c = s:IsHovered() and btnColor or Color(btnColor.r/4, btnColor.g/4, btnColor.b/4, 255)
                    draw.RoundedBox(6, 0, 0, w, h, c)
                    surface.SetDrawColor(btnColor) surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
                btn.DoClick = function()
                    Derma_Query(
                        "¿ESTÁS SEGURO? Los datos se eliminarán permanentemente de la base de datos.",
                        "⚠ CONFIRMACIÓN CRÍTICA",
                        "EJECUTAR BORRADO", function()
                            net.Start("Datapad_AdminAction") net.WriteString(actionID) net.SendToServer()
                        end,
                        "CANCELAR", function() end
                    )
                end
            end

            Section("MÓDULO ISB", Color(180, 30, 30))
            ActionBtn("PURGAR TODOS LOS CHATS ISB",       Color(180, 30, 30),  "clear_isb_messages")
            ActionBtn("PURGAR TODOS LOS EXPEDIENTES ISB", Color(180, 30, 30),  "clear_isb_reports")

            Section("MÓDULO RED TÁCTICA (RT)", Color(180, 180, 30))
            ActionBtn("PURGAR TODOS LOS INFORMES RT",     Color(180, 180, 30), "clear_rt_reports")

            Section("MÓDULO BASE DE DATOS 65th / SHOCK", Color(30, 120, 220))
            ActionBtn("PURGAR TODOS LOS ARRESTOS SHOCK",  Color(30, 120, 220), "clear_shock_arrests")

            local note = adminPanel:Add("DLabel")
            note:SetText("⚠  Los datos eliminados no se pueden recuperar.")
            note:SetFont("Admin_Body") note:SetTextColor(Color(160, 160, 160))
            note:Dock(TOP) note:DockMargin(20, 30, 20, 5)
        end
    })
end
