-- Shared data
local Persistence = Ext.Require("CombatReRandomizer/SharedData/Persistence.lua")
local RandomizerConfigData = Ext.Require("CombatReRandomizer/SharedData/RandomizerConfig.lua")
local WeightsData = Ext.Require("CombatReRandomizer/SharedData/Weights.lua")

-- Configuration
local Weights = WeightsData.Weights
local RandomizerConfig = RandomizerConfigData.RandomizerConfig

-- Utils
local BoostUtils = Ext.Require("CombatReRandomizer/Utils/BoostUtils.lua")
local MathUtils = Ext.Require("CombatReRandomizer/Utils/MathUtils.lua")

-- Json validator/converter
local JsonConverter = Ext.Require("CombatReRandomizer/UniqueEnemies/JsonValidator.lua")

local UniqueEnemiesModule = {}

local modApi = {}

-- Set up BoostUtils with the wrapped modApi
function UniqueEnemiesModule.initialize(wrappedModApi)
    modApi = wrappedModApi
    BoostUtils.initialize(wrappedModApi)
end

-- Define unique types with dictionary-based whitelist and blacklist
local UniqueTypes = {}

-- Helper functions to fetch base values for percentage calculations
local function getBaseValueForBoost(charId, boostType, boostData)
    if boostType == "TemporaryHp" then
        return modApi.GetMaxHitpoints(charId)
    elseif boostType == "Ability" then
        return modApi.GetAbility(charId, boostData.type)
    elseif boostType == "ActionResource" then
        return modApi.GetActionResourceValuePersonal(charId, boostData.type, 0)
    elseif boostType == "AC" then
        return 10
    end
    return 1
end

-- Function to calculate the final boost value based on percentage or static amount
local function calculateBoostAmount(charId, boostType, boostData)
    local globalUniquePowerScale = Weights.UniquePowerScale or 1
    if boostData.percentage then
        local baseValue = getBaseValueForBoost(charId, boostType, boostData)
        return MathUtils.mathRound(baseValue * boostData.amount * globalUniquePowerScale)
    else
        return MathUtils.mathRound(boostData.amount * globalUniquePowerScale)
    end
end

-- Function to apply boosts with support for percentage-based values
-- Example data:
--[[
"boosts": {
          "ActionResource": [
            { "type": "ActionPoint", "amount": 1, "percentage": false },
            { "type": "Movement", "amount": 3 }
          ],
          "TemporaryHp": { "amount": 50, "percentage": true },
          "Ability": [
            { "type": "Constitution", "amount": 4 },
            { "type": "Charisma", "amount": 3, "percentage": false }
          ],
          "AC": { "amount": 2, "percentage": true },
          "SpellSlot": [
            { "amount": 3, "level": 4 },
            { "amount": 1, "level": 1 }
          ]
        }
]]
local function applyBoosts(charId, boosts)
    for boostType, boostData in pairs(boosts) do
        if boostType == "ActionResource" then
            for _, resource in ipairs(boostData) do
                local finalAmount = calculateBoostAmount(charId, boostType, resource)
                BoostUtils.addBoostForChar("ActionResource(" .. resource.type .. "," .. finalAmount .. ",0)", charId)
                if RandomizerConfig.ConsoleDebug then
                    print("Giving resourses: " .. finalAmount .. " | " .. resource.type)
                end
            end
        elseif boostType == "TemporaryHp" then
            local finalAmount = calculateBoostAmount(charId, boostType, boostData)
            BoostUtils.addBoostForChar("TemporaryHP(" .. finalAmount .. ")", charId)
        elseif boostType == "Ability" then
            for _, ability in ipairs(boostData) do
                local finalAmount = calculateBoostAmount(charId, boostType, ability)
                BoostUtils.addBoostForCharWithPersistence("Ability(" .. ability.type .. "," .. finalAmount .. ")", charId)
                if RandomizerConfig.ConsoleDebug then
                    print("Giving abilities: " .. finalAmount .. " | " .. ability.type)
                end
            end
        elseif boostType == "AC" then
            local finalAmount = calculateBoostAmount(charId, boostType, boostData)
            BoostUtils.addBoostForCharWithPersistence("AC(" .. finalAmount .. ")", charId)
            if RandomizerConfig.ConsoleDebug then
                print("Giving AC: " .. finalAmount)
            end
        elseif boostType == "SpellSlot" then
            for _, spellSlot in ipairs(boostData) do
                local spellSlotLevel = spellSlot.level or 1
                local spellSlotAmount = spellSlot.amount or 1
                BoostUtils.addBoostForChar(
                    "ActionResource(SpellSlot," .. spellSlotAmount .. "," .. spellSlotLevel .. ")", charId)
                if RandomizerConfig.ConsoleDebug then
                    print("Giving Spell Slots: " .. spellSlotAmount .. " | level: " .. spellSlotLevel)
                end
            end
        end
    end
