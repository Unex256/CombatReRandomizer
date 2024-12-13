local Persistence = Ext.Require("CombatReRandomizer/SharedData/Persistence.lua")

local BoostUtils = {}

local modApi = {}

-- Set up BoostUtils with the wrapped modApi
function BoostUtils.initialize(wrappedModApi)
    modApi = wrappedModApi  -- Store the reference to modApi in a local variable
end

-- Function to add a boost with persistence tracking
function BoostUtils.addBoostForCharWithPersistence(boostStr, charId)
    modApi.AddBoosts(charId, boostStr, "", "ReRandomizer")
    if Persistence.characterBoosts[charId] then
        table.insert(Persistence.characterBoosts[charId], boostStr)
    else
        Persistence.characterBoosts[charId] = { boostStr }
    end
end

-- Function to add a boost without persistence
function BoostUtils.addBoostForChar(boostStr, charId)
    modApi.AddBoosts(charId, boostStr, "", "ReRandomizer")
end

-- Return the BoostUtils module
return BoostUtils
