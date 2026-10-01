local function process()
    local path = "d:/SteamLibrary/steamapps/common/GarrysMod/garrysmod/addons/ivo_utils/lua/sw_invshop/vgui/cl_3d_shop.lua"
    local f = io.open(path, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()

    local searchStr = [[            for _, subCat in ipairs(sortedSubKeys) do
                local nodeID = mainCat .. "_" .. subCat
                
                local btnSub = Scroll:Add("DButton")]]
                
    local repStr = [[            for _, subCat in ipairs(sortedSubKeys) do
                local nodeID = mainCat .. "_" .. subCat
                
                local hasSel = false
                if _G.Shop3D_SelectedItem then
                    for _, itm in ipairs(Shop3D_Categories[mainCat][subCat]) do
                        if itm.id == _G.Shop3D_SelectedItem then hasSel = true; break end
                    end
                    if not hasSel then continue end
                end
                
                if not _G.Shop3D_SelectedItem then
                    local btnSub = Scroll:Add("DButton")]]

    content = string.gsub(content, searchStr:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"), repStr)

    local searchStr2 = [[                end
                
                totalH = totalH + 32
                
                if Shop3D_Expanded[nodeID] then
                    local items = Shop3D_Categories[mainCat][subCat]
                    table.SortByMember(items, "price", true)]]
                    
    local repStr2 = [[                end
                
                if not _G.Shop3D_SelectedItem then
                    totalH = totalH + 32
                end
                
                if _G.Shop3D_SelectedItem or Shop3D_Expanded[nodeID] then
                    local items = Shop3D_Categories[mainCat][subCat]
                    table.SortByMember(items, "price", true)]]

    content = string.gsub(content, searchStr2:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"), repStr2)

    f = io.open(path, "w")
    f:write(content)
    f:close()
end
process()
