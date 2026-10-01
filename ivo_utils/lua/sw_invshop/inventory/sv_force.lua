concommand.Add("sw_force_give_arc", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    for _, v in ipairs(player.GetAll()) do
        if v.SW_Data then
            if not v.SW_Data.active["base_dc15a"] and not v.SW_Data.armario["base_dc15a"] then
                v.SW_Data.active["base_dc15a"] = 1
                v.SW_Data.active["base_dc17"] = 1
                v:ChatPrint("[Inventario] Tus armas base de ARC (DC-15A y DC-17) han sido forzadas a tu inventario activo.")
                SW_InvShop.SaveCurrentActiveAsLoadoutToDB(v)
                SW_InvShop.SyncPlayerData(v)
                SW_InvShop.ApplyLoadout(v)
            else
                v:ChatPrint("[Inventario] Ya posees la DC-15A en algun lugar de tu inventario (Activo o Baul).")
            end
        end
    end
    if IsValid(ply) then ply:ChatPrint("Comando ejecutado.") end
end)
