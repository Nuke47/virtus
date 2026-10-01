
if SERVER then

	hook.Add('EntityTakeDamage','CSquadShield',function(ent,dmg)
		if ent.PleaseKillMe then
			local ed = EffectData()
			local dmgpos = dmg:GetDamagePosition()
			ed:SetOrigin(dmgpos)
			ed:SetNormal((dmgpos-ent:GetPos()):GetNormalized())
			ed:SetRadius(1)
			util.Effect('cball_bounce',ed)
			util.Effect('AR2Explosion',ed)
			--ent:GetParent():EmitSound(('ambient/energy/weld%s.wav'):format(math.random(1,2)),80,math.random(144,192),.64)
			return true
		end
	end)

end

if CLIENT then

	local CDRAW = include('CDRAW.lua')

	surface.CreateFont('SHLACK',{font='Trebuchet MS',size=32,weight=400})

	local MSW, MSH = ScrW(), ScrH()
	local off_h = MSH/2-32
	local col_bg = Color(0,0,0,192)
	local col_fill = Color(64,128,192,255)
	local col_txt = Color(255,255,255)
	local sqshtab = {}
	
	hook.Add('Tick','CSquadShield',function()
		sqshtab = {}
		for k,v in pairs(ents.GetAll()) do
			if v:GetClass() == 'squad_shield' then
				sqshtab[#sqshtab+1] = v
			end
		end
	end)

	hook.Add('HUDPaint','CSquadShield',function()
		if !IsValid(LocalPlayer()) or !IsValid(LocalPlayer():GetActiveWeapon()) then return end
		local squad_shield = LocalPlayer():GetNWEntity('CSquadShield')
		if LocalPlayer():GetActiveWeapon():GetClass() == 'weapon_squadshield_arm' then
			local cooldown = LocalPlayer():GetNWInt('CSqShCooldown',CurTime())-CurTime() <= 0 and ('Ready to deploy') or ('Cooldown: '..string.ToMinutesSeconds(LocalPlayer():GetNWInt('CSqShCooldown',CurTime())-CurTime()+1))
			local str = IsValid(squad_shield) and (!squad_shield:GetActive() and cooldown or 'Deploy time: '..string.ToMinutesSeconds(squad_shield:GetTimeOffset()-CurTime()+squad_shield.LifeTime+1)) or cooldown
			CDRAW.DrawRect(col_bg,MSW-256-16,off_h+80,256,64)
			local fulfill = (IsValid(squad_shield) and squad_shield:GetActive()) and (squad_shield:GetTimeOffset()-CurTime()+squad_shield.LifeTime)/squad_shield.LifeTime or 0
			CDRAW.DrawRect(col_fill,MSW-256-16+4,off_h+80+4,248*fulfill,56)
			CDRAW.DrawText('SHLACK',MSW-256-8,off_h+80+16,col_txt,str)
		end
	end)

	surface.CreateFont('cents_ss',{font='Trebuchet MS',size=200})
	surface.CreateFont('cents_ss_blur',{font='Trebuchet MS',size=200,blursize=4})

	local rendmat = Material('models/props_combine/stasisshield_sheet')
	local rendmat2 = Material('models/props_combine/portalball001_sheet')
	local beammat = Material('cable/physbeam')
	local ringmat = Material('cable/blue_elec')
	local solvemat = Material('effects/tool_tracer')
	local text_col = Color(64,192,255)
	local beamcol = Color(0,192,255)
	local blue_shg = Color(0,64,255,64)
	local quality = 32
	local beamcount = 5
	local beam_width = 4
	local ring_width = 8
	local spr = 128
	local spr_rime = 0.1
	local step = .02

	local function qc(t,p0,p1,p2)
		return (1-t)^2*p0+2*(1-t)*t*p1+t^2*p2
	end

	hook.Add('PostDrawTranslucentRenderables','CSquadShield',function(bDepth,bSkybox)
		if bSkybox then return end
		for k,v in pairs(sqshtab) do
			if !IsValid(v) or !v:GetActive() then continue end
			local vpos = v:GetPos()
			local qq1 = Vector(0,0,1)
			local qq2 = qq1:Dot(vpos)
			render.SetMaterial(beammat)
			local startpos = vpos
			local radius = v.Radius*v.SphereScale
			local act_endpos = vpos+Vector(0,0,radius+16+math.sin(SysTime()*0.6)*32)
			for pee = 0, beamcount-1 do
				local haha = math.pi*2*pee/beamcount
				local endpos = startpos+Vector(math.sin(haha+CurTime()*spr_rime)*spr,math.cos(haha+CurTime()*spr_rime)*spr,radius-32)
				local normal = (endpos-startpos):GetNormalized()
				local dist = startpos:Distance(endpos)
				local mt = Matrix()
				mt:SetAngles(normal:Angle()+Angle(90,0,0))
				local oldpos
				for i = 0, 1, step do
					local p = qc(i,startpos,act_endpos,endpos)
					if oldpos then
						render.DrawBeam(oldpos,p,beam_width,1,1,beamcol)
					end
					oldpos = p
				end
			end
			render.SetMaterial(ringmat)
			for i = 1, quality do
				local p1 = vpos+Vector(math.sin((i/quality)*math.pi*2)*radius,math.cos((i/quality)*math.pi*2)*radius,0)
				local p2 = vpos+Vector(math.sin(((i+1)/quality)*math.pi*2)*radius,math.cos(((i+1)/quality)*math.pi*2)*radius,0)
				render.DrawBeam(p1,p2,ring_width,1,1,beamcol)
			end
			render.SetMaterial(solvemat)
			render.DrawBeam(vpos+Vector(0,0,8),vpos+Vector(0,0,16),8,CurTime()*2,CurTime()*2-1,beamcol)
			local oldEC = render.EnableClipping(true)
			render.PushCustomClipPlane(qq1,qq2)
			render.SetColorMaterial()
			render.DrawSphere(vpos,radius,quality,quality,blue_shg)
			render.SetMaterial(rendmat)
			render.OverrideBlend(true,3,1,BLENDFUNC_ADD)
			render.DrawSphere(vpos,radius,quality,quality)
			render.OverrideBlend(false,3,1,BLENDFUNC_ADD)
			render.SetMaterial(rendmat2)
			render.OverrideBlend(true,2,1,BLENDFUNC_ADD)
			render.DrawSphere(vpos,radius,quality,quality)
			render.OverrideBlend(false,2,1,BLENDFUNC_ADD)
			render.PopCustomClipPlane()
			render.EnableClipping(oldEC)
			local va = GetViewEntity():GetAngles()
			local pos = vpos+Vector(0,0,64+math.sin(SysTime()*1.2)*2)
			if v:GetShieldOwner() ~= LocalPlayer() then continue end
			cam.Start3D2D(pos,Angle(0,va.y-90,90-va.p),0.08)
				CDRAW.DrawNiceText(text_col,0,'cents_ss','TIME LEFT: '..string.ToMinutesSeconds(v:GetTimeOffset()-CurTime()+v.LifeTime+1))
			cam.End3D2D()
		end
	end)

end