if not Datapad then return end

if CLIENT then
    Datapad:RegisterModule("slicing_db", {
        Name  = "Robo de Datos",
        Icon  = "icon16/database_key.png",
        Order = 80,
        CanAccess = function(ply)
            return Datapad:HasAccess(ply, Datapad.Config.BountyHunters or {})
        end,

        UI = function(parent)
            local panel = vgui.Create("DPanel", parent)
            panel:Dock(FILL)
            panel.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(20, 10, 10))
            end

            local title = vgui.Create("DLabel", panel)
            title:SetText("SISTEMA DE INFILTRACIÓN DE DATOS")
            title:SetFont("Datapad_Title")
            title:SetTextColor(Color(255, 100, 50))
            title:Dock(TOP)
            title:DockMargin(20, 20, 20, 10)

            local desc = vgui.Create("DLabel", panel)
            desc:SetText("Selecciona una base de datos para intentar extraer créditos e información. Fallar revelará tu posición a las autoridades.")
            desc:SetFont("Datapad_Text")
            desc:SetTextColor(Color(200, 150, 150))
            desc:Dock(TOP)
            desc:DockMargin(20, 0, 20, 30)
            desc:SetWrap(true)
            desc:SetTall(40)

            local function CreateHackButton(text, color)
                local btn = vgui.Create("DButton", panel)
                btn:SetText(text)
                btn:SetFont("Datapad_Title")
                btn:SetTextColor(color_white)
                btn:Dock(TOP)
                btn:SetTall(50)
                btn:DockMargin(20, 10, 20, 10)
                btn.Paint = function(self, w, h)
                    local bg = self:IsHovered() and color or Color(color.r/3, color.g/3, color.b/3)
                    draw.RoundedBox(4, 0, 0, w, h, bg)
                    surface.SetDrawColor(color)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                end
                btn.DoClick = function()
                    if DATAPAD_FRAME then DATAPAD_FRAME:Close() end
                    if Datapad_StartMinigame then
                        Datapad_StartMinigame("database", nil)
                    end
                end
            end

            CreateHackButton("INFILTRAR BASE DE DATOS ISB", Color(180, 40, 40))
            CreateHackButton("INFILTRAR SERVIDOR SHOCK (65TH)", Color(200, 100, 20))
        end
    })
end
