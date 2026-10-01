-- Tabla global absoluta para evitar bugs de variables locales al recargar el código
MeditationUI_State = MeditationUI_State or {}
MeditationUI_State.HoveredNode = nil
MeditationUI_State.SelectedNode = nil
MeditationUI_State.Phase = 0
MeditationUI_State.State = 0
MeditationUI_State.UnlockTargetNode = nil
MeditationUI_State.UnlockProgress = 0

local isMeditating = false
local meditationCenter = Vector(0,0,0)
local meditationAngle = Angle(0,0,0)
local meditationForward = Vector(1,0,0)
local meditationRight = Vector(0,-1,0)
local meditationUp = Vector(0,0,1)

local mouseDownDebounce = false
local menuPanel = nil

surface.CreateFont("MeditationNodeTitle", { font = "Roboto", size = 72, weight = 800, antialias = true })
surface.CreateFont("MeditationNodeDesc", { font = "Roboto", size = 40, weight = 400, antialias = true })
surface.CreateFont("MeditationNodeCost", { font = "Roboto", size = 48, weight = 800, antialias = true })
surface.CreateFont("MeditationButton", { font = "Roboto", size = 24, weight = 400, antialias = true })
surface.CreateFont("MeditationMenuBig", { font = "Roboto", size = 32, weight = 600, antialias = true, shadow = true })

local matDarkSphere = CreateMaterial("MeditationDarkSphere", "VertexLitGeneric", { ["$basetexture"] = "color/white", ["$model"] = 1, ["$color2"] = "[0.05 0.05 0.1]" })
local matBrightSphere = CreateMaterial("MeditationBrightSphere", "UnlitGeneric", { ["$basetexture"] = "color/white", ["$model"] = 1 })

local TreeNodes = {
	-- ==============================================
	-- RAMA 1: POSTURAS (Izquierda Lejana)
	-- ==============================================
	["untrained"] = { type = "stance", pos = Vector(80, -200, 2), parents = {} },
	["juggernaut"] = { type = "stance", pos = Vector(180, -250, 2), parents = {"untrained"} },
	["yongli"] = { type = "stance", pos = Vector(280, -300, 2), parents = {"juggernaut"} },
	["butterfly"] = { type = "stance", pos = Vector(380, -350, 2), parents = {"yongli"} },
	
	-- ==============================================
	-- RAMA 2: LADO OSCURO / CONTROL (Centro Izquierdo)
	-- ==============================================
	["choke"] = { type = "force", pos = Vector(80, -100, 2), parents = {} },
	
	["drain"] = { type = "force", pos = Vector(180, -180, 2), parents = {"choke"} },
	["rage"] = { type = "force", pos = Vector(280, -220, 2), parents = {"drain"} },
	["quake"] = { type = "force", pos = Vector(380, -220, 2), parents = {"rage"} },
	
	["stasis"] = { type = "force", pos = Vector(180, -120, 2), parents = {"choke"} },
	["zerog"] = { type = "force", pos = Vector(280, -160, 2), parents = {"stasis"} },
	["blind"] = { type = "force", pos = Vector(280, -120, 2), parents = {"stasis"} },
	
	["ignite"] = { type = "force", pos = Vector(180, -60, 2), parents = {"choke"} },
	["scream"] = { type = "force", pos = Vector(280, -60, 2), parents = {"ignite"} },
	["lightning"] = { type = "force", pos = Vector(380, -80, 2), parents = {"scream"} },
	
	-- ==============================================
	-- RAMA 3: TELEKINESIS (Centro)
	-- ==============================================
	["push"] = { type = "force", pos = Vector(80, 0, 2), parents = {} },
	
	["repulse"] = { type = "force", pos = Vector(180, 40, 2), parents = {"push"} },
	["destruction"] = { type = "force", pos = Vector(280, 40, 2), parents = {"repulse"} },
	
	["pull"] = { type = "force", pos = Vector(180, 0, 2), parents = {"push"} },
	["throw"] = { type = "force", pos = Vector(280, 0, 2), parents = {"pull"} },
	["seismicthrow"] = { type = "force", pos = Vector(380, -30, 2), parents = {"throw"} },
	["grip"] = { type = "force", pos = Vector(380, 30, 2), parents = {"throw"} },
	
	-- ==============================================
	-- RAMA 4: LADO LUMINOSO / DEFENSA (Centro Derecho)
	-- ==============================================
	["jump"] = { type = "force", pos = Vector(80, 100, 2), parents = {} },
	
	["speed"] = { type = "force", pos = Vector(180, 180, 2), parents = {"jump"} },
	["blink"] = { type = "force", pos = Vector(280, 220, 2), parents = {"speed"} },
	["cloak"] = { type = "force", pos = Vector(380, 260, 2), parents = {"blink"} },
	
	["sense"] = { type = "force", pos = Vector(180, 120, 2), parents = {"jump"} },
	
	["heal"] = { type = "force", pos = Vector(280, 120, 2), parents = {"sense"} },
	["auraheal"] = { type = "force", pos = Vector(380, 160, 2), parents = {"heal"} },
	["meditation"] = { type = "force", pos = Vector(380, 100, 2), parents = {"heal"} },
	
	["barrier"] = { type = "force", pos = Vector(180, 80, 2), parents = {"jump"} },
	["deflect"] = { type = "force", pos = Vector(280, 80, 2), parents = {"barrier"} },
	["immunity"] = { type = "force", pos = Vector(380, 60, 2), parents = {"deflect"} },
}

