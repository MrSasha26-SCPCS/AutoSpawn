local GameObject = CS.UnityEngine.GameObject
local Time = CS.UnityEngine.Time
local Color = CS.UnityEngine.Color
local Vector2 = CS.UnityEngine.Vector2
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

---@class WaitingPVP:CS.Akequ.Base.Room
WaitingPVP = {}

WaitingPVP.sent = false
WaitingPVP.time = 0
WaitingPVP.update_time = 1
WaitingPVP.shown = {}

function WaitingPVP:Init()
    if self.main.netEvent.isServer then
        CS.HookManager.Run("changeLockRoundState", true)
        CS.HookManager.Run("onLCZState", true)
        CS.Config.SetConfig("friendly_fire", true)

        local sm = GameObject.FindObjectOfType(typeof(CS.SupportManager))
        if sm ~= nil then 
            GameObject.Destroy(sm)                
        end

        local players = GameObject.FindObjectsOfType(typeof(CS.Player))
        for i = 0, players.Length - 1 do
            local player = players[i]
            if player ~= nil then
                self:SetPlayer(player)
            end
        end
        self:ClearItemsOnMap()
        
        CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerDeath", function(obj)
            local deathPly = obj[0]
            local killer = obj[1].killer

            if killer ~= nil then
                killer.health = killer.maxHealth
                killer:UpdateHealth()
            end
        end)
        CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerCreated", function(obj)
            if GameObject.FindObjectsOfType(typeof(CS.Player)).Length >= CS.Config.GetInt("quit_pvp_minimum_players", 8) then
                GameObject.FindObjectOfType(typeof(CS.AdminPanel)):ShowAdminMessage("Нужное количество игроков достигнуто! Перезапуск раунда...", 3)
                self.main:Invoke(function() CS.HookManager.Run("RestartRoundAP") end, 2)
            end
        end)
    elseif self.main.netEvent.isClient then
        CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerSetClass", function(obj)
            local ply = obj[0]

            if ply == CS.PlayerUtilities.GetLocalPlayer() then
                if ply.playerClass == nil then return end
                if ply.playerClass:GetType().Name ~= "Spectator" then return end

                self.main:SendToServer("SetPlayer", CS.PlayerUtilities.GetLocalPlayer())
            end
        end)
    end
end

function WaitingPVP:Update()
    if self.main.netEvent.isServer then        
        self.update_time = self.update_time - Time.deltaTime
        if self.update_time <= 0 then
            self.update_time = 1
            self:PluginUpdate()
        end
    end
end

function WaitingPVP:PluginUpdate()
    self.time = self.time - 1
    if self.time <= 0 then
        self.time = 30
        self:GivePatrons()
        self:ClearItemsOnMap()
    end
end

function WaitingPVP:ClearItemsOnMap()
    local items = GameObject.FindObjectsOfType(typeof(CS.ItemPickup))
    for i = 0, items.Length - 1 do
        local item = items[i]
        if item ~= nil and item.gameObject ~= nil then
            GameObject.Destroy(item.gameObject)
        end
    end
end

function WaitingPVP:SetPlayer(player)
    if player ~= nil then
        player:SetClass("PVPClass")

        if getIndex(self.shown, player) ~= -1 then return 
        else table.insert(self.shown, player) end

        if GameObject.FindObjectsOfType(typeof(CS.Player)).Length < CS.Config.GetInt("quit_pvp_minimum_players", 8) then
            GameObject.FindObjectOfType(typeof(CS.AdminPanel)):ShowAdminMessage("Ожидание нужного количества игроков для начала раунда (" .. CS.Config.GetInt("quit_pvp_minimum_players", 8) .. ")", 5, player)
        end
    end
end

function WaitingPVP:GivePatrons()
    local players = GameObject.FindObjectsOfType(typeof(CS.Player))
    for i = 0, players.Length - 1 do
        local player = players[i]
        player:SetAvailAmmo("545x39", 120)
        player:SetAvailAmmo("556x45", 120)
        player:SetAvailAmmo("762x39", 120)
        player:SetAvailAmmo("9x19", 100)
    end
end

return WaitingPVP