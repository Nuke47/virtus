local PMETA = FindMetaTable( "Player" )

function PMETA:CH_ADVARREST_IsAllowedUsergroup()
	if serverguard then
		return CH_ADVArrest.Config.AllowedUsergroups[ serverguard.player:GetRank( self ) ] or false
	else
		return CH_ADVArrest.Config.AllowedUsergroups[ self:GetUserGroup() ] or false
	end
end

function PMETA:CH_ADVARREST_IsAuthorizedToArrest()
	if self:CH_ADVARREST_IsAllowedUsergroup() then
		return true
	else
		return CH_ADVArrest.Config.AllowedTeams[ team.GetName( self:Team() ) ]
	end
end

hook.Add("SetupMove", "CH_ADVArrest_DragMove", function(ply, mvd, cmd)
    if ply:GetNWBool("CH_ADVARREST_Handcuffed") then
        -- Evitar que el jugador camine por sí solo
        mvd:SetMaxClientSpeed(1)
        mvd:SetMaxSpeed(1)
        mvd:SetForwardSpeed(0)
        mvd:SetSideSpeed(0)
        mvd:SetUpSpeed(0)

        local dragger = ply:GetNWEntity("CH_ADVARREST_DraggedBy")
        if IsValid(dragger) and dragger:Alive() then
            local dist = dragger:GetPos():DistToSqr(ply:GetPos())
            if dist > 200000 then
                if SERVER then
                    ply:SetNWEntity("CH_ADVARREST_DraggedBy", NULL)
                    dragger.CH_ADVArrest_Dragging = nil
                end
            elseif dist > 10000 then
                local dir = (dragger:GetPos() - ply:GetPos()):GetNormalized()
                mvd:SetVelocity(dir * 250)
            end
        end
    end
end)