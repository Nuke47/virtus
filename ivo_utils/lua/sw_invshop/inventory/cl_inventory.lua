SW_InvShop.ActiveInv = SW_InvShop.ActiveInv or {}
SW_InvShop.Armario = SW_InvShop.Armario or {}

net.Receive("SW_SyncData", function()
    SW_InvShop.ActiveInv = net.ReadTable()
    SW_InvShop.Armario = net.ReadTable()
    SW_InvShop.SavedLoadouts = net.ReadTable()
    
    -- Si el menú está abierto, forzar un refresco visual
    if IsValid(SW_InvShop.MainMenu) then
        SW_InvShop.MainMenu:Refresh()
    end
    hook.Run("SW_InventorySynced")
end)
