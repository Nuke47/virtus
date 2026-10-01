hook.Add('PlayerSay', 'SW_ForceStrip_Chat', function(ply, text)
    if string.lower(text) == '!fixbg' then
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            if not SW_InvShop then ply:ChatPrint("[Debug] SW_InvShop is nil!") return end
            if not ply.SW_Data then ply:ChatPrint("[Debug] ply.SW_Data is nil!") return end
            if not ply.SW_Data.active then ply:ChatPrint("[Debug] ply.SW_Data.active is nil!") return end
            
            ply:ChatPrint("[Debug] Ejecutando EnforceActiveBodygroups...")
            SW_InvShop.EnforceActiveBodygroups(ply)
            ply:ChatPrint("[Debug] Listo!")
        end)
        return ''
    end
end) 
