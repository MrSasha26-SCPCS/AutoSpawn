local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

-- Local functions
local function getIndex(tab, val)
    for i, value in ipairs(tab) do
        if value == val then
            return i
        end
    end
    return -1
end
--

---@class AutoSpawn:CS.Akequ.Base.Room
AutoSpawn = {}

AutoSpawn.time = 60
AutoSpawn.isRoundBlocked = false
AutoSpawn.isRoundStarted = false

AutoSpawn.justConnected = {}

function AutoSpawn:Init()
    if self.main.netEvent.isServer then
        CS.HookManager.Add(self.main.netEvent.gameObject, "changeLockRoundState", function(obj)
            self.isRoundBlocked = obj[0]
        end)
        CS.HookManager.Add(self.main.netEvent.gameObject, "onRoundStart", function(obj)
            self.isRoundStarted = true
        end)
        CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerCreated", function(obj)
            if obj[0] == nil or not self.isRoundStarted then return end
            table.insert(self.justConnected, obj[0])
        end)
    elseif self.main.netEvent.isClient then
        CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerSetClass", function(obj)
            local ply = obj[0]
            if ply == nil then return end
            if ply == CS.PlayerUtilities.GetLocalPlayer() then
                self.main:SendToServer("SetAsClassD")
            end
        end)
    end
end

function AutoSpawn:Update()
    if self.main.netEvent.isServer and self.time > 0 and self.isRoundStarted then
        self.time = self.time - CS.UnityEngine.Time.deltaTime
    end
end

-- SERVER
function AutoSpawn:SetAsClassD(conn)
    if conn == nil then return end

    local player = CS.PlayerUtilities.GetServerPlayer(conn)

    local index = getIndex(self.justConnected, player)

    if self.time > 0 and not self.isRoundBlocked and index ~= -1 then
        table.remove(self.justConnected, index)
        player:SetClass("ClassD")
    end
end

return AutoSpawn