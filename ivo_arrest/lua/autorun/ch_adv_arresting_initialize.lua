-- INITIALIZE SCRIPT
if SERVER then
	for k, v in ipairs( file.Find( "ch_adv_arresting/shared/*.lua", "LUA" ) ) do
		include( "ch_adv_arresting/shared/" .. v )
		AddCSLuaFile( "ch_adv_arresting/shared/" .. v )
	end
	
	for k, v in ipairs( file.Find( "ch_adv_arresting/server/*.lua", "LUA" ) ) do
		include( "ch_adv_arresting/server/" .. v )
	end
	
	for k, v in ipairs( file.Find( "ch_adv_arresting/client/*.lua", "LUA" ) ) do
		AddCSLuaFile( "ch_adv_arresting/client/" .. v )
	end
end

if CLIENT then
	for k, v in ipairs( file.Find( "ch_adv_arresting/shared/*.lua", "LUA" ) ) do
		include( "ch_adv_arresting/shared/" .. v )
	end
	
	for k, v in ipairs( file.Find( "ch_adv_arresting/client/*.lua", "LUA" ) ) do
		include( "ch_adv_arresting/client/" .. v )
	end
end