for k,v in pairs(player.GetAll()) do print('Player: '..v:Nick()) if v.SW_Data then print('  Has rangefinder: '..tostring(v.SW_Data.active['bg_rangefinder'])) else print('  No SW_Data') end end 
