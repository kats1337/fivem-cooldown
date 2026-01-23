identifierCooldowns = {}
cdExpireEvents = {}

---@param name string
---@param time number (in seconds)
AddCooldownForIdentifier = function(name, time)
    if identifierCooldowns[name] then
        print("Cooldown already exists for identifier: " .. name)
        print("Cooldown already exists for identifier: " .. name.. " use ExtendCooldownForIdentifier instead.")
        return false
    end
    identifierCooldowns[name] = os.time() + time

    Citizen.CreateThread(function()
        while true do
            local endTime = identifierCooldowns[name]
            if not endTime then
                break
            end

            local remaining = endTime - os.time()
            if remaining <= 0 then
                identifierCooldowns[name] = nil
                if cdExpireEvents[name] then
                    local eventData = cdExpireEvents[name]
                    TriggerEvent(eventData.event, table.unpack(eventData.args))
                    cdExpireEvents[name] = nil
                end
                break
            end

            local sleepMs = math.min(remaining, 1) * 1000
            Citizen.Wait(sleepMs)
        end
    end)

    return true
end

---@param name string
---@param time number (in seconds)
ExtendCooldownForIdentifier = function(name, time)
    if not identifierCooldowns[name] then
        print("No existing cooldown for identifier: " .. name)
        return false
    end
    identifierCooldowns[name] = identifierCooldowns[name] + time
    return true
end

---@param name string
RemoveCooldownForIdentifier = function(name)
    if not identifierCooldowns[name] then
        print("No existing cooldown for identifier: " .. name)
        return false
    end
    identifierCooldowns[name] = nil
    return true
end

---@param name string
---@return boolean
---@return number timeLeft (in seconds)
IsIdentifierOnCooldown = function(name)
    local currentTime = os.time()
    local cooldownEndTime = identifierCooldowns[name]

    if cooldownEndTime and cooldownEndTime > currentTime then
        local timeLeft = cooldownEndTime - currentTime
        return true, timeLeft
    end

    return false, 0
end

---@return table
GetAllActiveCooldowns = function()
    local currentTime = os.time()
    local activeCooldowns = {}

    for name, endTime in pairs(identifierCooldowns) do
        if endTime > currentTime then
            activeCooldowns[name] = endTime - currentTime
        end
    end

    return activeCooldowns
end

---@param name string
---@return number|nil endTime (timestamp)
---@return nil
GetCooldownEndTimeForIdentifier = function(name)
    return identifierCooldowns[name]
end

---@param name string
---@return number|nil startTime (timestamp)
---@return nil
GetCooldownStartTimeForIdentifier = function(name)
    local endTime = identifierCooldowns[name]
    if endTime then
        local duration = endTime - os.time()
        return endTime - duration
    end
    return nil
end

---@param name string
---@return number|nil duration (in seconds)
---@return nil
GetCooldownDurationForIdentifier = function(name)
    local endTime = identifierCooldowns[name]
    if endTime then
        local startTime = GetCooldownStartTimeForIdentifier(name)
        return endTime - startTime
    end
    return nil
end

exports('AddCooldownForIdentifier', function(name, time)
    local res = GetInvokingResource()
    cdExpireEvents[name] = {
        event = res..':cooldownExpired',
        args = {name},
    }
    AddCooldownForIdentifier(name, time)
end)

exports('RemoveCooldownForIdentifier', function(name)
    if cdExpireEvents[name] then
        cdExpireEvents[name] = nil
    end
    RemoveCooldownForIdentifier(name)
end)

exports('ExtendCooldownForIdentifier', ExtendCooldownForIdentifier)
exports('IsIdentifierOnCooldown', IsIdentifierOnCooldown)
exports('GetAllActiveCooldowns', GetAllActiveCooldowns)
exports('GetCooldownEndTimeForIdentifier', GetCooldownEndTimeForIdentifier)
exports('GetCooldownStartTimeForIdentifier', GetCooldownStartTimeForIdentifier)
exports('GetCooldownDurationForIdentifier', GetCooldownDurationForIdentifier)

