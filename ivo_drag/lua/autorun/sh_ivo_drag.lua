if SERVER then
    util.AddNetworkString("ivo_drag_progress")

    hook.Add("Think", "ivo_drag_think", function()
        for _, ply in ipairs(player.GetAll()) do
            if not ply:Alive() then
                if IsValid(ply.ivo_Carrying) then
                    local ent = ply.ivo_Carrying
                    ent.ivo_Carrier = nil
                    
                    if IsValid(ent.ivo_FakeCorpseHelper) then ent.ivo_FakeCorpseHelper:Remove() end
                    if IsValid(ent.ivo_FakeCorpse) then ent.ivo_FakeCorpse:Remove() end
                    ent:SetParent(nil)
                    ent:SetNoDraw(false)
                    
                    if ent.ivo_OldCollisionGroup then
                        ent:SetCollisionGroup(ent.ivo_OldCollisionGroup)
                    else
                        ent:SetCollisionGroup(COLLISION_GROUP_NONE)
                        if ent:GetNWBool("IsPlayerCorpse") then
                            ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                        end
                    end
                end
                ply.ivo_Carrying = nil
                ply.ivo_DragHoldTime = nil
                ply:SetNWBool("ivo_IsCarrying", false)
                continue
            end
            
            if ply:GetNWBool("ivo_IsCarrying") and not IsValid(ply.ivo_Carrying) then
                ply:SetNWBool("ivo_IsCarrying", false)
            end

            if not IsValid(ply.ivo_Carrying) then
                if ply:KeyDown(IN_USE) then
                    local tr = ply:GetEyeTrace()
                    local ent = tr.Entity
                    if IsValid(ent) and ent:GetClass() == "prop_ragdoll" and tr.HitPos:DistToSqr(ply:GetPos()) < 15000 then
                        if not ply.ivo_DragHoldTime then
                            ply.ivo_DragHoldTime = CurTime()
                            net.Start("ivo_drag_progress")
                            net.WriteBool(true)
                            net.Send(ply)
                        elseif CurTime() - ply.ivo_DragHoldTime > 0.8 then
                            -- Pick up
                            ply.ivo_Carrying = ent
                            ply.ivo_DragHoldTime = nil
                            ent.ivo_Carrier = ply
                            ply:SetNWBool("ivo_IsCarrying", true)
                            
                            ent.ivo_OldCollisionGroup = ent:GetCollisionGroup()
                            ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
                            ent:SetNoDraw(true)
                            
                            -- Ignore view pitch/roll so the body doesn't spawn floating up or down
                            local rootAng = Angle(0, ply:EyeAngles().y, 0)
                            local rootPos = ply:GetPos()
                            
                            local desiredPos = rootPos + Vector(0,0,55) + rootAng:Right() * 10
                            local desiredAng = rootAng * 1
                            desiredAng:RotateAroundAxis(desiredAng:Right(), 90) -- Lying on stomach
                            desiredAng:RotateAroundAxis(desiredAng:Up(), 180) -- Head points back
                            
                            local fake = ents.Create("prop_dynamic")
                            fake:SetModel(ent:GetModel())
                            fake:SetPos(desiredPos)
                            fake:SetAngles(desiredAng)
                            fake:Spawn()
                            
                            -- We do NOT use SetParent(ply) because Star Wars RP servers often use FPP (Falco's Prop Protection) 
                            -- which blocks parenting props to players and throws Lua errors (getting the HUD stuck).
                            -- We will move the fake corpse manually in the Think loop.
                            
                            -- Match appearance
                            fake:SetSkin(ent:GetSkin())
                            for i=0, ent:GetNumBodyGroups()-1 do
                                fake:SetBodygroup(i, ent:GetBodygroup(i))
                            end
                            fake:SetMaterial(ent:GetMaterial())
                            fake:SetColor(ent:GetColor())
                            
                            -- Force an idle pose and manually fold the body so it drapes over the shoulder
                            local seq = fake:LookupSequence("idle_all_01")
                            if seq <= 0 then seq = fake:LookupSequence("idle") end
                            if seq > 0 then
                                fake:SetSequence(seq)
                            end
                            fake:SetPlaybackRate(0)
                            
                            -- Fold the body (Waist 90 deg forward, Spine curved forward)
                            -- Using fallback names in case the Star Wars model uses a custom skeleton
                            local bonesToBend = {
                                {"ValveBiped.Bip01_L_Thigh", Angle(0, -80, 0)},
                                {"ValveBiped.Bip01_R_Thigh", Angle(0, -80, 0)},
                                {"L_Thigh", Angle(0, -80, 0)},
                                {"R_Thigh", Angle(0, -80, 0)},
                                {"ValveBiped.Bip01_Spine", Angle(0, -20, 0)},
                                {"ValveBiped.Bip01_Spine1", Angle(0, -20, 0)},
                                {"ValveBiped.Bip01_Spine2", Angle(0, -20, 0)},
                                {"Spine", Angle(0, -20, 0)},
                                {"Spine1", Angle(0, -20, 0)},
                                {"Spine2", Angle(0, -20, 0)},
                                {"ValveBiped.Bip01_L_UpperArm", Angle(0, -60, 0)},
                                {"ValveBiped.Bip01_R_UpperArm", Angle(0, -60, 0)},
                                {"L_UpperArm", Angle(0, -60, 0)},
                                {"R_UpperArm", Angle(0, -60, 0)}
                            }
                            
                            for _, b in ipairs(bonesToBend) do
                                local bId = fake:LookupBone(b[1])
                                if bId then
                                    fake:ManipulateBoneAngles(bId, b[2])
                                end
                            end
                            
                            ent.ivo_FakeCorpse = fake
                            
                            -- Disable motion instead of parenting to prevent Havok physics cache bugs
                            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                                local phys = ent:GetPhysicsObjectNum(i)
                                if IsValid(phys) then
                                    phys:EnableMotion(false)
                                end
                            end
                            
                            net.Start("ivo_drag_progress")
                            net.WriteBool(false)
                            net.Send(ply)
                        end
                    else
                        if ply.ivo_DragHoldTime then
                            ply.ivo_DragHoldTime = nil
                            net.Start("ivo_drag_progress")
                            net.WriteBool(false)
                            net.Send(ply)
                        end
                    end
                else
                    if ply.ivo_DragHoldTime then
                        ply.ivo_DragHoldTime = nil
                        net.Start("ivo_drag_progress")
                        net.WriteBool(false)
                        net.Send(ply)
                    end
                end
            else
                -- Is carrying
                local ent = ply.ivo_Carrying
                
                if IsValid(ent.ivo_FakeCorpse) then
                    local fake = ent.ivo_FakeCorpse
                    
                    local rootAng = Angle(0, ply:EyeAngles().y, 0)
                    local rootPos = ply:GetPos()
                    
                    local desiredPos = rootPos + Vector(0,0,55) + rootAng:Right() * 10
                    local desiredAng = rootAng * 1
                    desiredAng:RotateAroundAxis(desiredAng:Right(), 90)
                    desiredAng:RotateAroundAxis(desiredAng:Up(), 180)
                    
                    -- Simple vertical bobbing based on spine
                    ply:SetupBones()
                    local boneId = ply:LookupBone("ValveBiped.Bip01_Spine2") or ply:LookupBone("ValveBiped.Bip01_Spine") or 0
                    local m = ply:GetBoneMatrix(boneId)
                    if m then
                        local spineZ = m:GetTranslation().z
                        local defaultZ = rootPos.z + 50
                        desiredPos.z = desiredPos.z + (spineZ - defaultZ)
                    end
                    
                    fake:SetPos(desiredPos)
                    fake:SetAngles(desiredAng)
                end
                
                -- Drop if pressing Use (but need a small delay so we don't drop immediately if they held it slightly longer)
                if ply:KeyPressed(IN_USE) then
                    ply.ivo_Carrying = nil
                    ent.ivo_Carrier = nil
                    ply:SetNWBool("ivo_IsCarrying", false)
                    
                    ent:SetNoDraw(false)
                    
                    if IsValid(ent.ivo_FakeCorpse) then
                        local fake = ent.ivo_FakeCorpse
                        fake:SetupBones()
                        
                        -- Set entity origin to the new drop location
                        ent:SetPos(fake:GetPos())
                        
                        -- Move the ragdoll physics to match the fake corpse pose
                        for i = 0, ent:GetPhysicsObjectCount() - 1 do
                            local phys = ent:GetPhysicsObjectNum(i)
                            if IsValid(phys) then
                                phys:EnableMotion(true)
                                phys:Wake()
                                
                                local bId = ent:TranslatePhysBoneToBone(i)
                                if bId then
                                    local p, a = fake:GetBonePosition(bId)
                                    if p and p ~= fake:GetPos() then
                                        phys:SetPos(p)
                                        phys:SetAngles(a)
                                    else
                                        -- Prevent explosion if SetupBones failed
                                        phys:SetPos(fake:GetPos() + Vector(0, 0, i * 2))
                                        phys:SetAngles(fake:GetAngles())
                                    end
                                end
                            end
                        end
                        fake:Remove()
                    end
                    
                    if ent.ivo_OldCollisionGroup then
                        ent:SetCollisionGroup(ent.ivo_OldCollisionGroup)
                    else
                        ent:SetCollisionGroup(COLLISION_GROUP_NONE)
                        if ent:GetNWBool("IsPlayerCorpse") then
                            ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                        end
                    end
                    
                    continue
                end
            end
        end
    end)

else
    -- CLIENT
    local is_progressing = false
    local progress_start = 0

    net.Receive("ivo_drag_progress", function()
        local state = net.ReadBool()
        is_progressing = state
        if state then
            progress_start = CurTime()
        end
    end)

    local function DrawArc(x, y, radius, thickness, fraction, color)
        local startAng = -90
        local endAng = startAng + (fraction * 360)
        local steps = math.max(4, math.ceil(40 * fraction))
        
        local quad = {}
        draw.NoTexture()
        surface.SetDrawColor(color)
        
        for i = 0, steps - 1 do
            local a1 = math.rad(Lerp(i / steps, startAng, endAng))
            local a2 = math.rad(Lerp((i + 1) / steps, startAng, endAng))
            
            local c1, s1 = math.cos(a1), math.sin(a1)
            local c2, s2 = math.cos(a2), math.sin(a2)
            
            quad[1] = {x = x + c1 * radius, y = y + s1 * radius}
            quad[2] = {x = x + c2 * radius, y = y + s2 * radius}
            quad[3] = {x = x + c2 * (radius - thickness), y = y + s2 * (radius - thickness)}
            quad[4] = {x = x + c1 * (radius - thickness), y = y + s1 * (radius - thickness)}
            
            surface.DrawPoly(quad)
        end
    end

    hook.Add("HUDPaint", "ivo_drag_hud", function()
        if is_progressing then
            local fraction = math.Clamp((CurTime() - progress_start) / 0.8, 0, 1)
            local x, y = ScrW() / 2, ScrH() / 2 + 50
            local radius = 20
            local thickness = 5
            
            -- Fondo del circulo (gris oscuro)
            DrawArc(x, y, radius, thickness, 1, Color(0, 0, 0, 150))
            
            -- Progreso del circulo (naranja)
            if fraction > 0 then
                DrawArc(x, y, radius, thickness, fraction, Color(255, 150, 0, 255))
            end
            
            -- Texto debajo
            draw.SimpleText("Cargando...", "DermaDefault", x, y + radius + 12, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end)

    -- Animation override (grab stick pose)
    hook.Add("CalcMainActivity", "ivo_drag_anim", function(ply, velocity)
        if ply:GetNWBool("ivo_IsCarrying", false) or (SERVER and IsValid(ply.ivo_Carrying)) then
            ply.CalcSeqOverride = -1
            
            if ply:IsOnGround() then
                if velocity:Length2DSqr() > 1 then
                    if ply:Crouching() then
                        ply.CalcIdeal = ACT_HL2MP_WALK_CROUCH_MELEE
                    else
                        ply.CalcIdeal = ACT_HL2MP_RUN_MELEE
                    end
                else
                    if ply:Crouching() then
                        ply.CalcIdeal = ACT_HL2MP_IDLE_CROUCH_MELEE
                    else
                        ply.CalcIdeal = ACT_HL2MP_IDLE_MELEE
                    end
                end
            else
                ply.CalcIdeal = ACT_HL2MP_JUMP_MELEE
            end
            
            return ply.CalcIdeal, ply.CalcSeqOverride
        end
    end)
end

-- Slow down player (SHARED for prediction)
hook.Add("Move", "ivo_drag_slow", function(ply, mv)
    if ply:GetNWBool("ivo_IsCarrying", false) or (SERVER and IsValid(ply.ivo_Carrying)) then
        local speed = mv:GetMaxSpeed() * 0.4
        mv:SetMaxSpeed(speed)
        mv:SetMaxClientSpeed(speed)
    end
end)