local function GetLSCSNodeData(id, type)
	if not LSCS then return {} end -- Seguro anti-crashes si LSCS no cargó aún
	if type == "stance" then
		return LSCS.Stance and LSCS.Stance[id] or {}
	else
		return LSCS.Force and LSCS.Force[id] or {}
	end
end

local function GetNodeWorldPos(node)
	return meditationCenter + (meditationForward * node.pos.x) + (meditationRight * node.pos.y) + (meditationUp * node.pos.z)
end

local function GetUnlockPath(ply, targetNodeId)
	local unl = {}
	if type(ply.lscsGetUnlockedSkills) == "function" then
		unl = ply:lscsGetUnlockedSkills()
		if type(unl) ~= "table" then unl = {} end
	end

	local function isUnlocked(id)
		if not TreeNodes[id] then return false end
		local oldF = "lscs_" .. TreeNodes[id].type .. "_" .. id
		return table.HasValue(unl, id) or table.HasValue(unl, oldF)
	end

	if isUnlocked(targetNodeId) then return 0, {} end

	local bestCost = math.huge
	local bestPath = nil
	
	local function search(id, currentCost, currentPath, visited)
		if visited[id] then return end
		visited[id] = true
		
		local newPath = table.Copy(currentPath)
		table.insert(newPath, 1, id)
		local newCost = currentCost + 1
		
		local node = TreeNodes[id]
		if not node then return end
		
		if not node.parents or #node.parents == 0 then
			if newCost < bestCost then
				bestCost = newCost
				bestPath = newPath
			end
		else
			local parentUnlocked = false
			for _, pid in ipairs(node.parents) do
				if isUnlocked(pid) then
					parentUnlocked = true
					if newCost < bestCost then
						bestCost = newCost
						bestPath = newPath
					end
				end
			end
			if not parentUnlocked then
				for _, pid in ipairs(node.parents) do
					search(pid, newCost, newPath, table.Copy(visited))
				end
			end
		end
	end
	
	search(targetNodeId, 0, {}, {})
	return bestCost == math.huge and 0 or bestCost, bestPath or {}
end

-- Helper for 3D progress circle
local function DrawArc(cx, cy, radius, thickness, start_ang, end_ang, segments, color)
	surface.SetDrawColor(color)
	draw.NoTexture()
	
	local outer = {}
	local inner = {}
	
	start_ang = math.rad(start_ang)
	end_ang = math.rad(end_ang)
	
	local step = (end_ang - start_ang) / segments
	
	for i = 0, segments do
		local a = start_ang + step * i
		local sin, cos = math.sin(a), math.cos(a)
		
		table.insert(outer, { x = cx + cos * radius, y = cy + sin * radius, u = 0, v = 0 })
		table.insert(inner, { x = cx + cos * (radius - thickness), y = cy + sin * (radius - thickness), u = 0, v = 0 })
	end
	
	for i = 1, #outer - 1 do
		surface.DrawPoly({ outer[i], outer[i+1], inner[i+1], inner[i] })
	end
end

local stars = {}
for i = 1, 300 do
	local dir = VectorRand()
	dir.z = math.abs(dir.z) * 0.5 
	dir:Normalize()
	table.insert(stars, { dir = dir, size = math.random(5, 15), offset = math.random(1, 100) })
end

local forceMotes = {}
for i = 1, 150 do
	table.insert(forceMotes, {
		x = math.random(-800, 800),
		y = math.random(-800, 800),
		z = math.random(-200, 800),
		speed = math.random(15, 40),
		phase = math.random(0, 360)
	})
end

-- Floating rocks cleanup and generation
if LSCS_FLOAT_ROCKS then
	for _, r in ipairs(LSCS_FLOAT_ROCKS) do
		if IsValid(r.ent) then r.ent:Remove() end
	end
