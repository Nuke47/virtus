if not ATTACHMENT then
	ATTACHMENT = {}
end

ATTACHMENT.Name = "Linterna Táctica"
ATTACHMENT.ShortName = "Linterna"
ATTACHMENT.Description = { 
	TFA.AttachmentColors["="], "Ilumina zonas oscuras",
	TFA.AttachmentColors["-"], "Revela tu posición"
}
ATTACHMENT.Icon = "entities/atts/linterna.png" -- Recuerda poner un ícono o usa uno existente

-- Aquí es donde ocurre la magia visual y lógica
ATTACHMENT.WeaponTable = {
    -- 1. Le decimos a TFA que el arma ahora puede usar la linterna (tecla F por defecto)
	["HasFlashlight"] = true, 

    -- 2. VElements = Cómo se ve el arma en PRIMERA PERSONA (en tus manos)
	["VElements"] = {
		["linterna_visual"] = {
			type = "Model", 
			model = "models/sw_battlefront/props/flashlight/flashlight.mdl", 
			bone = "ValveBiped.Bip01_R_Hand", -- MUY IMPORTANTE: Leer abajo sobre los huesos
			pos = Vector(0, 0, 0), -- Posición (Adelante/Atrás, Izquierda/Derecha, Arriba/Abajo)
			angle = Angle(0, 0, 0), -- Rotación
			size = Vector(1, 1, 1), 
			active = true -- Se activa automáticamente al equipar
		}
	},
    
    -- 3. WElements = Cómo ven el arma los DEMÁS JUGADORES (en tercera persona)
    ["WElements"] = {
		["linterna_visual_tp"] = {
			type = "Model", 
			model = "models/sw_battlefront/props/flashlight/flashlight.mdl", 
			bone = "ValveBiped.Bip01_R_Hand", 
			pos = Vector(0, 0, 0), 
			angle = Angle(0, 0, 0), 
			size = Vector(1, 1, 1), 
			active = true
		}
	}
}

if not TFA_ATTACHMENT_ISUPDATING then
	TFAUpdateAttachments()
end
