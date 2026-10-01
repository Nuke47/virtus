TOOL.Category = "Ivo Tools"
TOOL.Name = "No Target"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.ivonotarget.name", "No Target")
    language.Add("tool.ivonotarget.desc", "Aplica o remueve notarget.")
    language.Add("tool.ivonotarget.0", "Click Izquierdo: Darte notarget | Click Derecho: Quitarte notarget | Recargar: Alternar notarget al apuntado")
    language.Add("tool.ivonotarget.left", "Darte notarget")
    language.Add("tool.ivonotarget.right", "Quitarte notarget")
    language.Add("tool.ivonotarget.reload", "Alternar notarget al jugador apuntado")
end

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" }
}

function TOOL:LeftClick(trace)
    local ply = self:GetOwner()
    if SERVER and IsValid(ply) then
        if ply:IsFlagSet(FL_NOTARGET) then
            ply:ChatPrint("Ya tienes el notarget activado.")
        else
            ply:SetNoTarget(true)
            ply:ChatPrint("Te has ACTIVADO el notarget.")
        end
    end
    return true
end

function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    if SERVER and IsValid(ply) then
        if not ply:IsFlagSet(FL_NOTARGET) then
            ply:ChatPrint("No tienes el notarget activado.")
        else
            ply:SetNoTarget(false)
            ply:ChatPrint("Te has DESACTIVADO el notarget.")
        end
    end
    return true
end

function TOOL:Reload(trace)
    local ply = self:GetOwner()
    if not IsValid(ply) then return false end
    
    local ent = trace.Entity
    
    if IsValid(ent) and ent:IsPlayer() then
        if SERVER then
            if ent:IsFlagSet(FL_NOTARGET) then
                ent:SetNoTarget(false)
                ply:ChatPrint("Le has DESACTIVADO el notarget a " .. ent:Nick() .. ".")
                ent:ChatPrint(ply:Nick() .. " te ha DESACTIVADO el notarget.")
            else
                ent:SetNoTarget(true)
                ply:ChatPrint("Le has ACTIVADO el notarget a " .. ent:Nick() .. ".")
                ent:ChatPrint(ply:Nick() .. " te ha ACTIVADO el notarget.")
            end
        end
        return true
    elseif SERVER then
        -- Evitamos spamear el mensaje si se mantiene la R presionada
        if (self.NextReloadMsg or 0) < CurTime() then
            ply:ChatPrint("No estás apuntando a un jugador.")
            self.NextReloadMsg = CurTime() + 1
        end
    end
    return false
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", {Description = "Herramienta para gestionar el notarget. Usa los clicks para ti mismo y la recarga para apuntar a otros."})
end
