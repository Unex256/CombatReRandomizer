local Data = {}

Data.RandomizerConfig = {
    Randomness = 25,
    NpcEquipment = 50,
    NpcLootGear = 0.5,
    NpcSpells = 50,
    MaxNpcSpells = 5,
    EnemiesOnly = false,
    ResourceBoosts = 50,
    Statuses = 50,
    Consumables = 10,
    NegativeStatuses = false,
    HealthBoosts = 50,
    NpcsDropAddedItems = 10.0,
    AbilityBoosts = 50,
    DiminishingAbilityReturns = true,
    DiminishingAbilityThresholds = {10, 20, 30},
    ACBoosts = 33,
    DamageBonus = 0,
    RaidBossEnrageTurns = 4,
    Passives = 100,
    Elites = 10,
    SuperElites = 2,
    Uniques = 10,
    MaxUniqueModifiers = 3,
    GiveRandomSpellToParty = 100,
    RandomSpellToPartySingleCast = true,
    ConsoleDebug = false,
    ActAsNpcDebug = false,
    ConsoleExtraDebug = false,
}


local sortableKeys = {
    DiminishingAbilityThresholds = true,
}

-- Assigns new configuration values from a JSON-like table
function Data.assignRandomizerConfigValues(configJson)
    for key, value in pairs(configJson) do
        if Data.RandomizerConfig[key] ~= nil then
            if sortableKeys[key] and type(value) == "table" then
                table.sort(value)
            end
            Data.RandomizerConfig[key] = value
        end
    end
end


return Data
