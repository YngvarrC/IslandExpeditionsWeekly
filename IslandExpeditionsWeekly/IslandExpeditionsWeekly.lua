--[[
==============
==============                   IslandExpeditionsWeekly
==============              An addon by Lyrenia - EU - Draenor
==============  Keep track of your island expeditions weekly quest progress
==============
--]]

-- Init Ace3
local addonName = ...
_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
--_G[addonName].GUI = LibStub("AceGUI-3.0")
--_G[addonName].LDB = LibStub("LibDataBroker-1.1")
--_G[addonName].LDBI = LibStub("LibDBIcon-1.0")

local addon = _G[addonName]

local chat_options = {
    type = "group",
    args = {
        --[[show_old = {
            type = "execute",
            name = 'show',
            desc = "Show the info in chat the old way",
            func = function() addon:showProgressOld() end,
            order = 6
        },--]]
        show = {
            type = "execute",
            name = 'show',
            desc = "Show the info in chat",
            func = function() addon:showProgress() end,
            order = 1
        },
        reset = {
            type = "execute",
            name = 'reset',
            desc = "Reset the character database",
            func = function() addon:initDB(); addon:storeProgress(); addon:printToChat("DB reset succesful") end,
            order = 5
        },
        ignorelist = {
            type = "execute",
            name = 'ignorelist',
            desc = "Get a list of all ignored characters",
            func = function() addon:printIgnoreList() end,
            order = 3
        },
        clearignore = {
            type = "execute",
            name = 'clearignore',
            desc = "Unignore all characters",
            func = function() addon:clearIgnoreList() end,
            order = 4
        },
        ignore = {
            type = "input",
            name = "toggleignore",
            usage = "<Realm>.<Character>",
            desc = "Toggle ignoring a certain character so it doesn't get displayed",
            get = false,
            set = function(info, character_key) addon:toggleIgnoreCharacter(character_key) end,
            order = 2
        },
        --[[data = {
            type = "execute",
            name = 'data',
            func = function() addon:setData(); addon:printToChat("DB data fill succesful") end
        },]]
    },
}

-- localize used functions
local IsQuestFlaggedCompleted = _G.IsQuestFlaggedCompleted
local GetQuestObjectiveInfo = _G.GetQuestObjectiveInfo
local GetRealmName = _G.GetRealmName
local UnitName = _G.UnitName
local UnitLevel = _G.UnitLevel
local GetCurrentRegion = _G.GetCurrentRegion
local tinsert = table.insert
local tsort = table.sort

function addon:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, chat_options, {"IslandExpeditionsWeekly", "iew"})

    if IslandExpeditionsWeeklyDB == nil then
        addon:initDB()
    end

    if IslandExpeditionsWeeklyDB.IgnoredCharacters == nil then
        IslandExpeditionsWeeklyDB.IgnoredCharacters = {}
    end

    addon.next_reset = addon:getNextWeeklyReset()
    --[[
        if previous reset is earlier than next reset, reset manually
        we now base the reset on a 10 min difference between next weekly reset and last stored next weekly reset
        because simply doing
            IslandExpeditionsWeeklyDB.ResetTime < addon.next_reset
        is not reliable enough
        The calculated server reset seems to be off by a few seconds sometimes compared to earlier calculations, which causes unwanted resets)
    --]]
    if (addon.next_reset - IslandExpeditionsWeeklyDB.ResetTime) > 600 then
        -- addon:printToChat("\124c0000FFFFRESETTING "..IslandExpeditionsWeeklyDB.ResetTime.." < "..addon.next_reset.."\124r")
        addon:resetProgress()
    end
end

function addon:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("ISLAND_AZERITE_GAIN")
end

function addon:OnDisable()
    self:UnregisterAllEvents()
end

-- EVENT processing functions
function addon:PLAYER_ENTERING_WORLD()
    addon.realm = GetRealmName()
    addon.name = UnitName("player")
    addon.playerlevel = UnitLevel("player")
    addon.key = format("%s.%s", addon.realm, addon.name)
    addon:storeProgress()
end
function addon:PLAYER_LEVEL_UP()
    addon.playerlevel = UnitLevel("player")
    addon:storeProgress()
end
function addon:ISLAND_AZERITE_GAIN()
    addon:storeProgress()
end
-- END EVENT processing functions

-- handle chat commands
function addon:ChatCommand(input)
  if not input or input:trim() == "" then
    -- this will show an options dialog at some point
    LibStub("AceConfigDialog-3.0"):Open("IslandExpeditionsWeeklyOptions")
  else
    LibStub("AceConfigCmd-3.0").HandleCommand(addon, "iew", "IslandExpeditionsWeeklyOptions", input)
  end
end

--[[
====== Print stuff to user functions
--]]

