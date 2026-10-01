-- ============================================================================
-- IVOSAM: SISTEMA DE VOTACIONES (SERVIDOR)
-- ============================================================================

IVO_SAM = IVO_SAM or {}
IVO_SAM.CurrentVote = nil

util.AddNetworkString("IVO_Vote_Start")
util.AddNetworkString("IVO_Vote_End")
util.AddNetworkString("IVO_Vote_Cast")
util.AddNetworkString("IVO_Vote_Result")

function IVO_SAM.StartVote(title, options)
    if IVO_SAM.CurrentVote then return end

    local dur = 20
    IVO_SAM.CurrentVote = {
        title = title,
        options = options,
        votes = {},
        voters = {},
        endTime = CurTime() + dur
    }

    for i = 1, #options do
        IVO_SAM.CurrentVote.votes[i] = 0
    end

    net.Start("IVO_Vote_Start")
        net.WriteString(title)
        net.WriteTable(options)
        net.WriteFloat(dur)
    net.Broadcast()

    timer.Create("IVO_SAM_VoteTimer", dur, 1, function()
        IVO_SAM.EndVote()
    end)
end

function IVO_SAM.EndVote()
    if not IVO_SAM.CurrentVote then return end

    local maxVotes = -1
    local winnerIndex = 0
    local tie = false
    local totalVotes = 0

    for i, count in ipairs(IVO_SAM.CurrentVote.votes) do
        totalVotes = totalVotes + count
        if count > maxVotes then
            maxVotes = count
            winnerIndex = i
            tie = false
        elseif count == maxVotes then
            tie = true
        end
    end

    local title = IVO_SAM.CurrentVote.title
    local resultStr = ""
    local winStr = ""
    local isTie = false

    if tie or totalVotes == 0 then
        isTie = true
        resultStr = "La votación ha terminado en empate o sin votos."
    else
        winStr = IVO_SAM.CurrentVote.options[winnerIndex]
        resultStr = "(" .. maxVotes .. "/" .. totalVotes .. " votos)"
    end

    net.Start("IVO_Vote_End")
    net.Broadcast()

    net.Start("IVO_Vote_Result")
        net.WriteString(title)
        net.WriteBool(isTie)
        net.WriteString(winStr)
        net.WriteString(resultStr)
    net.Broadcast()

    IVO_SAM.CurrentVote = nil
end

net.Receive("IVO_Vote_Cast", function(len, ply)
    if not IVO_SAM.CurrentVote then return end
    if IVO_SAM.CurrentVote.voters[ply] then return end -- Ya votó

    local optionIndex = net.ReadUInt(4)
    if not IVO_SAM.CurrentVote.options[optionIndex] then return end

    IVO_SAM.CurrentVote.voters[ply] = true
    IVO_SAM.CurrentVote.votes[optionIndex] = IVO_SAM.CurrentVote.votes[optionIndex] + 1
end)
