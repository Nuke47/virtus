if SERVER then
	util.AddNetworkString("lscs_open_workbench_ui")
	return
end

surface.CreateFont("LSCS_WorkbenchTitle", {
	font = "Roboto",
	size = 36,
	weight = 800,
	antialias = true
})

surface.CreateFont("LSCS_WorkbenchSubTitle", {
	font = "Roboto",
	size = 22,
	weight = 600,
	antialias = true
})

surface.CreateFont("LSCS_WorkbenchText", {
	font = "Roboto",
	size = 18,
	weight = 400,
	antialias = true
})

local function OpenWorkbenchUI()
	if IsValid(LSCS_WorkbenchFrame) then LSCS_WorkbenchFrame:Remove() end

	local scrW, scrH = ScrW(), ScrH()
	local ply = LocalPlayer()
	
	LSCS_WorkbenchFrame = vgui.Create("DFrame")
	local f = LSCS_WorkbenchFrame
	f:SetSize(scrW, scrH)
	f:Center()
	f:SetTitle("")
	f:ShowCloseButton(false)
	f:SetDraggable(false)
	f:MakePopup()
	
	-- Colores Holográficos Star Wars
	local holoblue = Color(0, 180, 255, 200)
	local holobluedark = Color(0, 80, 150, 50)
	local holoyellow = Color(255, 200, 0, 255)
	
	local matBackground = Material("lscs_bg.png", "noclamp smooth")
	
	f.Paint = function(self, w, h)
		-- Imagen Realista de Fondo (Limpia, sin hologramas ni filtros)
		if not matBackground:IsError() then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(matBackground)
			surface.DrawTexturedRect(0, 0, w, h)
		else
			surface.SetDrawColor(5, 8, 12, 255)
			surface.DrawRect(0, 0, w, h)
		end
		
		-- Adornos esquineros Sci-Fi (Top Left & Top Right)
		surface.SetDrawColor(holoblue)
		surface.DrawRect(30, 30, 100, 3)
		surface.DrawRect(30, 30, 3, 100)
		
		surface.DrawRect(w - 130, 30, 100, 3)
		surface.DrawRect(w - 33, 30, 3, 100)
		
		draw.SimpleText("DATAPAD // LIGHTSABER FORGE", "LSCS_WorkbenchTitle", 50, 40, holoblue, TEXT_ALIGN_LEFT)
	end
	
	local currentCategory = "crystal"
	local currentHilt = nil
	local currentCrystal = nil

	for k, v in pairs(ply:lscsGetInventory()) do
		if isbool(ply:lscsGetEquipped()[k]) then
			local item = LSCS:ClassToItem(v)
			if item then
				if item.type == "hilt" then currentHilt = {item = item, invID = k}
				elseif item.type == "crystal" then currentCrystal = {item = item, invID = k} end
			end
		end
	end

	if not currentHilt then
		for k, v in pairs(ply:lscsGetInventory()) do
			local item = LSCS:ClassToItem(v)
			if item and item.type == "hilt" then currentHilt = {item = item, invID = k}; break end
		end
	end

	if not currentCrystal then
		for k, v in pairs(ply:lscsGetInventory()) do
			local item = LSCS:ClassToItem(v)
			if item and item.type == "crystal" then currentCrystal = {item = item, invID = k}; break end
		end
	end

	-- MODEL PANEL INMERSIVO FULLSCREEN 3D
	local mdlPanel = vgui.Create("DModelPanel", f)
	mdlPanel:SetSize(scrW, scrH)
	mdlPanel:SetPos(0, 0)
	mdlPanel:SetModel(currentHilt and currentHilt.item.mdl or "models/weapons/w_crowbar.mdl")
	
	mdlPanel:SetFOV(50)
	mdlPanel:SetCamPos(Vector(95, 0, 18)) -- Cámara más arriba, forzando al sable a descender y encajar en el "Stand"
	mdlPanel:SetLookAt(Vector(0, 0, 18))
	
	mdlPanel:SetAmbientLight(Color(60, 60, 60))
	mdlPanel:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
	mdlPanel:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
	
	local dragPitch = 0
	local isDragging = false
	local lastMouseX = 0
	
	function mdlPanel:LayoutEntity(Entity)
		if isDragging then
			local curX = gui.MouseX()
			dragPitch = dragPitch + (curX - lastMouseX) * 1.2 -- Sensibilidad de rotación
			lastMouseX = curX
		end
		
		-- Ubicación perfecta restaurada
		Entity:SetPos(Vector(50, 5, 19))
		
		-- Rotación matemática perfecta sobre su propio eje (cilíndrica)
		local baseAng = Angle(0, 40, -80)
		baseAng:RotateAroundAxis(baseAng:Up(), dragPitch)
		Entity:SetAngles(baseAng)
	end
	
	if not f.BladeModel then
		f.BladeModel = ClientsideModel("models/error.mdl")
		f.BladeModel:SetNoDraw(true)
	end
	f.OnRemove = function()
		if IsValid(f.BladeModel) then f.BladeModel:Remove() end
	end
	
	function mdlPanel:PostDrawModel(Entity)
		if not currentCrystal or not currentCrystal.item then return end
		local cry = currentCrystal.item
		local length = (cry.length or 45)
		local width = (cry.width or 1.5)
		local actual_width = width + math.Rand(0, cry.widthWiggle or 0.6)
		local matCore = cry.material_core or "trails/laser"
		if type(matCore) == "string" then matCore = Material(matCore) end
		local matGlow = cry.material_glow or "sprites/light_glow02_add"
		if type(matGlow) == "string" then matGlow = Material(matGlow) end
		local matCoreTip = cry.material_core_tip or "sprites/light_glow02_add"
		if type(matCoreTip) == "string" then matCoreTip = Material(matCoreTip) end
		local color_blur = cry.color_blur or cry.color or Color(0, 255, 100)
		local color_core = cry.color_core or Color(255, 255, 255)
		
		local function DrawSingleBlade(bpos, bdir)
			if cry.mdl then
				if IsValid(f.BladeModel) then
					if f.BladeModel:GetModel() ~= cry.mdl then f.BladeModel:SetModel(cry.mdl) end
					local bladeAng = Entity:GetAngles()
					local Forward = bladeAng:Up()
					local Right = bladeAng:Right()
					bladeAng:RotateAroundAxis(Right, math.deg(math.acos(math.Clamp(Forward:Dot(bdir) ,-1,1))))
					f.BladeModel:SetPos(bpos)
					f.BladeModel:SetAngles(bladeAng)
					f.BladeModel:SetupBones()
					f.BladeModel:DrawModel()
				end
				return
			end
			render.SetMaterial(matGlow)
			render.DrawSprite(bpos, width*32, width*32, color_blur)
			for i = 0, math.Round(length - 1, 0) do
				render.DrawSprite(bpos + bdir * i, width*12, width*12, color_blur)
			end
			local realEnd = bpos + bdir * math.max(length - 0.9, 0)
			render.SetMaterial(matCore)
			render.DrawBeam(bpos, realEnd, actual_width, 1, 1, color_core)
			render.SetMaterial(matCoreTip)
			render.DrawBeam(realEnd, realEnd + bdir, actual_width, 0.9, 0.1, color_core)
		end
		
		local drawn = false
		local atts = Entity:GetAttachments()
		if atts then
			for _, v in pairs(atts) do
				local name = string.lower(v.name or "")
				if string.find(name, "blade") then
					local attData = Entity:GetAttachment(v.id)
					if attData then
						DrawSingleBlade(attData.Pos, attData.Ang:Up())
						drawn = true
					end
				end
			end
		end
		
		if not drawn then
			local fallbackPos = Entity:GetPos() + Entity:GetAngles():Up() * Entity:OBBMaxs().z
			DrawSingleBlade(fallbackPos, Entity:GetAngles():Up())
		end
	end
	
	local uiLayer = vgui.Create("DPanel", f)
	uiLayer:SetSize(scrW, scrH)
	uiLayer.Paint = function() end
	
	uiLayer.OnMousePressed = function(self, key)
		if key == MOUSE_LEFT then
			isDragging = true
			lastMouseX = gui.MouseX()
		end
	end
	
	uiLayer.OnMouseReleased = function(self, key)
		if key == MOUSE_LEFT then
			isDragging = false
		end
	end
	
	uiLayer.Think = function(self)
		if isDragging and not input.IsMouseDown(MOUSE_LEFT) then
			isDragging = false
		end
	end

	-- Helper para dibujar fondos circulares Jedi
	local function DrawCircle(x, y, radius, seg)
		local cir = {}
		table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })
		for i = 0, seg do
			local a = math.rad((i / seg) * -360)
			table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
		end
		local a = math.rad(0)
		table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
		surface.DrawPoly(cir)
	end

	-- BOTÓN RETURN (Movido abajo a la derecha, estilo panel elegante)
	local backBtn = vgui.Create("DButton", uiLayer)
	backBtn:SetSize(160, 50)
	backBtn:SetPos(scrW - 200, scrH - 90)
	backBtn:SetText("RETURN")
	backBtn:SetFont("LSCS_WorkbenchTitle")
	backBtn:SetTextColor(Color(255, 255, 255))
	backBtn.Paint = function(self, w, h)
		local a = self:IsHovered() and 150 or 50
		surface.SetDrawColor(0, 150, 255, a)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(holoblue)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
		draw.NoTexture()
		surface.DrawPoly({{x = w - 15, y = h - 6}, {x = w - 6, y = h - 6}, {x = w - 6, y = h - 15}})
	end
	backBtn.DoClick = function()
		surface.PlaySound("weapons/physcannon/physcannon_charge.wav")
		ply:lscsCraftSaber()
		f:Remove()
	end

	-- PESTAÑAS HORIZONTALES (Jedi Survivor Categorías)
	local tabContainer = vgui.Create("DPanel", uiLayer)
	tabContainer:SetSize(600, 50)
	tabContainer:SetPos(scrW / 2 - 300, scrH - 260)
	tabContainer.Paint = function(self, w, h)
		surface.SetDrawColor(0, 150, 255, 30)
		surface.DrawRect(0, h - 3, w, 3)
	end
	
	local tabHilts = vgui.Create("DButton", tabContainer)
	tabHilts:SetSize(295, 50)
	tabHilts:SetPos(0, 0)
	tabHilts:SetText("")
	tabHilts.Paint = function(self, w, h)
		local col = currentCategory == "hilt" and Color(255,255,255) or Color(100,100,100)
		draw.SimpleText("HILTS", "LSCS_WorkbenchTitle", w/2, h/2 - 5, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if currentCategory == "hilt" then
			surface.SetDrawColor(holoyellow.r, holoyellow.g, holoyellow.b, 255)
			surface.DrawRect(0, h-4, w, 4)
		end
	end
	tabHilts.DoClick = function() surface.PlaySound("UI/buttonclick.wav"); currentCategory = "hilt"; LoadInventory() end
	
	local tabCrystals = vgui.Create("DButton", tabContainer)
	tabCrystals:SetSize(295, 50)
	tabCrystals:SetPos(305, 0)
	tabCrystals:SetText("")
	tabCrystals.Paint = function(self, w, h)
		local col = currentCategory == "crystal" and Color(255,255,255) or Color(100,100,100)
		draw.SimpleText("CRYSTALS", "LSCS_WorkbenchTitle", w/2, h/2 - 5, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if currentCategory == "crystal" then
			surface.SetDrawColor(holoyellow.r, holoyellow.g, holoyellow.b, 255)
			surface.DrawRect(0, h-4, w, 4)
		end
	end
	tabCrystals.DoClick = function() surface.PlaySound("UI/buttonclick.wav"); currentCategory = "crystal"; LoadInventory() end

	-- CARRUSEL HORIZONTAL DE TARJETAS
	local invScroller = vgui.Create("DHorizontalScroller", uiLayer)
	invScroller:SetSize(1000, 180)
	invScroller:SetPos(scrW / 2 - 500, scrH - 200)
	invScroller:SetOverlap(-15) -- Espacio separador entre tarjetas

	function LoadInventory()
		invScroller:Clear()
		local inventory = ply:lscsGetInventory()
		
		for k, v in pairs(inventory) do
			local item = LSCS:ClassToItem(v)
			if item and item.type == currentCategory then
				local isEq = false
				if currentCategory == "hilt" and currentHilt and currentHilt.invID == k then isEq = true
				elseif currentCategory == "crystal" and currentCrystal and currentCrystal.invID == k then isEq = true end
				
				local myItem = item 
				local myK = k

				local card = vgui.Create("DButton")
				card:SetSize(140, 160)
				card:SetText("")
				
				local bdColor = holoblue
				if currentCategory == "crystal" then bdColor = myItem.color_blur or myItem.color or bdColor end
				
				card.Paint = function(self, w, h)
					local alpha = self:IsHovered() and 100 or 40
					local txtCol = self:IsHovered() and Color(255,255,255) or Color(150,150,150)
					
					-- Fondo holográfico de la tarjeta
					surface.SetDrawColor(0, 50, 100, 50)
					surface.DrawRect(0, 0, w, h)
					
					-- Círculo brillante central detrás del modelo 3D
					draw.NoTexture()
					surface.SetDrawColor(bdColor.r, bdColor.g, bdColor.b, alpha)
					DrawCircle(w/2, h/2 - 15, 45, 32)
					
					-- Borde inferior y contorno oro si está activo
					if isEq then
						surface.SetDrawColor(holoyellow.r, holoyellow.g, holoyellow.b, 255)
						surface.DrawOutlinedRect(0, 0, w, h, 2)
						draw.SimpleText("ACTIVE", "LSCS_WorkbenchText", w/2, 10, holoyellow, TEXT_ALIGN_CENTER)
					else
						surface.SetDrawColor(bdColor.r, bdColor.g, bdColor.b, 200)
						surface.DrawRect(0, h-3, w, 3)
					end
					
					draw.SimpleText(myItem.name or "Item", "LSCS_WorkbenchText", w/2, h - 25, txtCol, TEXT_ALIGN_CENTER)
				end
				
				-- Renderizador Miniatura 3D dentro de la tarjeta
				local mdlCard = vgui.Create("DModelPanel", card)
				mdlCard:SetSize(120, 120)
				mdlCard:SetPos(10, 5)
				mdlCard:SetMouseInputEnabled(false)
				
				local mdlString = myItem.mdl or "models/error.mdl"
				-- Usar el modelo nativo que usa el addon LSCS para los cristales (rock001a)
				if currentCategory == "crystal" and not myItem.mdl then
					mdlString = "models/props_junk/rock001a.mdl"
				end
				
				mdlCard:SetModel(mdlString)
				
				-- Aplicar el material de energía pura brillante que usa LSCS
				if currentCategory == "crystal" and IsValid(mdlCard.Entity) then
					local coreCol = myItem.color_core or Color(255, 255, 255)
					mdlCard:SetColor(coreCol)
					mdlCard.Entity:SetMaterial("lights/white")
				end
				
				-- Autocentrar la cámara del mini icono y hacerla girar
				if IsValid(mdlCard.Entity) then
					local mn, mx = mdlCard.Entity:GetRenderBounds()
					local size = 0
					size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
					size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
					size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
					mdlCard:SetFOV(45)
					mdlCard:SetCamPos(Vector(size*1.5, size*1.5, size*1.5))
					mdlCard:SetLookAt((mn + mx) * 0.5)
					
					-- Giro continuo automático para el icono 3D
					mdlCard.LayoutEntity = function(self, ent)
						ent:SetAngles(Angle(0, RealTime() * 50, 0))
					end
				end
				
				-- Redirigir el clic de la tarjeta padre
				card.DoClick = function()
					surface.PlaySound("UI/buttonrol.wav")
					if myItem.type == "hilt" then
						currentHilt = {item = myItem, invID = myK}
						if myItem.mdl then mdlPanel:SetModel(myItem.mdl) end
					elseif myItem.type == "crystal" then
						currentCrystal = {item = myItem, invID = myK}
					end
					
					ply:lscsClearEquipped(myItem.type)
					timer.Simple(0.1, function()
						ply:lscsEquipItem(myK, true)
						ply:lscsCraftSaber()
						LoadInventory()
					end)
				end
				
				invScroller:AddPanel(card)
			end
		end
	end

	-- Inicializar
	currentCategory = "hilt"
	LoadInventory()
end

net.Receive("lscs_open_workbench_ui", function()
	OpenWorkbenchUI()
end)