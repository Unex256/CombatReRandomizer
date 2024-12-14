local Persistence = Ext.Require("CombatReRandomizer/SharedData/Persistence.lua")

local SpellUtils = {}

local modApi = {}

-- Persistence: Local lists
local characterSpells = Persistence.characterSpells
local spellsAddedToParty = Persistence.spellsAddedToParty

-- Set up BoostUtils with the wrapped modApi
function SpellUtils.initialize(wrappedModApi)
    modApi = wrappedModApi  -- Store the reference to modApi in a local variable
end

-- Spells
function SpellUtils.getSpellContainer(spell)
    local spellData = Ext.Stats.Get(spell, nil, false)
    if spellData and spellData.SpellContainerID ~= "" then
        return spellData.SpellContainerID
    end
    return "" -- Return an empty string if there's no container or spell doesn't exist
end

-- Function to check if a spell is a root spell
function SpellUtils.isRootSpell(spell)
    local spellData = Ext.Stats.Get(spell, nil, false)
    if spellData and (not spellData.RootSpellID or spellData.RootSpellID == "") then
        return true
    end
    return false -- Returns false if it's not a root spell or spell doesn't exist
end

-- Function to return root spell if it exists
function SpellUtils.getRootSpell(spell)
    local spellData = Ext.Stats.Get(spell, nil, false)
    if spellData and (not spellData.RootSpellID or spellData.RootSpellID == "") then
        return spellData.RootSpellID
    end
    return nil -- Returns false if it's not a root spell or spell doesn't exist
end

-- Helper function to check if a functor has summoning properties
local function isSummoningProperty(functor)
    return functor.TypeId == "Summon" or functor.TypeId == "Spawn"
end

-- Helper function to check if any of the spell's properties meet summoning conditions
function SpellUtils.hasSummoningProperties(spellData)
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

local function splitContainerSpells(input, separator)
    local result = {}
    for match in (input .. separator):gmatch("(.-)" .. separator) do
        table.insert(result, match)
    end
    return result
end

-- Main function to check if a spell or any of its container spells are summoning spells
function SpellUtils.isSummoningSpell(spell)
    local spellData = Ext.Stats.Get(spell)

    -- Step 1: Check the main spell for summoning properties
    if SpellUtils.hasSummoningProperties(spellData) then
        return true
    end

    -- Step 2: If the spell is a container, check each contained spell
    if spellData and spellData.ContainerSpells then
        -- Split the "ContainerSpells" string into individual spells
        local containerSpells = splitContainerSpells(spellData.ContainerSpells, ";")
        for _, containedSpell in ipairs(containerSpells) do
            local containedSpellData = Ext.Stats.Get(containedSpell)
            if SpellUtils.hasSummoningProperties(containedSpellData) then
                return true
            end
        end
    end

    return false
end

-- Function to add a single spell cast to npc with persistence tracking
function SpellUtils.addSpellCastToCharacter(charId, spell)
    -- Initialize characterSpells[charId] if it doesn't exist
    if not characterSpells[charId] then
        characterSpells[charId] = {}
    end
    if characterSpells[charId][spell] then
        -- Increment casts if the spell is already present
        characterSpells[charId][spell] = characterSpells[charId][spell] + 1
    else
        -- Add new spell with 1 cast
        characterSpells[charId][spell] = 1
        modApi.AddSpell(charId, spell)
    end
end

-- Function to add a several spell casts to npc with persistence tracking
function SpellUtils.addSpellCastsToCharacter(charId, spell, castCount)
    -- Initialize characterSpells[charId] if it doesn't exist
    if not characterSpells[charId] then
        characterSpells[charId] = {}
    end
    if characterSpells[charId][spell] then
        -- Increment casts if the spell is already present
        characterSpells[charId][spell] = characterSpells[charId][spell] + castCount
    else
        -- Add new spell with given cast count
        characterSpells[charId][spell] = castCount
        modApi.AddSpell(charId, spell)
    end
end

-- Function to add a spell (near infinite casts) to npc with persistence tracking
function SpellUtils.addSpellToCharacter(charId, spell)
    -- Initialize characterSpells[charId] if it doesn't exist
    if not characterSpells[charId] then
        characterSpells[charId] = {}
    end
    if characterSpells[charId][spell] then
        -- Rewrite to near infinite casts if it already has some
        characterSpells[charId][spell] = 9001
    else
        -- Add new spell with near infinite casts
        characterSpells[charId][spell] = 9001
        modApi.AddSpell(charId, spell)
    end
end

-- Function to add a single spell cast to a party member with persistence tracking
function SpellUtils.addSpellCastToPartyMember(charId, spell)
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
end

-- Function to add a several spell casts to a party member with persistence tracking
function SpellUtils.addSpellCastsToPartyMember(charId, spell, castCount)
    if not spellsAddedToParty[charId] then
        spellsAddedToParty[charId] = {}
    end
    if spellsAddedToParty[charId][spell] then
        -- Increment casts left if the spell is already added
        spellsAddedToParty[charId][spell] = spellsAddedToParty[charId][spell] + castCount
    else
        -- Add new spell with given cast count
        spellsAddedToParty[charId][spell] = castCount
        modApi.AddSpell(charId, spell)
    end
end

return SpellUtils