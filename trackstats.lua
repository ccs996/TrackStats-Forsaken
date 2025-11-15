-- FORSAKEN BOT TRACKSTATS v1.0
-- Works on any executor | Multi-bot safe
-- Author: CCS996

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerName = LocalPlayer.Name
local StartTime = tick()

-- === CONFIG ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/1434019048877981838/DpJNfhP6Ok2JtuO5DK5y9IWm1Id5tjISRO-W6iF0OW903REsaWCjgZn-JbgzINRxW1bb"  -- PUT YOUR WEBHOOK
local UPDATE_INTERVAL = 300  -- Send stats every 5 mins (300 sec)
local SAVE_TO_FILE = true    -- Save stats to .txt file
local STATS_FILE = "forsaken_stats_" .. PlayerName .. ".txt"

-- === STATS TABLE ===
local Stats = {
    Kills = 0,
    Deaths = 0,
    Wins = 0,
    Headshots = 0,
    CashEarned = 0,
    Playtime = 0
}

-- Load saved stats if exist
if SAVE_TO_FILE and isfile and readfile and isfile(STATS_FILE) then
    local success, loaded = pcall(function()
        return HttpService:JSONDecode(readfile(STATS_FILE))
    end)
    if success and loaded then
        Stats = loaded
        print("[TRACKSTATS] Loaded saved stats for " .. PlayerName)
    end
end

-- === SAVE STATS FUNCTION ===
local function saveStats()
    if SAVE_TO_FILE and writefile then
        writefile(STATS_FILE, HttpService:JSONEncode(Stats))
    end
end

-- === SEND TO DISCORD ===
local function sendToDiscord()
    Stats.Playtime = math.floor(tick() - StartTime)
    
    local data = {
        username = "Forsaken Bot Tracker",
        avatar_url = "https://i.imgur.com/YourIcon.png",
        embeds = {{
            title = "🤖 Bot Stats Update - " .. PlayerName,
            color = 0x00ff00,
            fields = {
                { name = "Kills", value = tostring(Stats.Kills), inline = true },
                { name = "Deaths", value = tostring(Stats.Deaths), inline = true },
                { name = "K/D", value = Stats.Deaths > 0 and string.format("%.2f", Stats.Kills / Stats.Deaths) or "INF", inline = true },
                { name = "Wins", value = tostring(Stats.Wins), inline = true },
                { name = "Headshots", value = tostring(Stats.Headshots), inline = true },
                { name = "Cash Earned", value = tostring(Stats.CashEarned), inline = true },
                { name = "Playtime", value = string.format("%d min", Stats.Playtime // 60), inline = true }
            },
            footer = { text = "Updated: " .. os.date("%H:%M:%S") }
        }}
    }

    pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
end

-- === TRACK KILLS (listen to humanoid death) ===
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")

    humanoid.Died:Connect(function()
        -- Check if we killed them
        local killer = humanoid:FindFirstChild("Creator")
        if killer and killer.Value == LocalPlayer then
            Stats.Kills = Stats.Kills + 1
            -- Check headshot
            if humanoid:FindFirstChild("Headshot") then
                Stats.Headshots = Stats.Headshots + 1
            end
            saveStats()
            print("[KILL] " .. player.Name .. " | Total Kills: " .. Stats.Kills)
        end
    end)
end

-- === TRACK DEATHS ===
LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        Stats.Deaths = Stats.Deaths + 1
        saveStats()
        print("[DEATH] You died | Total Deaths: " .. Stats.Deaths)
    end)
end)

-- === TRACK WINS (Forsaken-specific - adjust if needed) ===
-- Usually a RemoteEvent or GUI says "Victory"
spawn(function()
    while wait(5) do
        pcall(function()
            local gui = LocalPlayer:WaitForChild("PlayerGui")
            if gui:FindFirstChild("VictoryScreen") or gui:FindFirstChild("WinGui") then
                Stats.Wins = Stats.Wins + 1
                saveStats()
                print("[WIN] Victory! Total Wins: " .. Stats.Wins)
                wait(10) -- prevent double count
            end
        end)
    end
end)

-- === TRACK CASH (adjust path to your currency) ===
spawn(function()
    while wait(10) do
        pcall(function()
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
                if cash and cash.Value > (Stats.CashEarned or 0) then
                    Stats.CashEarned = cash.Value
                    saveStats()
                end
            end
        end)
    end
end)

-- === AUTO SEND TO DISCORD ===
spawn(function()
    while wait(UPDATE_INTERVAL) do
        sendToDiscord()
        saveStats()
    end
end)

-- === ON JOIN SETUP ===
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Final save on leave
game:BindToClose(function()
    Stats.Playtime = math.floor(tick() - StartTime)
    saveStats()
    sendToDiscord()
end)

print("[TRACKSTATS] Loaded for " .. PlayerName .. " | Webhook: " .. (WEBHOOK_URL ~= "" and "ON" or "OFF"))