function addon:showProgress()
    if IslandExpeditionsWeeklyDB ~= nil then
        local chars_120 = {}
        local chars_other = {}
        for key, char in pairs(IslandExpeditionsWeeklyDB.Characters) do
            if IslandExpeditionsWeeklyDB.IgnoredCharacters[key] == nil then
                if char.level == 120 then
                    tinsert(chars_120, key)
                else
                    tinsert(chars_other, key)
                end
            end
        end
        -- sort both alphabetically
        tsort(chars_120)
        tsort(chars_other)
        local ordered_chars = addon:mergeTables(chars_120, chars_other)

        local data_header = "Weekly island expedition progress:\nRealm Name: Azerite Collected -- WQ\n"
        local data_lines = ""
        for i = 1, #ordered_chars do
            local v = IslandExpeditionsWeeklyDB.Characters[ordered_chars[i]]
            local line = "\124c0000FFFF"..v.Realm.."\124r "..v.Name..":"
            if v.level == 120 then
                -- only 120s can do the azerite collecting
                if v.Finished_azerite then
                    line = line.." \124cFF00FF00Done\124r"
                else
                    line = line.." \124cFFFF0000"..v.Progress_azerite.."/40K\124r"
                end
            else
                line = line.." \124c0000FFFFN/A\124r"
            end

            -- everyone can do the world quest
            if v.Finished_xp == true then
                line = line.." -- \124cFF00FF00Done\124r"
            elseif v.Finished_xp == false then
                line = line.." -- \124cFFFF0000Open\124r"
            end
            data_lines = data_lines..line.."\n"
        end

        addon:printToChat(data_header..data_lines);
    else
        addon:printToChat("no data!")
    end
end

-- DEPRECATED
function addon:showProgressOld()
    if IslandExpeditionsWeeklyDB ~= nil then
        local ordered = {}
        for key in pairs(IslandExpeditionsWeeklyDB.Characters) do
            tinsert(ordered, key)
        end
        tsort(ordered)

        local line_max_header = "Weekly island azerite collecting progress:\n"
        local line_max = ""
        local line_xp_header = "Weekly island expedition WQ progress:\n"
        local line_xp = ""
        for i = 1, #ordered do
            local v = IslandExpeditionsWeeklyDB.Characters[ordered[i]]
            local line = "\124c0000FFFF"..v.Realm.."\124r "..v.Name
            if v.level == 120 then
                if v.Finished_azerite then
                    line_max = line_max..line.." \124cFF00FF00Finished collecting azerite!\124r\n"
                else
                    line_max = line_max..line.." \124cFFFF0000"..v.Progress_azerite.."/40000 azerite collected\124r\n"
                end
            elseif v.level > 109 and v.level < 120 then
                if v.Finished_xp == true then
                    line_xp = line_xp..line.." \124cFF00FF00Finished xp quest!\124r\n"
                elseif v.Finished_xp == false then
                    line_xp = line_xp..line.." \124cFFFF0000Xp quest not completed!\124r\n"
                end
            end
        end

        if #line_max > 0 then
            addon:printToChat(line_max_header..line_max);
        end
        if #line_xp > 0 then
            addon:printToChat(line_xp_header..line_xp);
        end
    else
        addon:printToChat("no data!")
    end
end

function addon:printIgnoreList()
        local list = ""
        for key in pairs(IslandExpeditionsWeeklyDB.IgnoredCharacters) do
            local parts = addon:split(key, ".")
            if #parts == 2 then
                list = list.."\124c0000FFFF"..parts[1].."\124r "..parts[2].."\n"
            end
        end
        if #list > 0 then
            addon:printToChat("Currenlty ignoring:\n"..list)
        else
            addon:printToChat("No characters ignored")
        end
end

--[[
====== DB interaction functions
--]]
-- store a default table into the savedvariable
function addon:initDB()
    IslandExpeditionsWeeklyDB = {
        ResetTime = 0, -- timestamp of upcoming reset
        Characters = {
        --[[    ["Realm.Name"] = {
                Realm = "some realm",
                Name = "some name",
                level = player level integer,
                Finished_azerite = finished azerite quest?, 120 level only
                Progress_azerite = progress azerite quest,
                Finished_xp = finished weekly xp WQ? [110-119] level range
            } ]]
        },
        IgnoredCharacters = {
            -- simple list of Realm.Name as key to store characters we do not want to show
            -- "Realm.Name" = true
        }
    }
    -- update reset time to next reset
    addon:saveResetTime()
end

function addon:saveResetTime()
    if addon.next_reset ~= nil then
        IslandExpeditionsWeeklyDB.ResetTime = addon.next_reset
    else
        IslandExpeditionsWeeklyDB.ResetTime = 0
    end
