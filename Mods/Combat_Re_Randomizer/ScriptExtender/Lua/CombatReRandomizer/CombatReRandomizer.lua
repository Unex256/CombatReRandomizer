local BaseRandomizablesList = Ext.Require("CombatReRandomizer/StaticData/BaseRandomizableLists.lua")
local StaticLists = Ext.Require("CombatReRandomizer/StaticData/StaticLists.lua")

local UniqueEnemiesModule = Ext.Require("CombatReRandomizer/UniqueEnemies/UniqueEnemies.lua")

-- Base user interactable files
local baseConfig = Ext.Require("CombatReRandomizer/StaticData/ReRandomizerBaseConfig.lua")
local baseWeightsFile = Ext.Require("CombatReRandomizer/StaticData/ReRandomizerBaseWeights.lua")
local baseModdedFile = Ext.Require("CombatReRandomizer/StaticData/ReRandomizerBaseModdedItems.lua")
local baseUniquesFile = Ext.Require("CombatReRandomizer/StaticData/ReRandomizerBaseUniques.lua")

-- Utils
local ApiWrapper = Ext.Require("CombatReRandomizer/Utils/ApiWrapper.lua")
local BoostUtils = Ext.Require("CombatReRandomizer/Utils/BoostUtils.lua")
local MathUtils = Ext.Require("CombatReRandomizer/Utils/MathUtils.lua")

-- Shared data
local Persistence = Ext.Require("CombatReRandomizer/SharedData/Persistence.lua")
local RandomizerConfigData = Ext.Require("CombatReRandomizer/SharedData/RandomizerConfig.lua")
local WeightsData = Ext.Require("CombatReRandomizer/SharedData/Weights.lua")

-- Configuration
local Weights = WeightsData.Weights
local RandomizerConfig = RandomizerConfigData.RandomizerConfig

-- Statics
local OriginChracters = nil
local RandomizablesLists = BaseRandomizablesList

-- Event and runtime locality
local unprocessedItemTemplates = {}

-- Wrapped Api methods
local modApi = {}

-- Persistence: Local lists
local randomizedNpcs = Persistence.randomizedNpcs
local characterItems = Persistence.characterItems
local characterBoosts = Persistence.characterBoosts
local characterSpells = Persistence.characterSpells
local spellsAddedToParty = Persistence.spellsAddedToParty
local combatVisitors = Persistence.combatVisitors
local namePrefixes = Persistence.namePrefixes
local uniqueProperties = Persistence.uniqueProperties

-- Persistence: Modvars
local reRandomizerUUID = "28040579-aead-4e01-aa9c-6371ab131e9d";
Ext.Vars.RegisterModVariable(reRandomizerUUID, "randomized_npcs", {});   -- Randomized npcs tracker.
Ext.Vars.RegisterModVariable(reRandomizerUUID, "character_items", {});   -- Randomized loot tracker.
Ext.Vars.RegisterModVariable(reRandomizerUUID, "character_boosts", {});  -- Randomized boosts tracker.
Ext.Vars.RegisterModVariable(reRandomizerUUID, "character_spells", {});  -- Randomized spells tracker.
Ext.Vars.RegisterModVariable(reRandomizerUUID, "party_spells", {});      -- Randomized spells added to party tracker.
Ext.Vars.RegisterModVariable(reRandomizerUUID, "combat_visitors", {});   -- Party Characters that have already visited specific combat.
Ext.Vars.RegisterModVariable(reRandomizerUUID, "name_prefixes", {});     -- Added name prefixes.
Ext.Vars.RegisterModVariable(reRandomizerUUID, "unique_properties", {}); -- Characters with unique properties.

local function getModvars()
    local modvars = Ext.Vars.GetModVariables(reRandomizerUUID)
    local keys = {
        "randomized_npcs",
        "character_items",
        "character_boosts",
        "character_spells",
        "party_spells",
        "combat_visitors",
        "name_prefixes",
        "unique_properties"
    }

    for _, key in ipairs(keys) do
        if modvars[key] == nil then
            modvars[key] = {}
        end
    end

    return modvars
end

local function parseGuid(string)
    return string.sub(string, -36)
end

local function parseStringFromGuid(string)
    local modifiedString = string.sub(string, 1, -37)
    modifiedString = string.gsub(modifiedString, "[-_]$", "")
    return modifiedString
end


local function resetModdedItemsFile()
    Ext.IO.SaveFile("CombatReRandomizerModdedItems.json", baseModdedFile)
    print("Combat ReRandomizer - Making modded items file.")
end

local function addItemsFromJson(sourceTable, targetList, label)
    for _, item in ipairs(sourceTable) do
        print("Combat ReRandomizer - adding modded " .. label .. ": " .. item)
        table.insert(targetList, item)
    end
end

local function getModdedStuffFromFile()
    local moddedItems = Ext.IO.LoadFile("CombatReRandomizerModdedItems.json")
    if (moddedItems) then
        local itemsJson = Ext.Json.Parse(moddedItems)
        addItemsFromJson(itemsJson["Spells"], RandomizablesLists.Spells, "Spells")
        addItemsFromJson(itemsJson["Armor"], RandomizablesLists.Armor, "Armor")
        addItemsFromJson(itemsJson["Gloves"], RandomizablesLists.Gloves, "Gloves")
        addItemsFromJson(itemsJson["Helmets"], RandomizablesLists.Helmets, "Helmets")
        addItemsFromJson(itemsJson["Shields"], RandomizablesLists.Shields, "Shields")
        addItemsFromJson(itemsJson["Cloaks"], RandomizablesLists.Cloaks, "Cloaks")
        addItemsFromJson(itemsJson["Boots"], RandomizablesLists.Boots, "Boots")
        addItemsFromJson(itemsJson["Rings"], RandomizablesLists.Rings, "Rings")
        addItemsFromJson(itemsJson["Amulets"], RandomizablesLists.Amulets, "Amulets")
        addItemsFromJson(itemsJson["Consumables"], RandomizablesLists.Consumables, "Consumables")
        addItemsFromJson(itemsJson["Weapons"], RandomizablesLists.Weapons, "Weapons")
        addItemsFromJson(itemsJson["Statuses"], RandomizablesLists.Statuses, "Statuses")
        addItemsFromJson(itemsJson["NegativeStatuses"], RandomizablesLists.NegativeStatuses, "NegativeStatuses")
    else
        resetModdedItemsFile()
    end
