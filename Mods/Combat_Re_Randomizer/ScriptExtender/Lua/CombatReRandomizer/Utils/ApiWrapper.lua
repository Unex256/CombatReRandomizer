-- Define the ModApiWrappers module
local ApiWrapper = {}

-- Function to wrap methods that return integer booleans (0 or 1)
local function wrapMethodForBooleanReturn(originalMethod)
    return function(...)
        local result = originalMethod(...)
        return result and result ~= 0  -- Converts 0/nil to false and 1 to true
    end
end

-- Function to create a dummy wrapper for methods that don't return anything
local function wrapMethodWithoutReturn(originalMethod)
    return function(...)
        originalMethod(...)  -- Call the original method with the provided arguments
    end
end

-- Function to wrap methods for no reason :)
local function wrapMethodWithReturn(originalMethod)
    return function(...)
        return originalMethod(...)
    end
end

-- Function to wrap and initialize mod API methods
function ApiWrapper.initializeModApi(modApi)
    modApi.IsPartyMember = wrapMethodForBooleanReturn(IsPartyMember)
    modApi.IsCharacter = wrapMethodForBooleanReturn(IsCharacter)
    modApi.IsEnemy = wrapMethodForBooleanReturn(IsEnemy)
    modApi.IsDead = wrapMethodForBooleanReturn(IsDead)
    modApi.HasAppliedStatus = wrapMethodForBooleanReturn(HasAppliedStatus)
    modApi.HasActiveStatus = wrapMethodForBooleanReturn(HasActiveStatus)
    modApi.IsEquipable = wrapMethodForBooleanReturn(IsEquipable)
    modApi.IsInInventoryOf = wrapMethodForBooleanReturn(IsInInventoryOf)
    modApi.TemplateIsInInventory = wrapMethodForBooleanReturn(TemplateIsInInventory)
    modApi.SpellHasSpellFlag = wrapMethodForBooleanReturn(SpellHasSpellFlag)
    modApi.IsPartyFollower = wrapMethodForBooleanReturn(IsPartyFollower)
    modApi.IsSummon = wrapMethodForBooleanReturn(IsSummon)

    modApi.AddBoosts = wrapMethodWithoutReturn(AddBoosts)
    modApi.ApplyDamage = wrapMethodWithoutReturn(ApplyDamage)
    modApi.Equip = wrapMethodWithoutReturn(Equip)
    modApi.Unequip = wrapMethodWithoutReturn(Unequip)
    modApi.Drop = wrapMethodWithoutReturn(Drop)
    modApi.LockUnequip = wrapMethodWithoutReturn(LockUnequip)
    modApi.SetIsDroppedOnDeath = wrapMethodWithoutReturn(SetIsDroppedOnDeath)
    modApi.TemplateAddTo = wrapMethodWithoutReturn(TemplateAddTo)
    modApi.TemplateRemoveFrom = wrapMethodWithoutReturn(TemplateRemoveFrom)
    modApi.AddSpell = wrapMethodWithoutReturn(AddSpell)
    modApi.RemoveSpell = wrapMethodWithoutReturn(RemoveSpell)
    modApi.ApplyStatus = wrapMethodWithoutReturn(ApplyStatus)
    modApi.AddPassive = wrapMethodWithoutReturn(AddPassive)
    modApi.SetStoryDisplayName = wrapMethodWithoutReturn(SetStoryDisplayName)
    modApi.RequestDelete = wrapMethodWithoutReturn(RequestDelete)
    modApi.Die = wrapMethodWithoutReturn(Die)

    modApi.GetActionResourceValuePersonal = wrapMethodWithReturn(GetActionResourceValuePersonal)
    modApi.GetAbility = wrapMethodWithReturn(GetAbility)
    modApi.GetMaxHitpoints = wrapMethodWithReturn(GetMaxHitpoints)
    modApi.GetHitpoints = wrapMethodWithReturn(GetHitpoints)
    modApi.GetLevel = wrapMethodWithReturn(GetLevel)
    modApi.GetDisplayName = wrapMethodWithReturn(GetDisplayName)
    modApi.GetFlagDescription = wrapMethodWithReturn(GetFlagDescription)
end

return ApiWrapper