end
LSCS_FLOAT_ROCKS = {}
local rockModels = {
	"models/props_debris/concrete_chunk01a.mdl",
	"models/props_debris/concrete_chunk02a.mdl",
	"models/props_debris/concrete_chunk01b.mdl",
	"models/props_wasteland/rockgranite03b.mdl"
}
for i = 1, 25 do
	local mdl = rockModels[math.random(#rockModels)]
	local ent = ClientsideModel(mdl, RENDERGROUP_OPAQUE)
	if IsValid(ent) then
		ent:SetNoDraw(true)
		table.insert(LSCS_FLOAT_ROCKS, {
			ent = ent,
			basePos = Vector(math.random(-1500, 1500), math.random(-1500, 1500), math.random(-200, 800)),
			ang = Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
			rotSpeed = Angle(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10)) * 0.01, -- Much slower
			floatSpeed = math.random(2, 6) * 0.1, -- Slower levitation
			phase = math.random(0, 360)
		})
	end
end

LSCS_SHOCKWAVES = LSCS_SHOCKWAVES or {}

local OpenMeditationMainMenu
local CloseMeditationUI

function CloseMeditationUI()
	if IsValid(menuPanel) then
		menuPanel:Remove()
		menuPanel = nil
	end
end

function OpenMeditationMainMenu()
	if IsValid(menuPanel) then menuPanel:Remove() end
	
	-- Limpiar paneles fantasmas
	for _, pnl in pairs(vgui.GetWorldPanel():GetChildren()) do
		if pnl:GetName() == "DPanel" and pnl:GetWide() == ScrW() and pnl:GetTall() == ScrH() then
			pnl:Remove()
		end
	end
	
	-- Panel base transparente
	menuPanel = vgui.Create("DPanel")
	menuPanel:SetSize(ScrW(), ScrH())
	menuPanel:SetPos(0, 0)
	menuPanel:SetZPos(100)
	menuPanel.Paint = function() end -- Completamente transparente
	
	-- =======================================================
	-- NUEVO: PANEL HUD DEDICADO A LA INFO DEL NODO
	-- =======================================================
	local infoBox = vgui.Create("DPanel", menuPanel)
	infoBox:SetSize(600, 320)
	infoBox:SetPos(40, 40)
	infoBox.Paint = function(self, w, h)
		if MeditationUI_State.State ~= 2 then return end
		
		local activeNode = MeditationUI_State.HoveredNode or MeditationUI_State.SelectedNode
		if not activeNode then return end
		
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		local node = TreeNodes[activeNode]
		local lscsData = GetLSCSNodeData(activeNode, node.type)
		
		local title = string.upper(tostring(lscsData.PrintName or activeNode))
		local desc = tostring(lscsData.Description or "Sin descripción.")
		
		local isUnlocked = false
		if ply.lscsGetUnlockedSkills then
			local unlocked = ply:lscsGetUnlockedSkills()
			if type(unlocked) == "table" then
				local oldFormat = "lscs_" .. node.type .. "_" .. activeNode
				isUnlocked = table.HasValue(unlocked, activeNode) or table.HasValue(unlocked, oldFormat)
			end
		end
		
		-- ====================================================================
		-- JEDI FALLEN ORDER STYLE HUD
		-- ====================================================================
		
		-- Título de la habilidad (Grande, fuente limpia)
		draw.SimpleText(title, "MeditationNodeTitle", 40, 40, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		-- Línea separadora naranja/dorada (muy fina y elegante)
		surface.SetDrawColor(220, 150, 50, 255)
		surface.DrawRect(40, 110, 400, 2)
		
		-- Costo (Naranja, debajo de la línea)
		if isUnlocked then
			draw.SimpleText("DESBLOQUEADO", "MeditationNodeCost", 40, 125, Color(100, 255, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		else
			draw.SimpleText("1 PUNTO DE HABILIDAD", "MeditationNodeCost", 40, 125, Color(220, 150, 50, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		
		-- Descripción (Blanco, texto normal, más abajo)
		-- Para que el texto largo se adapte, usamos DrawText que soporta saltos de línea (\n)
		local wrappedDesc = string.gsub(desc, "(.{1,50})(%s+)", "%1\n")
		draw.DrawText(desc, "MeditationButton", 40, 160, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT)
		
		-- Mensaje de ayuda si no está desbloqueado
		if not isUnlocked then
			local cost, path = GetUnlockPath(ply, activeNode)
			local sp = tonumber(ply.lscsGetSkillPoints and ply:lscsGetSkillPoints() or 0) or 0
			
			if #path > 0 then
				if sp >= cost then
					if cost == 1 then
						draw.SimpleText("Mantén el clic sobre el nodo para aprender", "MeditationButton", 40, 280, Color(150, 255, 150, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					else
						draw.SimpleText("Aprender cadena (" .. cost .. " habilidades x " .. cost .. " ptos)", "MeditationButton", 40, 280, Color(150, 200, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					end
				else
					draw.SimpleText("FALTAN PUNTOS (Requiere " .. cost .. ")", "MeditationNodeCost", 40, 280, Color(255, 80, 80, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			else
				draw.SimpleText("RUTA INVÁLIDA", "MeditationNodeCost", 40, 280, Color(255, 80, 80, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
		end
	end

	-- =======================================================
	-- NUEVO: PANEL HUD DEDICADO A LA BARRA DE XP
	-- =======================================================
	local xpBox = vgui.Create("DPanel", menuPanel)
	xpBox:SetSize(800, 200)
	xpBox:SetPos((ScrW() - 800) / 2, ScrH() - 200)
	xpBox.Paint = function(self, w, h)
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		local sp = tonumber(ply.lscsGetSkillPoints and ply:lscsGetSkillPoints() or 0) or 0
		local xp = tonumber(ply.lscsGetXP and ply:lscsGetXP() or 0) or 0
		local lvl = tonumber(ply.lscsGetLevel and ply:lscsGetLevel() or 1) or 1
		
		local requiredXP = math.max(1, lvl * 1000)
		local fraction = math.Clamp(xp / requiredXP, 0, 1)
		if fraction ~= fraction then fraction = 0 end
		
		local barW, barH = 400, 6
		local barX, barY = (w - barW) / 2, 60
		
		draw.RoundedBox(0, barX, barY, barW, barH, Color(50, 50, 50, 200))
		draw.RoundedBox(0, barX, barY, barW * fraction, barH, Color(200, 150, 50, 255))
		
		draw.SimpleText(tostring(sp), "MeditationNodeTitle", w / 2, barY - 60, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText("PUNTOS DE HABILIDAD", "MeditationNodeDesc", w / 2, barY + 20, Color(150, 150, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		
		draw.SimpleText("NIVEL " .. tostring(lvl), "MeditationButton", barX - 20, barY - 12, Color(200, 200, 200, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText(tostring(math.floor(fraction * 100)) .. "%", "MeditationButton", barX + barW + 20, barY - 12, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	menuPanel:MakePopup()
	menuPanel:SetKeyboardInputEnabled(false)
	
	local cx = ScrW() / 2
	local cy = ScrH() / 2 - 180
	
	local function CreateFallenOrderButton(txt, x, y, w, h, onClick)
		local btn = vgui.Create("DButton", menuPanel)
		btn:SetSize(w, h)
		btn:SetPos(x - w/2, y - h/2)
		btn:SetText("")
		btn.DoClick = onClick
		
		btn.Paint = function(self, w, h)
			local hover = self:IsHovered()
			local textColor = hover and Color(255, 255, 255, 255) or Color(150, 160, 170, 200)
			
			draw.SimpleText(txt, "MeditationMenuBig", w/2, h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			if hover then
				surface.SetFont("MeditationMenuBig")
				local tw, th = surface.GetTextSize(txt)
				
				-- Diamantes decorativos a los lados estilo Fallen Order
				draw.SimpleText("♦", "MeditationMenuBig", w/2 - tw/2 - 20, h/2, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("♦", "MeditationMenuBig", w/2 + tw/2 + 20, h/2, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		return btn
	end
	
	local btnTree = nil
	local btnRest = nil
	local btnExit = nil

	btnRest = CreateFallenOrderButton("DESCANSAR", cx - 250, cy, 300, 50, function()
		surface.PlaySound("buttons/blip1.wav")
		net.Start("Meditation_Action_Rest")
		net.SendToServer()
	end)
	
	btnExit = CreateFallenOrderButton("SALIR", cx + 250, cy, 300, 50, function()
		surface.PlaySound("buttons/lightswitch2.wav")
		net.Start("Meditation_Action_Exit")
		net.SendToServer()
	end)

	btnTree = CreateFallenOrderButton("ÁRBOL DE HABILIDADES", cx, cy + 60, 400, 50, function()
		surface.PlaySound("buttons/button14.wav")
		MeditationUI_State.State = 2
		btnTree:SetVisible(false)
		btnRest:SetVisible(false)
		btnExit:SetVisible(false)
		
		local btnBack = nil
		local btnReset = nil
		
		btnBack = CreateFallenOrderButton("VOLVER", cx - 110, ScrH() - 60, 200, 36, function()
			surface.PlaySound("buttons/button15.wav")
			MeditationUI_State.State = 1
			btnTree:SetVisible(true)
			btnRest:SetVisible(true)
			btnExit:SetVisible(true)
			if IsValid(btnBack) then btnBack:Remove() end
			if IsValid(btnReset) then btnReset:Remove() end
		end)
		
		btnReset = CreateFallenOrderButton("REINICIAR ÁRBOL", cx + 110, ScrH() - 60, 200, 36, function()
			Derma_Query(
				"¿Estás seguro de que quieres resetear tu árbol de habilidades?",
				"Confirmar Reseteo",
				"Sí, resetear",
				function()
					net.Start("lscs_reset_skills")
					net.SendToServer()
					surface.PlaySound("buttons/button14.wav")
					MeditationUI_State.State = 1
					btnTree:SetVisible(true)
					btnRest:SetVisible(true)
					btnExit:SetVisible(true)
					if IsValid(btnBack) then btnBack:Remove() end
					if IsValid(btnReset) then btnReset:Remove() end
				end,
				"Cancelar",
				function() end
			)
		end)
	end)
end

local currentCamPos = Vector(0,0,0)
local currentCamAng = Angle(0,0,0)
local firstFrame = true

hook.Add("Think", "Meditation_CheckState", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local newPhase = ply:GetNWInt("MeditationPhase", 0)
	if newPhase ~= MeditationUI_State.Phase then
		MeditationUI_State.Phase = newPhase
		isMeditating = (MeditationUI_State.Phase > 0)
		
		if MeditationUI_State.Phase == 1 then
			firstFrame = true
			meditationCenter = ply:GetPos()
			meditationAngle = Angle(0, ply:EyeAngles().y, 0)
			meditationForward = meditationAngle:Forward()
			meditationRight = meditationAngle:Right()
			meditationUp = meditationAngle:Up()
			
			currentCamPos = ply:EyePos()
			currentCamAng = ply:EyeAngles()
			
			gui.EnableScreenClicker(false)
		elseif MeditationUI_State.Phase == 2 then
			MeditationUI_State.State = 1
			gui.EnableScreenClicker(true)
			OpenMeditationMainMenu()
		elseif MeditationUI_State.Phase == 3 or MeditationUI_State.Phase == 0 then
			MeditationUI_State.State = 0
			gui.EnableScreenClicker(false)
			CloseMeditationUI()
		end
	end
	
	if MeditationUI_State.Phase == 2 and MeditationUI_State.State == 2 then
		local aimOrigin = currentCamPos
		local aimDir = gui.ScreenToVector(gui.MouseX(), gui.MouseY())
		
		if aimDir then
			MeditationUI_State.HoveredNode = nil
			local closestDist = math.huge
			
			for id, node in pairs(TreeNodes) do
				local nodeWorldPos = GetNodeWorldPos(node)
				local t = util.IntersectRayWithSphere(aimOrigin, aimDir, nodeWorldPos, 30)
				if t then
					local dist = aimOrigin:Distance(nodeWorldPos)
					if dist < closestDist then
						closestDist = dist
						MeditationUI_State.HoveredNode = id
					end
				end
			end
		end
		
		local isDown = input.IsMouseDown(MOUSE_LEFT)
		if isDown then
			if MeditationUI_State.HoveredNode then
				MeditationUI_State.SelectedNode = MeditationUI_State.HoveredNode
				local node = TreeNodes[MeditationUI_State.HoveredNode]
				
				local isUnlocked = false
				if ply.lscsGetUnlockedSkills then
					local unlocked = ply:lscsGetUnlockedSkills()
					if type(unlocked) == "table" then
						local oldFormat = "lscs_" .. node.type .. "_" .. MeditationUI_State.HoveredNode
						isUnlocked = table.HasValue(unlocked, MeditationUI_State.HoveredNode) or table.HasValue(unlocked, oldFormat)
					end
				end
				
				if not isUnlocked then
					local cost, path = GetUnlockPath(ply, MeditationUI_State.HoveredNode)
					local sp = tonumber(ply.lscsGetSkillPoints and ply:lscsGetSkillPoints() or 0) or 0
					
					if #path > 0 and sp >= cost then
						if MeditationUI_State.UnlockTargetNode ~= MeditationUI_State.HoveredNode then
							MeditationUI_State.UnlockTargetNode = MeditationUI_State.HoveredNode
							MeditationUI_State.UnlockProgress = 0
						end
						
						MeditationUI_State.UnlockProgress = math.Clamp(MeditationUI_State.UnlockProgress + FrameTime(), 0, 1.5)
						
						if MeditationUI_State.UnlockProgress >= 1.5 then
							for _, idToUnlock in ipairs(path) do
								local n = TreeNodes[idToUnlock]
								if n then
									net.Start("lscs_unlock_skill")
									net.WriteString(idToUnlock)
									net.WriteString(n.type)
									net.SendToServer()
								end
							end
							
							surface.PlaySound("buttons/blip1.wav")
							util.ScreenShake(Vector(0,0,0), 5, 5, 0.5, 5000)
							local nodePos = GetNodeWorldPos(node)
							if nodePos then
								table.insert(LSCS_SHOCKWAVES, { pos = nodePos, startTime = CurTime() })
							end
							
							MeditationUI_State.UnlockProgress = 0
							MeditationUI_State.UnlockTargetNode = nil
						end
					else
						MeditationUI_State.UnlockProgress = 0
					end
				else
					MeditationUI_State.UnlockProgress = 0
				end
			else
				if not mouseDownDebounce then
					MeditationUI_State.SelectedNode = nil
				end
				MeditationUI_State.UnlockProgress = 0
			end
			mouseDownDebounce = true
		else
			mouseDownDebounce = false
			MeditationUI_State.UnlockProgress = 0
			MeditationUI_State.UnlockTargetNode = nil
		end
	end
end)

local matGlow = Material("sprites/glow04_noz")
local matRing = Material("particle/particle_ring_wave_additive")
local matBeam = Material("trails/laser")

hook.Add("CalcView", "Meditation_Camera", function(ply, pos, angles, fov)
	if MeditationUI_State.Phase == 0 then return end
	
	local targetPos, targetAng
	
	if MeditationUI_State.Phase == 1 then
		targetAng = Angle(15, meditationAngle.y, 0)
		targetPos = meditationCenter + Vector(0, 0, 50) - (meditationForward * 80)
	elseif MeditationUI_State.Phase == 2 then
		if MeditationUI_State.State == 1 then
			targetAng = Angle(15, meditationAngle.y, 0)
			targetPos = meditationCenter + Vector(0, 0, 50) - (meditationForward * 80)
		else
			targetAng = Angle(55, meditationAngle.y, 0)
			targetPos = meditationCenter + Vector(0, 0, 180) - (meditationForward * 40)
		end
	elseif MeditationUI_State.Phase == 3 then
		targetAng = Angle(15, meditationAngle.y, 0)
		targetPos = meditationCenter + Vector(0, 0, 50) - (meditationForward * 80)
	end
	
	if firstFrame then
		firstFrame = false
	else
		currentCamPos = LerpVector(RealFrameTime() * 4, currentCamPos, targetPos)
		currentCamAng = LerpAngle(RealFrameTime() * 4, currentCamAng, targetAng)
	end
	
	return { origin = currentCamPos, angles = currentCamAng, fov = fov, drawviewer = false }
end)

hook.Add("RenderScene", "Meditation_Void", function(origin, angles, fov)
	if MeditationUI_State.Phase ~= 2 then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local ct = CurTime()
	
	render.Clear(12, 14, 18, 255, true, true)
	
	cam.Start3D(origin, angles, fov)
		local matFog = Material("particle/particle_smokegrenade")
		
		render.SetMaterial(matGlow)
		for _, s in ipairs(stars) do
			local p = meditationCenter + s.dir * 2000
			local alpha = 10 + math.sin(ct * 2 + s.offset) * 30
			render.DrawSprite(p, s.size * 4, s.size * 4, Color(150, 160, 180, alpha))
		end
		
		-- Cosmic Fog (Nebulas)
		render.SetMaterial(matFog)
		for i=1, 12 do
			local ang = ct * 0.015 * (i%2==0 and 1 or -1) -- Slower rotation
			local fogPos = meditationCenter + Vector(math.sin(i*7 + ang)*1800, math.cos(i*3 + ang)*1800, -300 + math.sin(i*5)*1000)
			local col = (i%2 == 0) and Color(15, 25, 60, 15) or Color(35, 15, 65, 12)
			render.DrawSprite(fogPos, 6000, 6000, col)
		end
		
		-- Floor Fog (Dense mist near the player)
		for i=1, 10 do
			local ang = ct * 0.03 + (i * 36) -- Slower rotation
			local fogPos = meditationCenter + Vector(math.sin(ang)*400, math.cos(ang)*400, -20 + math.sin(ct*0.2 + i)*20) -- Slower bob
			render.DrawSprite(fogPos, 2000, 2000, Color(40, 60, 100, 15))
		end
		
		-- Floating Rocks
		for _, r in ipairs(LSCS_FLOAT_ROCKS) do
			if IsValid(r.ent) then
				r.ang = r.ang + r.rotSpeed
				local floatOffset = math.sin(ct * r.floatSpeed + r.phase) * 30
				local rockPos = meditationCenter + r.basePos + Vector(0, 0, floatOffset)
				
				r.ent:SetPos(rockPos)
				r.ent:SetAngles(r.ang)
				
				-- Draw the rock with a dark, blueish ambient lighting to match the void
				render.SuppressEngineLighting(true)
				render.SetModelLighting(BOX_FRONT, 0.2, 0.3, 0.5)
				render.SetModelLighting(BOX_TOP, 0.1, 0.2, 0.4)
				render.SetModelLighting(BOX_BOTTOM, 0, 0, 0)
				render.SetModelLighting(BOX_LEFT, 0.1, 0.1, 0.2)
				render.SetModelLighting(BOX_RIGHT, 0.1, 0.1, 0.2)
				render.SetModelLighting(BOX_BACK, 0.1, 0.1, 0.2)
				
				r.ent:DrawModel()
				
				render.SuppressEngineLighting(false)
			end
		end
		
		-- Force Motes (Fireflies)
		render.SetMaterial(matGlow)
		for _, m in ipairs(forceMotes) do
			m.z = m.z + m.speed * FrameTime()
			if m.z > 800 then m.z = -200 end
			local xOffset = math.sin(ct * 0.5 + m.phase) * 30
			local yOffset = math.cos(ct * 0.5 + m.phase) * 30
			local p = meditationCenter + Vector(m.x + xOffset, m.y + yOffset, m.z)
			
			local distToCam = origin:Distance(p)
			local alpha = math.Clamp(255 - (distToCam * 0.2), 0, 150)
			
			render.DrawSprite(p, 4, 4, Color(150, 200, 255, alpha))
		end
		
		render.SetMaterial(matDarkSphere)
		for i=1, 5 do
			local planetPos = meditationCenter + Vector(math.sin(i*2)*3000, math.cos(i*2)*3000, 500 + math.sin(i)*1000)
			render.DrawSphere(planetPos, 300 + (i*100), 20, 20, color_white)
			
			render.SetMaterial(matGlow)
			render.DrawSprite(planetPos, 4000, 4000, Color(20, 25, 35, 150))
		end
		
		-- Astrolabe Grid (Floor Rings and Lines)
		render.SetMaterial(matBeam)
		local maxRings = 10
		for i=1, maxRings do
			local radius = i * 120
			local segments = 48
			local step = (math.pi * 2) / segments
			local prevPos = meditationCenter + Vector(math.cos(0)*radius, math.sin(0)*radius, 1)
			
			local ringColor = Color(80, 150, 255, (i % 3 == 0) and 20 or 5)
			
			for j=1, segments do
				local angle = j * step
				local nextPos = meditationCenter + Vector(math.cos(angle)*radius, math.sin(angle)*radius, 1)
				render.DrawBeam(prevPos, nextPos, 2, 0, 1, ringColor)
				prevPos = nextPos
			end
		end
		
		-- Astrolabe Radial Lines
		for i=1, 8 do
			local angle = i * (math.pi / 4)
			local endPos = meditationCenter + Vector(math.cos(angle)*1200, math.sin(angle)*1200, 1)
			render.DrawBeam(meditationCenter, endPos, 1.5, 0, 1, Color(80, 150, 255, 8))
		end
		
		-- Force Ripples (Expanding rings on the ground under player)
		for i=1, 3 do
			local expansion = (ct * 0.08 + (i * 0.33)) % 1
			local rippleRadius = expansion * 400
			local rippleAlpha = (1 - expansion) * 150
			
			local segments = 32
			local step = (math.pi * 2) / segments
			local prevPos = meditationCenter + Vector(math.cos(0)*rippleRadius, math.sin(0)*rippleRadius, 2)
			
			for j=1, segments do
				local angle = j * step
				local nextPos = meditationCenter + Vector(math.cos(angle)*rippleRadius, math.sin(angle)*rippleRadius, 2)
				render.DrawBeam(prevPos, nextPos, 4, 0, 1, Color(100, 200, 255, rippleAlpha))
				prevPos = nextPos
			end
		end
		
		-- Shockwaves from unlocks (Explosive light effect)
		if LSCS_SHOCKWAVES then
			for i = #LSCS_SHOCKWAVES, 1, -1 do
				local sw = LSCS_SHOCKWAVES[i]
				local age = CurTime() - sw.startTime
				if age > 0.6 then
					table.remove(LSCS_SHOCKWAVES, i)
				else
					local radius = age * 5000
					local alpha = (1 - (age / 0.6)) * 255
					
					-- Explosive glowing ring
					render.SetMaterial(matRing)
					render.DrawQuadEasy(sw.pos, -currentCamAng:Forward(), radius, radius, Color(150, 220, 255, alpha), 0)
					render.DrawQuadEasy(sw.pos, -currentCamAng:Forward(), radius * 0.8, radius * 0.8, Color(255, 255, 255, alpha), 0)
					
					-- Massive center flash
					render.SetMaterial(matGlow)
					render.DrawSprite(sw.pos, radius * 0.5, radius * 0.5, Color(150, 200, 255, alpha * 0.5))
				end
			end
		end
		
		-- Cinematic Dynamic Lighting for the Player
		local dlight = DynamicLight(ply:EntIndex())
		if dlight then
			dlight.pos = meditationCenter + Vector(0, 0, 30) + meditationForward * 30
			dlight.r = 40
			dlight.g = 100
			dlight.b = 255
			dlight.brightness = 2
			dlight.Decay = 1000
			dlight.Size = 400
			dlight.DieTime = CurTime() + 0.1
		end
		
		for _, ent in ipairs(ents.FindByClass("meditation_dummy")) do
			if IsValid(ent) and ent:GetPos():Distance(meditationCenter) < 50 then
				ent:DrawModel()
			end
		end
		
		render.SetMaterial(matBeam)
		for id, node in pairs(TreeNodes) do
			local nodePos = GetNodeWorldPos(node)
			for _, parentId in ipairs(node.parents) do
				local parentNode = TreeNodes[parentId]
				if parentNode then
					local parentPos = GetNodeWorldPos(parentNode)
					
					local isPathUnlocked = false
					if ply.lscsGetUnlockedSkills then
						local unlocked = ply:lscsGetUnlockedSkills()
						if type(unlocked) == "table" then
							isPathUnlocked = (table.HasValue(unlocked, id) or table.HasValue(unlocked, "lscs_" .. node.type .. "_" .. id)) and 
											 (table.HasValue(unlocked, parentId) or table.HasValue(unlocked, "lscs_" .. parentNode.type .. "_" .. parentId))
						end
					end
					
					local lineColor = isPathUnlocked and Color(255, 255, 255, 255) or Color(120, 130, 150, 180)
					local lineWidth = isPathUnlocked and 16 or 8
					
					render.DrawBeam(nodePos, parentPos, lineWidth, 0, 1, lineColor)
					
					-- Energy Pulses along unlocked lines
					if isPathUnlocked then
						local pulsePhase = (ct * 0.4 + (parentPos.x % 10) * 0.1) % 1
						local pulsePos = parentPos + (nodePos - parentPos) * pulsePhase
						render.SetMaterial(matGlow)
						render.DrawSprite(pulsePos, 40, 40, Color(200, 240, 255, 255))
						render.SetMaterial(matBeam)
					end
				end
			end
		end
		
		local floorDist = Vector(0,0,1):Dot(meditationCenter + Vector(0,0,1))
		
		for id, node in pairs(TreeNodes) do
			local nodePos = GetNodeWorldPos(node)
			local isHovered = ((MeditationUI_State.HoveredNode == id) or (MeditationUI_State.SelectedNode == id)) and (MeditationUI_State.Phase == 2 and MeditationUI_State.State == 2)
			
			-- Breathing node scale
			local breathScale = 1 + math.sin(ct * 2 + math.abs(nodePos.x) * 0.01) * 0.05
			
			local isUnlocked = false
			if ply.lscsGetUnlockedSkills then
				local unlocked = ply:lscsGetUnlockedSkills()
				if type(unlocked) == "table" then
					isUnlocked = table.HasValue(unlocked, id) or table.HasValue(unlocked, "lscs_" .. node.type .. "_" .. id)
				end
			end
			
			local nodeColor = isUnlocked and Color(20, 20, 20) or Color(80, 80, 80)
			local ringSize = 16 * breathScale
			
			if isHovered then
				nodeColor = isUnlocked and Color(0, 0, 0) or Color(200, 230, 255)
				ringSize = 20 * breathScale
			end
			
			if MeditationUI_State.State == 1 then
				-- We are in Shoulder view (Main Menu). Draw the spheres popping from the ground.
				
				render.SuppressEngineLighting(true)
				-- Apply manual ambient lighting to avoid pitch black spheres
				render.SetModelLighting(BOX_FRONT, 0.2, 0.4, 0.8)
				render.SetModelLighting(BOX_TOP, 0.4, 0.6, 1.0)
				render.SetModelLighting(BOX_BOTTOM, 0, 0, 0)
				render.SetModelLighting(BOX_LEFT, 0.1, 0.2, 0.4)
				render.SetModelLighting(BOX_RIGHT, 0.1, 0.2, 0.4)
				render.SetModelLighting(BOX_BACK, 0.1, 0.1, 0.2)
				
				if isUnlocked then
					local dlight = DynamicLight(math.floor(math.abs(nodePos.x) + math.abs(nodePos.y)))
					if dlight then
						dlight.pos = nodePos + Vector(0,0,20)
						dlight.r = 150
						dlight.g = 220
						dlight.b = 255
						dlight.brightness = 4
						dlight.Decay = 1000
						dlight.Size = 250
						dlight.DieTime = CurTime() + 0.1
					end
					
					local oldClip = render.EnableClipping(true)
					render.PushCustomClipPlane(Vector(0,0,1), floorDist)
					
					render.SetMaterial(matBrightSphere)
					render.DrawSphere(nodePos, 12 * breathScale, 30, 30, color_white)
					
					render.PopCustomClipPlane()
					render.EnableClipping(oldClip)
					
					render.SetMaterial(matGlow)
					render.DrawSprite(nodePos, 100 * breathScale, 100 * breathScale, Color(100, 150, 255, 255))
					render.DrawSprite(nodePos, 40 * breathScale, 40 * breathScale, Color(255, 255, 255, 255))
				else
					local oldClip = render.EnableClipping(true)
					render.PushCustomClipPlane(Vector(0,0,1), floorDist)
					
					render.SetMaterial(matDarkSphere)
					render.DrawSphere(nodePos, 12 * breathScale, 30, 30, color_white)
					
					render.PopCustomClipPlane()
					render.EnableClipping(oldClip)
				end
				
				render.SuppressEngineLighting(false)
			else
				local zOffset = (isHovered and 6 or 2) * breathScale
				local drawPos = nodePos + Vector(0, 0, zOffset)
				
				if isUnlocked or isHovered then
					render.SetMaterial(matRing)
					render.DrawQuadEasy(drawPos, -currentCamAng:Forward(), ringSize * 1.8, ringSize * 1.8, Color(100, 150, 255, 200), 0)
				end
				
				local lscsData = GetLSCSNodeData(id, node.type)
				if lscsData then
					local ang = currentCamAng * 1
					ang:RotateAroundAxis(ang:Forward(), 90)
					ang:RotateAroundAxis(ang:Right(), 90)
					
					cam.Start3D2D(drawPos, ang, 0.1 * breathScale)
						if isUnlocked then
							DrawArc(0, 0, 80, 80, 0, 360, 32, Color(255, 255, 255, 255))
						end
						
						if lscsData.icon then
							surface.SetDrawColor(nodeColor.r, nodeColor.g, nodeColor.b, 255)
							if type(lscsData.icon) == "string" then
								surface.SetMaterial(Material(lscsData.icon))
							else
								pcall(function() surface.SetMaterial(lscsData.icon) end)
							end
							pcall(function() surface.DrawTexturedRect(-64, -64, 128, 128) end)
						end
						
						-- Remove text title to match Fallen Order exactly (nodes are just icons)
						
						-- Circular progress bar in 3D
						if MeditationUI_State.UnlockTargetNode == id and MeditationUI_State.UnlockProgress > 0 then
							local pct = MeditationUI_State.UnlockProgress / 1.5
							-- Anillo de fondo (gris)
							DrawArc(0, 0, 90, 8, 0, 360, 40, Color(40, 40, 40, 200))
							-- Anillo de progreso (azul/blanco brillante como en Fallen Order)
							DrawArc(0, 0, 90, 8, -90, -90 + (360 * pct), 40, Color(255, 255, 255, 255))
						end
					cam.End3D2D()
				end
			end
		end
	cam.End3D()
	
	return true
end)

hook.Add("HUDShouldDraw", "Meditation_HideHUD", function(name)
	if MeditationUI_State.Phase > 0 then
		if name == "CHudCrosshair" or name == "CHudHealth" or name == "CHudBattery" or name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
			return false
		end
	end
end)