end

local function resetConfigFile()
    Ext.IO.SaveFile("CombatReRandomizerConfig.json", baseConfig)
end

local function resetWeightsFile()
    Ext.IO.SaveFile("CombatReRandomizerWeights.json", baseWeightsFile)
end

local function resetUniquesFile()
    Ext.IO.SaveFile("CombatReRandomizerUniques.json", baseUniquesFile)
end

local function getConfigFromFile()
    local config = Ext.IO.LoadFile("CombatReRandomizerConfig.json")
    if config then
        local configJson = Ext.Json.Parse(config)
        RandomizerConfigData.assignRandomizerConfigValues(configJson)
    else
        print("Combat ReRandomizer - Configuration file not found. Creating one.")
        resetConfigFile()
        getConfigFromFile()
    end
end

local function getWeightsFromFile()
    local weights = Ext.IO.LoadFile("CombatReRandomizerWeights.json")
    if weights then
        local weightsJson = Ext.Json.Parse(weights)
        WeightsData.assignRandomizerWeights(weightsJson)
    else
        print("Combat ReRandomizer - Weights file not found. Creating one.")
        resetWeightsFile()
        getWeightsFromFile()
    end
end

local function getUniquesFromFile()
    local uniques = Ext.IO.LoadFile("CombatReRandomizerUniques.json")
    if uniques then
        local uniquesJson = Ext.Json.Parse(uniques)
        UniqueEnemiesModule.parseUniques(uniquesJson)
    else
        print("Combat ReRandomizer - Uniques file not found. Creating one.")
        resetUniquesFile()
        getUniquesFromFile()
    end
end

-- Helper function to check if a table contains a specific element
local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function split(input, separator)
    local result = {}
    for match in (input .. separator):gmatch("(.-)" .. separator) do
        table.insert(result, match)
    end
    return result
end

-- Stats:

-- Spells
local function getSpellContainer(spell)
    local spellData = Ext.Stats.Get(spell, nil, false)
    if spellData and spellData.SpellContainerID ~= "" then
        if RandomizerConfig.ConsoleExtraDebug then
            print("Spell has a container: " .. spellData.SpellContainerID)
        end
        return spellData.SpellContainerID
    end
    return "" -- Return an empty string if there's no container or spell doesn't exist
end

-- Function to check if a spell is a root spell
local function getRootSpell(spell)
    local spellData = Ext.Stats.Get(spell, nil, false)
    if spellData and (not spellData.RootSpellID or spellData.RootSpellID == "") then
        if RandomizerConfig.ConsoleExtraDebug then
            print("Spell is a root spell: " .. spell)
        end
        return true
    end
    return false -- Returns false if it's not a root spell or spell doesn't exist
end

-- Helper function to check if a functor has summoning properties
local function isSummoningProperty(functor)
    return functor.TypeId == "Summon" or functor.TypeId == "Spawn"
end


-- Helper function to check if any of the spell's properties meet summoning conditions
local function hasSummoningProperties(spellData)
    if spellData and spellData.SpellProperties then
        for _, property in pairs(spellData.SpellProperties) do
            if property.Functors then
                for _, functor in pairs(property.Functors) do
                    if isSummoningProperty(functor) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Main function to check if a spell or any of its container spells are summoning spells
local function isSummoningSpell(spell)
    local spellData = Ext.Stats.Get(spell)

    -- Step 1: Check the main spell for summoning properties
    if hasSummoningProperties(spellData) then
        return true
    end

    -- Step 2: If the spell is a container, check each contained spell
    if spellData and spellData.ContainerSpells then
        -- Split the "ContainerSpells" string into individual spells
        local containerSpells = split(spellData.ContainerSpells, ";")
        for _, containedSpell in ipairs(containerSpells) do
            local containedSpellData = Ext.Stats.Get(containedSpell)
            if hasSummoningProperties(containedSpellData) then
                return true
            end
        end
    end

    return false
end

local function reApplyNonPersistentBoosts()
    for charId, boosts in pairs(characterBoosts) do
        for _, boost in ipairs(boosts) do
            BoostUtils.addBoostForChar(boost, charId)
        end
    end
end

local function reApplyDisplayNames()
    for charId, prefixes in pairs(namePrefixes) do
        local currentName = Ext.Loca.GetTranslatedString(modApi.GetDisplayName(charId))

        -- Concatenate all prefixes into a single string
        local combinedPrefixes = table.concat(prefixes, " ")
        local newName = combinedPrefixes .. " " .. currentName

        modApi.SetStoryDisplayName(charId, newName)
    end
end

local function addItemToCharacterItemList(itemId, charId)
    if not characterItems[charId] then
        characterItems[charId] = {}
    end
    characterItems[charId][itemId] = true
end


