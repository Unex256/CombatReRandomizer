local function default(value, fallback)
    if value == nil then
        return fallback
    else
        return value
    end
end

local function validateAndConvert(jsonData)
    local luaData = {}

    for uniqueName, uniqueData in pairs(jsonData.UniqueTypes) do
        local weightValue = tonumber(uniqueData.weight)
        local converted = {
            boosts = {},
            statuses = {},
            spells = {},
            blacklist = {},
            whitelist = {},
            weight = weightValue and math.max(weightValue, 1) or 100
        }

        local function logErrorAndSkip(field, extraMessage)
            if not extraMessage then
                extraMessage = ""
            end
            print("Skipping '" .. uniqueName .. "' due to missing/invalid field: " .. field .. " " .. extraMessage)
            return nil
        end

        -- Validate and convert boosts
        if uniqueData.boosts then
            converted.boosts.ActionResource = {}
            if uniqueData.boosts.ActionResource then
                for _, action in ipairs(uniqueData.boosts.ActionResource) do
                    if not action.type then
                        logErrorAndSkip("ActionResource.type")
                        goto continue
                    end
                    if type(action.amount) ~= "number" then
                        logErrorAndSkip("ActionResource.amount", "must be a number or nothing (default 1)")
                        goto continue
                    end
                    if action.percentage ~= nil and type(action.percentage) ~= "boolean" then
                        logErrorAndSkip("ActionResource.percentage", "must be empty(false) or a boolean (true/false)")
                        goto continue
                    end
                    table.insert(converted.boosts.ActionResource, {
                        type = action.type,
                        amount = default(action.amount, 1),
                        percentage = default(action.percentage, false)
                    })
                end
            end

            if uniqueData.boosts.TemporaryHp then
                local tempHp = uniqueData.boosts.TemporaryHp
                if type(tempHp.amount) ~= "number" or tempHp.amount < 0 then
                    logErrorAndSkip("TemporaryHp.amount", "must be a positive number or nothing (default 1)")
                    goto continue
                end
                tempHp.amount = default(tempHp.amount, 1)
                tempHp.percentage = default(tempHp.percentage, false)
                converted.boosts.TemporaryHp = tempHp
            end

            if uniqueData.boosts.Ability then
                converted.boosts.Ability = {}
                for _, ability in ipairs(uniqueData.boosts.Ability) do
                    if not ability.type then
                        logErrorAndSkip("Ability.type")
                        goto continue
                    end
                    table.insert(converted.boosts.Ability, {
                        type = ability.type,
                        amount = default(ability.amount, 1),
                        percentage = default(ability.percentage, false)
                    })
                end
            end

            if uniqueData.boosts.AC then
                local ac = uniqueData.boosts.AC
                ac.amount = default(ac.amount, 1)
                ac.percentage = default(ac.percentage, false)
                converted.boosts.AC = ac
            end

            if uniqueData.boosts.SpellSlot then
                converted.boosts.SpellSlot = {}
                for _, slot in ipairs(uniqueData.boosts.SpellSlot) do
                    if type(slot.amount) ~= "number" or slot.amount < 0 then
                        logErrorAndSkip("SpellSlot.amount", "must be a positive integer or nothing (default 1)")
                        goto continue
                    end
                    if type(slot.level) ~= "number" or slot.level < 1 then
                        logErrorAndSkip("SpellSlot.level", "must be a positive integer or nothing (default 1)")
                        goto continue
                    end
                    table.insert(converted.boosts.SpellSlot, {
                        amount = default(slot.amount, 1),
                        level = default(slot.level, 1)
                    })
                end
            end
        end

        -- Validate and convert statuses
        if uniqueData.statuses then
            for _, status in ipairs(uniqueData.statuses) do
                if not status.type then
                    logErrorAndSkip("statuses.type")
                    goto continue
                end
                if status.duration ~= nil and (type(status.duration) ~= "number" or status.duration < 0) then
                    logErrorAndSkip("statuses.duration", "must be a positive number or nothing(infinite)")
                    goto continue
                end
                table.insert(converted.statuses, {
                    type = status.type,
                    duration = default(status.duration, -1)
                })
            end
        end

        -- Validate and convert spells
        if uniqueData.spells then
            for _, spellData in ipairs(uniqueData.spells) do
                if not spellData.spell then
                    logErrorAndSkip("spellData.type")
                    goto continue
                end
                if spellData.casts ~= nil and (type(spellData.casts) ~= "number" or spellData.casts < 0) then
                    logErrorAndSkip("spells.casts", "must be a positive number or nothing(infinite)")
                    goto continue
                end
                table.insert(converted.statuses, {
                    spell = spellData.spell,
                    casts = default(spellData.casts, nil)
                })
            end
        end

        -- Convert whitelist and blacklist
        if uniqueData.blacklist then
            if type(uniqueData.blacklist) == "table" then
                for _, item in ipairs(uniqueData.blacklist) do
                    if type(item) ~= "string" then
                        logErrorAndSkip("blacklist item", "must be a string")
                        goto continue
                    end
                    converted.blacklist[item] = true
                end
            else
                logErrorAndSkip("blacklist", "must be an array of strings")
                goto continue
            end
        end

        if uniqueData.whitelist then
            if type(uniqueData.whitelist) == "table" then
                for _, item in ipairs(uniqueData.whitelist) do
                    if type(item) ~= "string" then
                        logErrorAndSkip("whitelist item", "must be a string")
                        goto continue
                    end
                    converted.whitelist[item] = true
                end
            else
                logErrorAndSkip("whitelist", "must be an array of strings")
                goto continue
            end
        end

        luaData[uniqueName] = converted

        ::continue::
    end

    return luaData
end

return validateAndConvert
