concommand.Add("rollthedice", function(ply)

    local number = math.random(1,100)

    for _, v in ipairs(player.GetAll()) do

        v:SendLua([[chat.AddText(
            Color(255,255,255),
            "]] .. ply:Nick() .. [[ roleó ",
            Color(0,150,255),
            "]] .. number .. [[",
            Color(255,255,255),
            "."
        )]])

    end

end)

function RollCommand(pl, text, teamonly)

    if text == "/roll" then

        pl:ConCommand("rollthedice")
        return ""

    end

end

hook.Add("PlayerSay", "Chat", RollCommand)