end

-- store/update progress on current character
function addon:storeProgress()
    if addon.playerlevel >= 110 then

        -- track weekly azerite quest for 120+
        local finished_azerite = false
        local progress_azerite = 0
        if addon.playerlevel == 120 then
            finished_azerite = IsQuestFlaggedCompleted(53435)
            if finished_azerite == false then
                local text, type, finished_fake, progress, needed = GetQuestObjectiveInfo(53435,1,false);
                progress_azerite = progress
            end
        end

        -- track weekly WQ
        local finished_xp = true
        local faction, _ = UnitFactionGroup("player");
        if faction == "Horde" then
            finished_xp = IsQuestFlaggedCompleted(54166)
        elseif faction == "Alliance" then
            finished_xp = IsQuestFlaggedCompleted(54167)
        end

        IslandExpeditionsWeeklyDB.Characters[addon.key] = {
            Realm = addon.realm,
            Name = addon.name,
            level = addon.playerlevel,
            Finished_azerite = finished_azerite,
            Progress_azerite = progress_azerite,
            Finished_xp = finished_xp
        }
    end
end

-- reset savedvariable to a 'nothing completed' state
function addon:resetProgress()
    for key, data in pairs(IslandExpeditionsWeeklyDB.Characters) do
        -- Only reset those that finished the weekly azerite because it carries over to next week
        if IslandExpeditionsWeeklyDB.Characters[key].Finished_azerite == true then
            IslandExpeditionsWeeklyDB.Characters[key].Finished_azerite = false
            IslandExpeditionsWeeklyDB.Characters[key].Progress_azerite = 0
        end

        -- reset WQ for everyone
        if IslandExpeditionsWeeklyDB.Characters[key].Finished_xp == true then
            IslandExpeditionsWeeklyDB.Characters[key].Finished_xp = false
        end
    end

    addon:saveResetTime()
end

-- (un)ignore a character
function addon:toggleIgnoreCharacter(character_key)
    if IslandExpeditionsWeeklyDB.Characters[character_key] == nil then
        addon:printToChat("Character '"..character_key.."' is not being tracked. Unable to ignore")
    else
        if IslandExpeditionsWeeklyDB.IgnoredCharacters[character_key] == nil then
            IslandExpeditionsWeeklyDB.IgnoredCharacters[character_key] = true
            addon:printToChat("Ignoring "..character_key)
        else
            IslandExpeditionsWeeklyDB.IgnoredCharacters[character_key] = nil
            addon:printToChat("No longer ignoring "..character_key)
        end
    end
end

function addon:clearIgnoreList()
    IslandExpeditionsWeeklyDB.IgnoredCharacters = {}
    addon:printToChat("Ignore list cleared")
end

--[[
====== Utility functions
--]]
function addon:printToChat(text)
    DEFAULT_CHAT_FRAME:AddMessage("\124cFFFFFF00[IEW] "..text.."\124r")
end

function addon:mergeTables(t1, t2)
    local resulting_table = {}
    if t1 ~= nil and t2 ~= nil then
        for _, value in pairs(t1) do
            tinsert(resulting_table, value)
        end
        for _, value in pairs(t2) do
            tinsert(resulting_table, value)
        end
    end

    return resulting_table
end

function addon:split(input, separator)
    -- default split on whitespace
    if separator == nil then
        separator = "%s"
    end

    local list = {}
    for part in string.gmatch(input, "([^"..separator.."]+)") do
        tinsert(list, part)
    end

    return list
end

-- Get next weekly reset, server time
function addon:getNextWeeklyReset()
    if addon.resetday == nil then
        -- determine server reset day based on region
        local region = GetCurrentRegion()
        addon.resetday = {}
        if region ~= nil then
            if region == 1 then
                addon.resetday["2"] = true -- US resets on tuesday
            elseif region == 3 then
                addon.resetday["3"] = true -- EU resets on wednesday
            elseif region == 2 or region == 4 or region == 5 then -- Korea, Taiwan, China
                addon.resetday["4"] = true --  resets on thursday
            end
        else
            addon.resetday["3"] = true -- fallback on eu reset
        end
    end

    -- get daily reset time
    local daily_reset_ts = GetQuestResetTime()
    local server_time = C_Calendar.GetDate()
    local server_ts = time({
        year = server_time.year,
        month = server_time.month,
        day = server_time.monthDay,
        hour = server_time.hour,
        min = server_time.minute,
        sec = 0
        })
    local reset = server_ts + daily_reset_ts
    if not reset then
        return nil
    end
    -- add a day until we reach our reset day
    while not addon.resetday[date("%w", reset)] do
        reset = reset + 24 * 3600
    end

    return reset
end

function addon:setData()
    -- debug function to fill up the db variable
end
