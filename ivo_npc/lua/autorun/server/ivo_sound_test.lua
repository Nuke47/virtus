hook.Add("PlayerSay", "TestSoundIvo", function(ply, text)
    if text == "!testsound" then
        ply:EmitSound("npcs/voice/b1/acaben.wav", 75, 100)
        ply:ChatPrint("Playing sound...")
    end
end)