-- Process and deduplicate spells, replacing them with container spells or root spells if applicable
local function processRandomizableSpells()
    -- Replace spells with container or root spells
    for i, spell in ipairs(RandomizablesLists.Spells) do
        local containerSpell = getSpellContainer(spell)
        if containerSpell and containerSpell ~= "" then
            RandomizablesLists.Spells[i] = containerSpell -- Replace with container spell
        elseif getRootSpell(spell) then
            RandomizablesLists.Spells[i] = spell          -- Keep only if it's a root spell
        end
    end

    -- Deduplicate the list
    local uniqueSpells = {}
    local deduplicatedList = {}
    for _, spell in ipairs(RandomizablesLists.Spells) do
        if not uniqueSpells[spell] then
            uniqueSpells[spell] = true
            table.insert(deduplicatedList, spell)
        end
    end

    if RandomizerConfig.ConsoleExtraDebug then
        print(#deduplicatedList .. " unique spells are ready to be randomized")
    end
    -- Replace the original list with the deduplicated list
    RandomizablesLists.Spells = deduplicatedList
end

local function processRandomizablesList()
    processRandomizableSpells()
end

local function onSessionLoaded()
    print("CombatReRandomizer ver. 0.7.1 initialization")
    ApiWrapper.initializeModApi(modApi)
    BoostUtils.initialize(modApi)
    UniqueEnemiesModule.initialize(modApi)

    local modvars = getModvars()
    randomizedNpcs = modvars.randomized_npcs
    characterItems = modvars.character_items
    characterBoosts = modvars.character_boosts
    combatVisitors = modvars.combat_visitors
    namePrefixes = modvars.name_prefixes
    spellsAddedToParty = modvars.party_spells

    getConfigFromFile()
    getModdedStuffFromFile()
    getWeightsFromFile()
    getUniquesFromFile()
    processRandomizablesList()
end

local function onLevelGameplayStarted()
    reApplyNonPersistentBoosts()
    reApplyDisplayNames()
end

local function getRandomItemFromList(list)
    if #list == 0 then
        if RandomizerConfig.ConsoleExtraDebug then
            print("List lenght is 0, something is wrong!")
        end
        return nil
    end
    local randomIndex = MathUtils.random(1, #list)
    return list[randomIndex]
end

local function addNamePrefix(prefix, charId)
    -- Retrieve existing prefixes for the character, if any
    local existingPrefixes = namePrefixes[charId] or {}

    -- Concatenate all existing prefixes
    local combinedPrefixes = table.concat(existingPrefixes, " ")

    -- Get the current display name
    local currentName = Ext.Loca.GetTranslatedString(modApi.GetDisplayName(charId))

    -- Construct the new display name by adding the new prefix and existing prefixes
    local newName
    if combinedPrefixes ~= "" then
        newName = prefix .. " " .. combinedPrefixes .. " " .. currentName
    else
        newName = prefix .. " " .. currentName
    end

    -- Set the updated display name
    modApi.SetStoryDisplayName(charId, newName)

    -- Add the new prefix to the beginning of the list of prefixes
    if namePrefixes[charId] then
        table.insert(namePrefixes[charId], 1, prefix) -- Insert at the beginning of the table
    else
        namePrefixes[charId] = { prefix }
    end
end

local function addNamePrefixes(prefixes, charId)
    for _, prefix in ipairs(prefixes) do
        if prefix then
            addNamePrefix(prefix, charId)
        end
    end
end

local function addRandomVFX(charId)
    local randomEffect = getRandomItemFromList(RandomizablesLists.VFX)
    if randomEffect then
        modApi.ApplyStatus(charId, randomEffect, 100)
    end
end

local function giveItemDropMultiplier(charId, multiplier)
    uniqueProperties[charId] = uniqueProperties[charId] or {}
    if uniqueProperties[charId].ItemDropMultiplier then
        uniqueProperties[charId].ItemDropMultiplier = uniqueProperties[charId].ItemDropMultiplier * multiplier
    else
        uniqueProperties[charId].ItemDropMultiplier = multiplier
    end
end

local function randomizeElites(charId)
    local isElite = MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.Elites)
    local isSuperElite = MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.SuperElites)
    if isElite or isSuperElite then
        addRandomVFX(charId)
    end
    if isElite and isSuperElite then
        if RandomizerConfig.ConsoleDebug then
            print("Elite Squared! With a chance of around 1 in " ..
                (100 / RandomizerConfig.Elites) * (100 / RandomizerConfig.SuperElites) .. "!")
        end

        addNamePrefix("Ultra Elite", charId)
        giveItemDropMultiplier(charId, Weights.EliteItemDropChance * Weights.SuperEliteItemDropChance)

        return 10
    elseif isSuperElite then
        if RandomizerConfig.ConsoleDebug then
            print("Super Elite!")
        end

        addNamePrefix("Super Elite", charId)
        giveItemDropMultiplier(charId, Weights.SuperEliteItemDropChance)

        return 5
    elseif isElite then
        if RandomizerConfig.ConsoleDebug then
            print("Elite!")
        end

        addNamePrefix("Elite", charId)
        giveItemDropMultiplier(charId, Weights.EliteItemDropChance)

        return 3
    end
    return nil
end

local function getConstrainedRandomness(multiplierOption)
    local multiplier = multiplierOption or 2.0
    return math.random(0, multiplier * RandomizerConfig.Randomness)
end

--Will return a number between 0 and multiplierOption(default = 2) * Randomness/100
local function getAdditionalStrengthMultiplier(multiplierOption)
    return getConstrainedRandomness(multiplierOption) / 100.0
end

local function addItemToCharacter(itemTemplateId, charId)
    local itemTemplateGuid = parseGuid(itemTemplateId)
    if not unprocessedItemTemplates[charId] then
        unprocessedItemTemplates[charId] = {}
    end

    unprocessedItemTemplates[charId][itemTemplateGuid] = true
    modApi.TemplateAddTo(itemTemplateGuid, charId, 1)

    if RandomizerConfig.ConsoleDebug then
        print("Gained item: " .. itemTemplateId)
    end
end


local function giveRandomEquipment(charId)
    local equipmentList = {
        { list = RandomizablesLists.Armor },
        { list = RandomizablesLists.Amulets },
        { list = RandomizablesLists.Gloves },
        { list = RandomizablesLists.Helmets },
        { list = RandomizablesLists.Shields, extraCondition = function() return MathUtils.isGreaterOrEqualThanRandom(50) end },
        { list = RandomizablesLists.Cloaks },
        { list = RandomizablesLists.Boots },
        { list = RandomizablesLists.Rings },
        { list = RandomizablesLists.Weapons }
    }

    for _, equipment in ipairs(equipmentList) do
        if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.NpcEquipment) and
            (not equipment.extraCondition or equipment.extraCondition()) then
            local rndItemTemplate = getRandomItemFromList(equipment.list)
            addItemToCharacter(rndItemTemplate, charId)
        end
    end
end

