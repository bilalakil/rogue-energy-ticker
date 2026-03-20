local ENERGY_TICK_INTERVAL = 2
local EXPECTED_ENERGY_GAINED = 20

RogueEnergyTicker = CreateFrame("Frame", "RogueEnergyTickerFrame", UIParent)

RogueEnergyTicker:SetScript("OnEvent", function (_, event, ...)
    local handler = RogueEnergyTicker[event]
    if handler then
        handler(RogueEnergyTicker, ...)
    end
end)
RogueEnergyTicker:RegisterEvent("ADDON_LOADED")

function RogueEnergyTicker:ADDON_LOADED(addonName)
    if addonName ~= "RogueEnergyTicker" then
        return
    end

    self.TRACE = false
    self:RegisterEvent("PLAYER_LOGIN")
end

function RogueEnergyTicker:PLAYER_LOGIN()
    if UnitPowerType("player") ~= Enum.PowerType.Energy then
        self:Trace("Aborting initialization, player doesn't use energy.")
        return
    end

    self:Trace("Initializing...")

    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:SetScript("OnUpdate", self.Update)

    self.lastEnergy = UnitPower("player", Enum.PowerType.Energy)
    self.lastGainedEnergyTime = 0
    self:GUIBuild()
    
    self:Trace("Initialization complete.")
end

function RogueEnergyTicker:UNIT_POWER_UPDATE(unit, powerType)
    if unit ~= "player" or powerType ~= "ENERGY" then return end

    local currentEnergy = UnitPower("player", Enum.PowerType.Energy)
    local delta = currentEnergy - self.lastEnergy
    self:Trace("Energy updated, from", self.lastEnergy, "to", currentEnergy, ", delta:", delta)

    if delta == 20 or delta == 21 or delta >= 40 then
        self.lastGainedEnergyTime = GetTime()
    end

    self.lastEnergy = currentEnergy
end

function RogueEnergyTicker:Update()
    if not self.spark then return end

    local elapsed = (GetTime() - self.lastGainedEnergyTime) % ENERGY_TICK_INTERVAL
    local pct = elapsed / ENERGY_TICK_INTERVAL

    local barWidth = PlayerFrameManaBar:GetWidth()
    local xOffset = pct * barWidth
    self.spark:SetPoint("CENTER", PlayerFrameManaBar, "LEFT", xOffset, 0)
end

function RogueEnergyTicker:Print(...)
    print("|cff33ff99RogueEnergyTicker:|r", ...)
end

function RogueEnergyTicker:Trace(...)
    if self.TRACE then
        self:Print(...)
    end
end

function RogueEnergyTicker:GUIBuild()
    if not PlayerFrameManaBar then
        self:Trace("PlayerFrameManaBar not found, cannot create energy ticker.")
        return
    end

    local sparkFrame = CreateFrame("Frame", nil, PlayerFrameManaBar)
    sparkFrame:SetFrameStrata(PlayerFrameManaBar:GetFrameStrata())
    sparkFrame:SetFrameLevel(PlayerFrameManaBar:GetFrameLevel() + 10)
    sparkFrame:SetSize(20, 32)
    sparkFrame:SetPoint("CENTER", PlayerFrameManaBar, "CENTER", 0, 0)

    local sparkTexture = sparkFrame:CreateTexture(nil, "OVERLAY")
    sparkTexture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    sparkTexture:SetBlendMode("ADD")
    sparkTexture:SetAllPoints()

    self.spark = sparkFrame
end