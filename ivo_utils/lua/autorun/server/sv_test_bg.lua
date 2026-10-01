concommand.Add('sw_test_bg', function(ply) print('Testing bg...') local success, err = pcall(function() SW_InvShop.EnforceActiveBodygroups(ply) end) print('Result: ', success, err) end) 
