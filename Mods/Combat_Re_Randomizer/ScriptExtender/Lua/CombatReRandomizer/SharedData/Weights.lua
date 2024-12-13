local Data = {}

Data.Weights = {
    Ability = 0.6,
    AC = 0.7,
    ActionPoint = 0.8,
    BonusActionPoint = 0.8,
    TempHp = 1.4,
    PartyFollowerSpellChance = 0.5,
    SummonSpellChance = 0.4,
    EliteItemDropChance = 1.5,
    SuperEliteItemDropChance = 2.0,
    UniquePowerScale = 1.0
}

-- Assigns new weight values from a JSON-like table
function Data.assignRandomizerWeights(weightsJson)
    for key, value in pairs(weightsJson) do
        if Data.Weights[key] ~= nil then
            Data.Weights[key] = value
        end
    end
end

return Data
