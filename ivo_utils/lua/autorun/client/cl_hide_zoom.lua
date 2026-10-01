hook.Add('HUDShouldDraw', 'HideNativeGmodZoom', function(n) if n == 'CHudZoom' then return false end end) 