local function giveConsumables(charId, multiplierOption)
    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.Consumables) then
        local consumablesMultiplier = Weights.ConsumablesMultiplier or 2
        local numConsumablesToAdd = (1 + MathUtils.mathRound(getAdditionalStrengthMultiplier(multiplierOption))) *
        consumablesMultiplier
        for i = 1, numConsumablesToAdd do
            local rndItem = getRandomItemFromList(RandomizablesLists.Consumables)
            addItemToCharacter(rndItem, charId)
        end
    end
end

-- Full character from list removal
local function removeCharFromRandomizedNpcs(charId)
    randomizedNpcs[charId] = nil
end

local function removeCharacterFromCharacterItems(charId)
    characterItems[charId] = nil
end

local function removeCharacterFromCharacterSpells(charId)
    characterSpells[charId] = nil
end


local function removeCharacterFromUniquePropertiesList(charId)
    uniqueProperties[charId] = nil
end

local function removeGivenSpellsFromPartyMember(charId)
    if spellsAddedToParty[charId] then
        for spell, _ in pairs(spellsAddedToParty[charId]) do
            modApi.RemoveSpell(charId, spell)
        end
        spellsAddedToParty[charId] = nil
    end
end

local function removeCharacterFromBoostsList(charId)
    for i, id in ipairs(characterBoosts) do
        if id == charId then
            table.remove(characterBoosts, i)
            break
        end
    end
end

local function removeCharacterFromDisplayNamesList(charId)
    for i, id in ipairs(namePrefixes) do
        if id == charId then
            table.remove(namePrefixes, i)
            break
        end
    end
end

local function removeCharacterFromUnprocessedItemTemplates(charId)
    unprocessedItemTemplates[charId] = nil
end

local function addCharToRandomizedNpcs(charId)
    randomizedNpcs[charId] = true
end

local function removeRandomizedItems(charId)
    if characterItems[charId] then
        local dropChance = RandomizerConfig.NpcsDropAddedItems *
            ((uniqueProperties[charId] and uniqueProperties[charId].ItemDropMultiplier) or 1.0)

        if RandomizerConfig.ConsoleDebug then
            print("Removing given items from: " .. parseStringFromGuid(charId))
            print("Chance to keep item: " .. dropChance)
        end

        for itemId, _ in pairs(characterItems[charId]) do
            if MathUtils.isGreaterOrEqualThanRandom(dropChance) then
                if RandomizerConfig.ConsoleDebug then
                    print("Keeping item: " .. parseStringFromGuid(itemId))
                end
                modApi.Unequip(charId, itemId)
            else
                if RandomizerConfig.ConsoleDebug then
                    print("Removing item: " .. parseStringFromGuid(itemId))
                end
                modApi.RequestDelete(itemId)
            end
        end
        removeCharacterFromCharacterItems(charId)
    end
end

local function giveAllProficiencies(charId)
    local proficiencies = {
        "MartialWeapons",
        "SimpleWeapons",
        "HeavyArmor",
        "LightArmor",
        "MediumArmor",
        "Shields"
    }
    for _, proficiency in ipairs(proficiencies) do
        BoostUtils.addBoostForCharWithPersistence("Proficiency(" .. proficiency .. ")", charId)
    end
end

-- Generalized function to handle giving action resources
local function giveActionResource(charId, resourceName, minDefault, multiplierOption, debugName, weight)
    local localWeight = weight or 1
    local baseValue = modApi.GetActionResourceValuePersonal(charId, resourceName, 0)
    if not baseValue and RandomizerConfig.ConsoleDebug then
        print("Could not fetch " .. (debugName or resourceName) .. " for char: " .. parseStringFromGuid(charId))
    end
    if not baseValue or baseValue < minDefault then
        baseValue = minDefault
    end
    local extraValue = MathUtils.mathRound(baseValue * getAdditionalStrengthMultiplier(multiplierOption) * localWeight)
    if RandomizerConfig.ConsoleDebug then
        print("Giving: " .. extraValue .. " " .. (debugName or resourceName))
    end
    BoostUtils.addBoostForChar("ActionResource(" .. resourceName .. "," .. extraValue .. ",0)", charId)
end

local function giveActionPoints(charId, multiplierOption)
    giveActionResource(charId, "ActionPoint", 1, multiplierOption, "ActionPoints", Weights.ActionPoint)
end

local function giveBonusActionPoints(charId, multiplierOption)
    giveActionResource(charId, "BonusActionPoint", 1, multiplierOption, "BonusActionPoints",
        Weights.BonusActionPoint)
end

local function giveSorceryPoints(charId, multiplierOption)
    giveActionResource(charId, "SorceryPoint", 4, multiplierOption, "SorceryPoints")
end

local function giveSuperiorityDie(charId, multiplierOption)
    giveActionResource(charId, "SuperiorityDie", 4, multiplierOption, "SuperiorityDie")
end

local function giveLayOnHandsCharge(charId, multiplierOption)
    giveActionResource(charId, "LayOnHandsCharge", 2, multiplierOption, "LayOnHandsCharge")
end

local function giveChannelOath(charId, multiplierOption)
    giveActionResource(charId, "ChannelOath", 2, multiplierOption, "ChannelOath")
end

local function giveChannelDivinity(charId, multiplierOption)
    giveActionResource(charId, "ChannelDivinity", 2, multiplierOption, "ChannelDivinity")
end

local function giveKiPoints(charId, multiplierOption)
    giveActionResource(charId, "KiPoint", 5, multiplierOption, "KiPoints")
end

-- Static methods
local function giveRagePoints(charId, _)
    BoostUtils.addBoostForChar("ActionResource(Rage,10,0)", charId)
end

local function giveWildshapePoints(charId, _)
    BoostUtils.addBoostForChar("ActionResource(WildShape,10,0)", charId)
end

local actionResourceBoostMethods = {
    giveActionPoints,
    giveBonusActionPoints,
    giveSorceryPoints,
    giveSuperiorityDie,
    giveLayOnHandsCharge,
    giveChannelOath,
    giveChannelDivinity,
    giveKiPoints,
    giveRagePoints,
    giveWildshapePoints,
}

local function giveResourceBoosts(charId, multiplierOption)
    -- Action resources
    for _, method in ipairs(actionResourceBoostMethods) do
        if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.ResourceBoosts) then
            method(charId, multiplierOption)
        end
    end
