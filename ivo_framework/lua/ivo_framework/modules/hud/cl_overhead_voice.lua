-- This script hides the default voice UI and draws a custom microphone icon with a green glow above speaking players' heads.

-- Hide the default voice icon
hook.Add("PlayerStartVoice", "HideDefaultVoiceUI_Start", function(ply)
	return true
end)

hook.Add("PlayerEndVoice", "HideDefaultVoiceUI_End", function(ply)
	return true
end)

-- Eliminar el ícono 3D que viene por defecto en DarkRP u otros addons
hook.Remove("PostPlayerDraw", "DarkRP_DrawVoiceChat")
hook.Remove("PostPlayerDraw", "DarkRP_ChatBubbles")

if hook.GetTable().PostPlayerDraw then
	for k, v in pairs(hook.GetTable().PostPlayerDraw) do
		if type(k) == "string" and string.find(string.lower(k), "voice") then
			hook.Remove("PostPlayerDraw", k)
		end
	end
end

timer.Create("ForceRemoveDarkRPVoice", 1, 0, function()
	hook.Remove("PostPlayerDraw", "DarkRP_DrawVoiceChat")
	hook.Remove("PostPlayerDraw", "DarkRP_ChatBubbles")
	if GAMEMODE and GAMEMODE.DrawVoiceChat then
		GAMEMODE.DrawVoiceChat = function() end
	end
	if GAMEMODE and GAMEMODE.DrawChatBubbles then
		GAMEMODE.DrawChatBubbles = function() end
	end
	
	if hook.GetTable().PostPlayerDraw then
		for k, v in pairs(hook.GetTable().PostPlayerDraw) do
			if type(k) == "string" then
				local kl = string.lower(k)
				if string.find(kl, "voice") or string.find(kl, "chat") or string.find(kl, "bubble") or string.find(kl, "talk") or string.find(kl, "speak") or string.find(kl, "mic") then
					hook.Remove("PostPlayerDraw", k)
				end
			end
		end
	end
	
	if hook.GetTable().PostDrawTranslucentRenderables then
		for k, v in pairs(hook.GetTable().PostDrawTranslucentRenderables) do
			if type(k) == "string" then
				local kl = string.lower(k)
				if string.find(kl, "voice") or string.find(kl, "chat") or string.find(kl, "bubble") or string.find(kl, "talk") or string.find(kl, "speak") or string.find(kl, "mic") then
					hook.Remove("PostDrawTranslucentRenderables", k)
				end
			end
		end
	end
	
	if hook.GetTable().PrePlayerDraw then
		for k, v in pairs(hook.GetTable().PrePlayerDraw) do
			if type(k) == "string" then
				local kl = string.lower(k)
				if string.find(kl, "voice") or string.find(kl, "chat") or string.find(kl, "bubble") or string.find(kl, "talk") or string.find(kl, "speak") or string.find(kl, "mic") then
					hook.Remove("PrePlayerDraw", k)
				end
			end
		end
	end
end)

local function DisableVoiceIcons()
	RunConsoleCommand("mp_show_voice_icons", "0")
end
hook.Add("Initialize", "DisableVoiceIcons", DisableVoiceIcons)
DisableVoiceIcons() -- Ejecutarlo inmediatamente también

-- El dibujado del micrófono fue movido a cl_hud2.lua para que escale en 3D