end

-- Function to apply statuses for given duration (in turns, 6 seconds each)
-- Example data:
--[[
"statuses": [
          { "type": "GiantKiller", "duration": 8 },
          { "type": "ColossusSlayer" }
        ]
]]
local function applyStatuses(charId, statuses)
    for _, status in ipairs(statuses) do
        if status.type then
            local duration = (status.duration and status.duration * 6) or -1
            modApi.ApplyStatus(charId, status.type, duration)
        end
    end
end


-- Function to give spells
-- Example data:
--[[
"spells": [
          { "spell": "Projectile_MagicMissile", "casts": 3 },
          { "spell": "Shout_Blur" }
        ]
]]
local function giveSpells(charId, spells)
    
end

-- Function to apply a single unique type (buffs, boosts etc.) to a character
local function applyUniqueType(charId, uniqueTypeToApply)
    local uniqueType = UniqueTypes[uniqueTypeToApply]
    if uniqueType then
        applyBoosts(charId, uniqueType.boosts)
        applyStatuses(charId, uniqueType.statuses)
        giveSpells(charId, uniqueType.spells)
    end
end

-- Function to check if a type is compatible with the current unique types on the character
local function isTypeCompatible(newType, currentTypes)
    local newTypeData = UniqueTypes[newType]

    if newTypeData.blacklist and next(newTypeData.blacklist) then
        for _, currentType in ipairs(currentTypes) do
            if newTypeData.blacklist[currentType] then
                if RandomizerConfig.ConsoleExtraDebug then
                    print("Incompatible due to blacklist: " .. newType .. " cannot be combined with " .. currentType)
                end
                return false
            end
        end
    end

    for _, currentType in ipairs(currentTypes) do
        local currentTypeData = UniqueTypes[currentType]
        if currentTypeData.whitelist and next(currentTypeData.whitelist) then
            if not currentTypeData.whitelist[newType] then
                if RandomizerConfig.ConsoleExtraDebug then
                    print("Incompatible due to whitelist: " .. currentType .. " does not allow " .. newType)
                end
                return false
            end
        end
    end

    return true
end

-- Weighted selection function
local function getRandomUniqueType(currentUniqueTypes)
    local availableTypes = {}
    for uniqueType, uniqueData in pairs(UniqueTypes) do
        if isTypeCompatible(uniqueType, currentUniqueTypes) then
            for i = 1, uniqueData.weight do
                table.insert(availableTypes, uniqueType)
            end
        end
    end

    if #availableTypes == 0 then
        return nil
    end

    return availableTypes[math.random(#availableTypes)]
end

-- Function to apply multiple unique modifiers to a character, with compatibility tracking
function UniqueEnemiesModule.applyUniqueModifiers(charId)
    local uniqueModifiersApplied = 0
    local currentUniques = {}

    while uniqueModifiersApplied < RandomizerConfig.MaxUniqueModifiers do
        if MathUtils.isLessThanRandom(RandomizerConfig.Uniques) then
            break
        end
        local selectedType = getRandomUniqueType(currentUniques)

        if not selectedType then
            break
        end

        if RandomizerConfig.ConsoleDebug then
            print("----- Uniques module -----")
            print("Applying| " .. selectedType .. " |unique modifier to character " .. charId)
        end
        applyUniqueType(charId, selectedType)

        table.insert(currentUniques, selectedType)
        uniqueModifiersApplied = uniqueModifiersApplied + 1
    end
    if uniqueModifiersApplied > 0 and RandomizerConfig.ConsoleDebug then
        print("-------------------------")
    end

    return currentUniques
end

function UniqueEnemiesModule.parseUniques(uniquesJson)
    local uniqueTypes = JsonConverter(uniquesJson)

    -- Assign to UniqueTypes if it is successfully converted
    if uniqueTypes then
        UniqueTypes = uniqueTypes
    else
        print("Failed to parse unique types from JSON.")
    end
end

return UniqueEnemiesModule