end

-- Generalized function to handle giving abilities/attributes
local function giveAbilities(charId, attributeName, multiplierOption)
    local minDefault = 3
    local baseValue = modApi.GetAbility(charId, attributeName)
    if not baseValue and RandomizerConfig.ConsoleExtraDebug then
        print("Could not fetch " .. attributeName .. " for char: " .. parseStringFromGuid(charId))
    end
    if not baseValue or baseValue < minDefault then
        baseValue = minDefault
    end
    local extraValue = MathUtils.mathRound(baseValue * getAdditionalStrengthMultiplier(multiplierOption) *
        Weights.Ability)
    if RandomizerConfig.ConsoleDebug then
        print("Giving: " .. extraValue .. " " .. attributeName)
    end
    BoostUtils.addBoostForCharWithPersistence("Ability(" .. attributeName .. ",+" .. extraValue .. ")", charId)
end


local function giveAbilityBoosts(charId, multiplierOption)
    -- Abilities
    for _, string in ipairs(StaticLists.Abilities) do
        if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.AbilityBoosts) then
            giveAbilities(charId, string, multiplierOption)
        end
    end
end

local function giveAcBoost(charId, multiplierOption)
    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.ACBoosts) then
        local baseAc = 10
        local positiveValue = baseAc * getAdditionalStrengthMultiplier(multiplierOption)
        local negativeValue = baseAc * getAdditionalStrengthMultiplier(multiplierOption)
        local extraAc = MathUtils.mathRound((positiveValue - negativeValue) * Weights.AC)
        BoostUtils.addBoostForCharWithPersistence("AC(" .. extraAc .. ")", charId)
    end
end

local function giveTemporaryHp(charId, multiplierOption, overrideChance)
    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.HealthBoosts) or overrideChance then
        local minDefault = 25
        local baseValue = modApi.GetMaxHitpoints(charId)
        if not baseValue and RandomizerConfig.ConsoleExtraDebug then
            print("Could not fetch MaxHitpoints for char: " .. charId)
        end
        if not baseValue or baseValue < minDefault then
            baseValue = minDefault
        end
        local extraValue = MathUtils.mathRound(baseValue * getAdditionalStrengthMultiplier(multiplierOption) *
            Weights.TempHp)
        if RandomizerConfig.ConsoleDebug then
            print("Giving: " .. extraValue .. " TemporaryHp")
        end
        BoostUtils.addBoostForChar("TemporaryHP(" .. extraValue .. ")", charId)
    end
end

local function giveSpellSlots(charId, multiplierOption)
    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.ResourceBoosts) then
        local charLevel = modApi.GetLevel(charId)
        local spellSlotLevels = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
        for _, spellSlotLevel in ipairs(spellSlotLevels) do
            -- SpellSlot curve, depending on character level
            local randomRange = (math.floor(((spellSlotLevel - 1) ^ 1.4 * 3) / charLevel) + 2) * 2
            local randomNumber = math.random(1, randomRange)
            if randomNumber <= MathUtils.mathRound(getAdditionalStrengthMultiplier(multiplierOption)) then
                local numberOfSpellSlots = MathUtils.mathRound(math.random(1, RandomizerConfig.Randomness) / 8.00 /
                    spellSlotLevel)
                if RandomizerConfig.ConsoleDebug then
                    print("Giving: " .. numberOfSpellSlots .. " level " .. spellSlotLevel .. " spell slots")
                end
                BoostUtils.addBoostForChar(
                    "ActionResource(SpellSlot," .. numberOfSpellSlots .. "," .. spellSlotLevel .. ")", charId)
            end
        end
    end
end

-- Get a valid random spell. Blocks summoning spells if disallowSummonSpells flag is enabled
-- Or at least tries to block, as some modded spells are added in unexpected format
local function getValidSpell(disallowSummonSpells)
    local MAX_ATTEMPTS = 100 -- Limit the number of retries
    local spell
    local attempts = 0
    repeat
        spell = getRandomItemFromList(RandomizablesLists.Spells)
        attempts = attempts + 1
    until (spell and (not disallowSummonSpells or not isSummoningSpell(spell))) or attempts >= MAX_ATTEMPTS

    if attempts >= MAX_ATTEMPTS then
        if RandomizerConfig.ConsoleDebug then
            print("Failed to retrieve a valid spell after " .. MAX_ATTEMPTS .. " attempts.")
        end
        return nil -- Fallback to avoid infinite loop
    end
    return spell
end

local function giveSpells(charId, multiplierOption)
    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.NpcSpells) then
        local numSpellsToAdd = MathUtils.mathRound(
            getAdditionalStrengthMultiplier(multiplierOption) * math.max(1.0, modApi.GetLevel(charId) / 2.0)
        )

        -- Determine whether summon spells should be disallowed
        local disallowSummonSpells = modApi.IsSummon(charId)

        if RandomizerConfig.ConsoleDebug then
            print("Giving " .. numSpellsToAdd .. " spell(s) to NPC: " .. parseStringFromGuid(charId))
        end

        -- Initialize characterSpells[charId] if it doesn't exist
        if not characterSpells[charId] then
            characterSpells[charId] = {}
        end

        for i = 1, numSpellsToAdd do
            local randomSpell = getValidSpell(disallowSummonSpells)

            if randomSpell then
                if characterSpells[charId][randomSpell] then
                    -- Increment casts if the spell is already present
                    characterSpells[charId][randomSpell] = characterSpells[charId][randomSpell] + 1
                else
                    -- Add new spell with 1 cast
                    characterSpells[charId][randomSpell] = 1
                    modApi.AddSpell(charId, randomSpell)
                end

                if RandomizerConfig.ConsoleDebug then
                    print("Giving spell to: " .. parseStringFromGuid(charId) ..
                        " spell: " .. randomSpell .. " (casts left: " .. characterSpells[charId][randomSpell] .. ")")
                end
            else
                if RandomizerConfig.ConsoleExtraDebug then
                    print("No valid spell was returned for: " .. parseStringFromGuid(charId))
                end
            end
        end
    end
end

