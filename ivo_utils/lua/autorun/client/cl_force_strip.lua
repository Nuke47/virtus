concommand.Add('sw_force_strip', function() local ply = LocalPlayer() net.Start('SW_ReEnforceBGs') net.SendToServer() end) 
