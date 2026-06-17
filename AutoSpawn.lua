local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

local function FindInactiveObj(name)
    local objs = CS.UnityEngine.Resources.FindObjectsOfTypeAll(typeof(GameObject))
    for i = 0, objs.Length - 1 do
        local obj = objs[i]
        if obj.name == name then
            return obj
        end
    end
    return nil
end

---@class AutoSpawn:CS.Akequ.Base.Room
AutoSpawn = {}

AutoSpawn.time = 60
AutoSpawn.isRoundBlocked = false
AutoSpawn.isRoundStarted = false

function AutoSpawn:Init()
    if self.main.netEvent.isServer then
        CS.HookManager.Add(self.main.netEvent.gameObject, "changeLockRoundState", function(obj)
            self.isRoundBlocked = obj[0]
        end)
        CS.HookManager.Add(self.main.netEvent.gameObject, "onRoundStart", function(obj)
            self.isRoundStarted = true
        end)
        CS.HookManager.Add("onPlayerCreated", function(obj)
            local player = obj[0]
            if player ~= nil and self.time > 0 and not self.isRoundBlocked and self.isRoundStarted then
                self.main:Invoke(function() player:SetClass("ClassD") end, 0.2)
            end
        end)
    end
end

function AutoSpawn:Update()
    if self.main.netEvent.isServer and self.time > 0 then
        self.time = self.time - CS.UnityEngine.Time.deltaTime
    end
end

return AutoSpawn