local function giveStatuses(charId, multiplierOption)
    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.Statuses) then
        local numStatusesToAdd = MathUtils.mathRound(getAdditionalStrengthMultiplier(multiplierOption) * 2.0)
        for i = 1, numStatusesToAdd do
            local statusToAdd = getRandomItemFromList(RandomizablesLists.Statuses)
            if RandomizerConfig.ConsoleDebug then
                print("Giving status: " .. statusToAdd)
            end
            modApi.ApplyStatus(charId, statusToAdd,
                MathUtils.mathRound(getAdditionalStrengthMultiplier(multiplierOption) * 24))
        end
    end

    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.Statuses) and RandomizerConfig.NegativeStatuses then
        local numStatusesToAdd = MathUtils.mathRound(getAdditionalStrengthMultiplier(multiplierOption) * 1.8)
        for i = 1, numStatusesToAdd do
            local statusToAdd = getRandomItemFromList(RandomizablesLists.NegativeStatuses)
            if RandomizerConfig.ConsoleDebug then
                print("Giving negative status: " .. statusToAdd)
            end
            modApi.ApplyStatus(charId, statusToAdd,
                MathUtils.mathRound(getAdditionalStrengthMultiplier(multiplierOption) * 20))
        end
    end
end

local function givePassives(charId, multiplierOption)
    if MathUtils.isGreaterOrEqualThanRandom(RandomizerConfig.Passives) then
        local numPassivesToAdd = MathUtils.mathRound(getAdditionalStrengthMultiplier(multiplierOption) * 2)
        for i = 1, numPassivesToAdd do
            local passiveToAdd = getRandomItemFromList(RandomizablesLists.Passives)
            if RandomizerConfig.ConsoleDebug then
                print("Giving passive: " .. passiveToAdd)
            end
            modApi.AddPassive(charId, passiveToAdd)
        end
    end
end

local function randomizeNpc(charId)
    if (RandomizerConfig.ConsoleDebug) then
        print("=======================================================================")
        print("Randomizing character: " .. parseStringFromGuid(charId))
    end
    local uniqueNames = UniqueEnemiesModule.applyUniqueModifiers(charId)
    addNamePrefixes(uniqueNames, charId)
    local eliteMultiplierOption = randomizeElites(charId)


    addCharToRandomizedNpcs(charId)

    giveAllProficiencies(charId)

    giveResourceBoosts(charId, eliteMultiplierOption)
    giveAbilityBoosts(charId, eliteMultiplierOption)
    giveAcBoost(charId, eliteMultiplierOption)
    giveTemporaryHp(charId, eliteMultiplierOption)

    giveSpellSlots(charId, eliteMultiplierOption)
    giveSpells(charId, eliteMultiplierOption)

    giveStatuses(charId, eliteMultiplierOption)
    givePassives(charId, eliteMultiplierOption)

    giveRandomEquipment(charId)
    giveConsumables(charId, eliteMultiplierOption)

    if (RandomizerConfig.ConsoleDebug) then
        print("=======================================================================")
    end
end

local function spellWasGivenToPartyMember(spellId, charId)
    return spellId ~= "" and spellsAddedToParty[charId] and spellsAddedToParty[charId][spellId]
end

-- Helper function: Add or increment spell casts
local function addOrIncrementSpell(charId, spell)
    if not spellsAddedToParty[charId] then
        spellsAddedToParty[charId] = {}
    end
    if spellsAddedToParty[charId][spell] then
        -- Increment casts left if the spell is already added
        spellsAddedToParty[charId][spell] = spellsAddedToParty[charId][spell] + 1
    else
        -- Add new spell with 1 cast
        spellsAddedToParty[charId][spell] = 1
        modApi.AddSpell(charId, spell)
    end

    if RandomizerConfig.ConsoleDebug then
        print("Adding spell to: " .. parseStringFromGuid(charId) ..
            " spell: " .. spell .. " (casts left: " .. spellsAddedToParty[charId][spell] .. ")")
    end
end

-- Main function: Add random spells to a party member with a certain chance
local function giveSpellsToPartyMember(charId)
    -- Different chances for summons and extra party followers
    local weight = 1.0
    local disallowSummonSpells = false
    if modApi.IsSummon(charId) then
        weight = Weights.SummonSpellChance
        disallowSummonSpells = true
    elseif modApi.IsPartyFollower(charId) then
        weight = Weights.PartyFollowerSpellChance
    end

    -- Determine how many spells to add based on the value of GiveRandomSpellToParty
    local spellChance = MathUtils.mathRound(RandomizerConfig.GiveRandomSpellToParty * weight)
    local numSpellsToAdd = math.floor(spellChance / 100.0)
    local extraSpellChance = spellChance % 100

    -- Add spells based on numSpellsToAdd
    for i = 1, numSpellsToAdd do
        local spell = getValidSpell(disallowSummonSpells)
        if spell then
            addOrIncrementSpell(charId, spell)
        else
            if RandomizerConfig.ConsoleExtraDebug then
                print("No valid spell was returned for: " .. parseStringFromGuid(charId))
            end
        end
    end

    -- Add an extra spell with a chance equal to extraSpellChance
    if extraSpellChance > 0 and MathUtils.isGreaterOrEqualThanRandom(extraSpellChance) then
        local spell = getValidSpell(disallowSummonSpells)
        if spell then
            addOrIncrementSpell(charId, spell)
        else
            if RandomizerConfig.ConsoleExtraDebug then
                print("No extra valid spell was returned for: " .. parseStringFromGuid(charId))
            end
        end
    end
end



local function randomizePartyMember(charId)
    if (RandomizerConfig.ConsoleDebug) then
        print("Randomizing partyMember: " .. parseStringFromGuid(charId))
    end
    giveSpellsToPartyMember(charId)
end

local function isPartyMember(charId)
    return modApi.IsPartyMember(charId, 1)
end

local function isRandomizedChar(charId)
    return randomizedNpcs[charId] == true
end

local function isOriginChar(charId)
    if not OriginChracters then
        OriginChracters = {}
        for _, originCharId in ipairs(StaticLists.OriginCharacters) do
            OriginChracters[originCharId] = true
        end
    end
    return OriginChracters[charId] == true
end

local function isUnprocessedItemTemplate(templateId, charId)
    return unprocessedItemTemplates[charId] and unprocessedItemTemplates[charId][templateId] ~= nil
end

local function isUnprocessedItemTemplateWithRemoval(itemId, charId)
    if unprocessedItemTemplates[charId] and unprocessedItemTemplates[charId][itemId] then
        unprocessedItemTemplates[charId][itemId] = nil
        return true
    end
    return false
end

local function fullyEquipItemForChar(itemId, charId)
    modApi.Equip(charId, itemId)
    if (RandomizerConfig.ConsoleExtraDebug) then
        print("Character: " .. parseStringFromGuid(charId) .. " equiped: " .. parseStringFromGuid(itemId))
    end
end

Ext.Events.SessionLoaded:Subscribe(onSessionLoaded)

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_, _)
    onLevelGameplayStarted()
end)

Ext.Osiris.RegisterListener("PingRequested", 1, "after", function(_)
    print("Combat ReRandomizer - applying current config.")
    RandomizablesLists = BaseRandomizablesList
    getConfigFromFile()
    getModdedStuffFromFile()
    getWeightsFromFile()
    getUniquesFromFile()
    processRandomizablesList()
end)

local function handleDiedEventForRandomizedChar(charId)
    local modvars = getModvars()

    if (RandomizerConfig.ConsoleDebug) then
        print("=======================================================================")
        print("Randomized charecter is dead: " .. parseStringFromGuid(charId))
    end

    removeRandomizedItems(charId)
    modvars.character_items = characterItems
    removeCharFromRandomizedNpcs(charId)
    modvars.randomized_npcs = randomizedNpcs
    removeCharacterFromBoostsList(charId)
    modvars.character_boosts = characterBoosts
    removeCharacterFromCharacterSpells(charId)
    modvars.character_spells = characterSpells
    removeCharacterFromDisplayNamesList(charId)
    modvars.name_prefixes = namePrefixes
    removeCharacterFromUnprocessedItemTemplates(charId)
    removeCharacterFromUniquePropertiesList(charId)
    modvars.unique_properties = uniqueProperties


    if (RandomizerConfig.ConsoleDebug) then
        print("=======================================================================")
    end
end

Ext.Osiris.RegisterListener("Died", 1, "after", function(dyingCharId)
    if isRandomizedChar(dyingCharId) then
        handleDiedEventForRandomizedChar(dyingCharId)
    end
end)

--[[local function handleDownedChangedEventForRandomizedChar(charId)
    if (RandomizerConfig.ConsoleDebug) then
        print("=======================================================================")
        print("Randomized charecter is downed: " .. parseStringFromGuid(charId))
    end

    removeRandomizedItems(charId)

    if (RandomizerConfig.ConsoleDebug) then
        print("=======================================================================")
    end
end

Ext.Osiris.RegisterListener("DownedChanged", 2, "after", function(downedCharId, isDownedInt)
    if isDownedInt == 1 and isRandomizedChar(downedCharId) then
        handleDownedChangedEventForRandomizedChar(downedCharId)
    end
end)]]

local function handleTemplateAddedToEventForRandomizedChar(templateId, itemId, charId)
    local modvars = getModvars()

    if modApi.IsEquipable(itemId) then
        fullyEquipItemForChar(itemId, charId)
    end
    addItemToCharacterItemList(itemId, charId)

    modvars.character_items = characterItems
end

Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", function(templateId, itemId, charId, addType)
    templateId = parseGuid(templateId)
    if isRandomizedChar(charId) and isUnprocessedItemTemplateWithRemoval(templateId, charId) then
        handleTemplateAddedToEventForRandomizedChar(templateId, itemId, charId)
    end
end)

Ext.Osiris.RegisterListener("TemplateRemovedFrom", 3, "after", function(_, itemId, charId)

end)

local function addPartyMemeberAsCombatVisitor(charId, combatId)
    if combatVisitors[combatId] then
        table.insert(combatVisitors[combatId], charId)
    else
        combatVisitors[combatId] = { charId }
    end
end

local function partyMamberHasVisitedCombat(charId, combatId)
    if combatVisitors[combatId] then
        for _, visitor in ipairs(combatVisitors[combatId]) do
            if charId == visitor then
                return true
            end
        end
    end
    return false
end

local function handlePartyMemberEnteredCombatEvent(charId, combatId)
    if not partyMamberHasVisitedCombat(charId, combatId) then
        local modvars = getModvars()

        -- Debug to see randomization first hand (or just mess around)
        if RandomizerConfig.ActAsNpcDebug and not isRandomizedChar(charId) then
            randomizeNpc(charId)

            modvars.randomized_npcs = randomizedNpcs
            modvars.character_items = characterItems
            modvars.character_boosts = characterBoosts
            modvars.character_spells = characterSpells
            modvars.name_prefixes = namePrefixes
            modvars.unique_properties = uniqueProperties
        end

        addPartyMemeberAsCombatVisitor(charId, combatId)
        modvars.combat_visitors = combatVisitors
        randomizePartyMember(charId)
        modvars.party_spells = spellsAddedToParty
    end
end

local function handleNpcEnteredCombatEvent(charId, combatId)
    if not isRandomizedChar(charId) then
        local modvars = getModvars()

        randomizeNpc(charId)

        modvars.character_items = characterItems
        modvars.character_boosts = characterBoosts
        modvars.character_spells = characterSpells
        modvars.randomized_npcs = randomizedNpcs
        modvars.name_prefixes = namePrefixes
        modvars.unique_properties = uniqueProperties
    else
        giveStatuses(charId)
    end
end

local function handleOriginCharEnteredCombatEvent(charId, combatId)
    giveTemporaryHp(charId, 5, true)
end

Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(charId, combatId)
    if modApi.IsDead(charId) then
        if RandomizerConfig.ConsoleExtraDebug then
            print("Dead character entered combat, incinerating: " .. parseStringFromGuid(charId))
        end
        modApi.Die(charId, 7)
    elseif modApi.IsCharacter(charId) then
        if isPartyMember(charId) then
            handlePartyMemberEnteredCombatEvent(charId, combatId)
        elseif isOriginChar(charId) then
            handleOriginCharEnteredCombatEvent(charId, combatId)
        else
            handleNpcEnteredCombatEvent(charId, combatId)
        end
    end
end)

local function handlePartyMemberLeftCombatEvent(charId)
    local modvars = getModvars()
    removeGivenSpellsFromPartyMember(charId)
    modvars.party_spells = spellsAddedToParty
end

Ext.Osiris.RegisterListener("LeftCombat", 2, "after", function(charId, combatId)
    if modApi.IsCharacter(charId) then
        if isPartyMember(charId) then
            handlePartyMemberLeftCombatEvent(charId)
        end
    end
end)

local function clearCombatVisitors(combatId)
    combatVisitors[combatId] = nil
end

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function(combatId)
    local modvars = getModvars()
    clearCombatVisitors(combatId)
    modvars.combat_visitors = combatVisitors
end)


Ext.Osiris.RegisterListener("AttackedBy", 7, "after", function(targetId, attackerId, _, damageType, amount, _, _)
    if (RandomizerConfig.DamageBonus > 0 and isPartyMember(attackerId) and not (modApi.HasAppliedStatus(attackerId, "NON_LETHAL") or modApi.HasActiveStatus(attackerId, "NON_LETHAL"))) then
        if (modApi.IsEnemy(targetId, attackerId)) then
            local extraDmg = math.floor((amount * (RandomizerConfig.DamageBonus)) / 100)
            if RandomizerConfig.ConsoleExtraDebug then
                print("Extra damage to deal:" .. extraDmg)
            end
            if (extraDmg > 0) then
                if (extraDmg > 25000) then
                    local remainingDamage = extraDmg
                    while (remainingDamage > 0) do
                        if (remainingDamage > 25000) then
                            modApi.ApplyDamage(targetId, 25000, damageType)
                            remainingDamage = remainingDamage - 25000
                        else
                            modApi.ApplyDamage(targetId, remainingDamage, damageType)
                            remainingDamage = 0
                        end
                    end
                else
                    modApi.ApplyDamage(targetId, extraDmg, damageType)
                end
            end
        end
    end
end)

local function isGivenSpellForPartyMember(spell, charId)
    return spellWasGivenToPartyMember(spell, charId) and isPartyMember(charId)
end

local function isGivenSpell(spell, charId)
    return characterSpells[charId] and characterSpells[charId][spell]
end

local function removeAddedPartySpellForChar(spell, charId)
    if spellsAddedToParty[charId] and spellsAddedToParty[charId][spell] then
        spellsAddedToParty[charId][spell] = spellsAddedToParty[charId][spell] - 1

        if spellsAddedToParty[charId][spell] > 0 then
            if RandomizerConfig.ConsoleDebug then
                print("Spell: " .. spell .. " for character: " .. parseStringFromGuid(charId) ..
                    " has " .. spellsAddedToParty[charId][spell] .. " casts left.")
            end
        else
            if RandomizerConfig.ConsoleDebug then
                print("Removing spell: " ..
                    spell .. ", after limited casts for character: " .. parseStringFromGuid(charId))
            end

            modApi.RemoveSpell(charId, spell)
            spellsAddedToParty[charId][spell] = nil
        end
    end
end

-- Removes spell or decreses cast count of spell for character
local function removeCharacterSpellFromChar(spell, charId)
    if characterSpells[charId] and characterSpells[charId][spell] then
        -- Decrement the number of casts left
        characterSpells[charId][spell] = characterSpells[charId][spell] - 1

        if characterSpells[charId][spell] <= 0 then
            -- Remove the spell completely if casts reach zero
            if RandomizerConfig.ConsoleDebug then
                print("Removing spell: " .. spell .. ", for npc: " .. parseStringFromGuid(charId))
            end
            modApi.RemoveSpell(charId, spell, 1)
            characterSpells[charId][spell] = nil
        else
            -- Log remaining casts if the spell is not fully removed
            if RandomizerConfig.ConsoleDebug then
                print("Decrementing spell: " .. spell .. ", for npc: " .. parseStringFromGuid(charId) ..
                    ". Casts left: " .. characterSpells[charId][spell])
            end
        end
    end
end


local function handlePartyMemberCastedSpellEvent(charId, spell)
    local proccesingNeeded = true
    if RandomizerConfig.RandomSpellToPartySingleCast then
        if isGivenSpellForPartyMember(spell, charId) then
            local modvars = getModvars()
            removeAddedPartySpellForChar(spell, charId)
            proccesingNeeded = false
            modvars.party_spells = spellsAddedToParty
        else
            local containerSpell = getSpellContainer(spell)
            if containerSpell and containerSpell ~= "" then
                local modvars = getModvars()
                removeAddedPartySpellForChar(containerSpell, charId)
                proccesingNeeded = false
                modvars.party_spells = spellsAddedToParty
            end
        end
    end
    if proccesingNeeded and RandomizerConfig.ActAsNpcDebug and isGivenSpell(spell, charId) then
        local modvars = getModvars()
        removeCharacterSpellFromChar(spell, charId)
        modvars.character_spells = characterSpells
    end
end

local function handleNpcCastedSpellEvent(charId, spell)
    if isGivenSpell(spell, charId) then
        local modvars = getModvars()
        removeCharacterSpellFromChar(spell, charId)
        modvars.character_spells = characterSpells
    else
        local containerSpell = getSpellContainer(spell)
        if containerSpell and containerSpell ~= "" then
            local modvars = getModvars()
            removeCharacterSpellFromChar(containerSpell, charId)
            modvars.character_spells = characterSpells
        end
    end
end

Ext.Osiris.RegisterListener("CastedSpell", 5, "after", function(casterId, spell, _, _, _)
    if RandomizerConfig.ConsoleDebug then
        print(casterId .. " cast spell: ", spell)
    end
    if isPartyMember(casterId) then
        handlePartyMemberCastedSpellEvent(casterId, spell)
    elseif isRandomizedChar(casterId) then
        handleNpcCastedSpellEvent(casterId, spell)
    end
end)
