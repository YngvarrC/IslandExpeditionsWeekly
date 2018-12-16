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
_G[addonName].GUI = LibStub("AceGUI-3.0")
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
        showgui = {
            type = "execute",
            name = 'show',
            desc = "Show the progress in a simple window",
            func = function() addon:showGui() end,
            order = 2
        },
        reset = {
            type = "execute",
            name = 'reset',
            desc = "Reset the character database",
            func = function() addon:initDB(); addon:storeProgress(); addon:printToChat("DB reset succesful") end,
            order = 6
        },
        ignorelist = {
            type = "execute",
            name = 'ignorelist',
            desc = "Get a list of all ignored characters",
            func = function() addon:printIgnoreList() end,
            order = 4
        },
        clearignore = {
            type = "execute",
            name = 'clearignore',
            desc = "Unignore all characters",
            func = function() addon:clearIgnoreList() end,
            order = 5
        },
        ignore = {
            type = "input",
            name = "toggleignore",
            usage = "<Realm>.<Character>",
            desc = "Toggle ignoring a certain character so it doesn't get displayed. Note that the gui will not be updated until you /reload",
            get = false,
            set = function(info, character_key) addon:toggleIgnoreCharacter(character_key) end,
            order = 3
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

function addon:getProgressTable()
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
        return addon:mergeTables(chars_120, chars_other)
    else
        return nil
    end
end

--[[
====== Print stuff to user functions
--]]

function addon:showProgress()
    local ordered_chars = addon:getProgressTable()
    if ordered_chars ~= nil then
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
                    line = line.." \124cFFFF0000"..v.Progress_azerite.."/36K\124r"
                end
            else
                line = line.." \124c0000FFFFN/A\124r"
            end
--[[
            -- seems that in 8.1 this world quest was removed (couldn't find any info about it)
            -- so for now we just don't show the completion state
            -- everyone can do the world quest
            if v.Finished_xp == true then
                line = line.." -- \124cFF00FF00Done\124r"
            elseif v.Finished_xp == false then
                line = line.." -- \124cFFFF0000Open\124r"
            end
--]]
            data_lines = data_lines..line.."\n"
        end

        addon:printToChat(data_header..data_lines);
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

function addon:showGui()
    local col1_width = 0.5
    local col2_width = 0.5
    --local col3_width = 0.2

    if self.panel == nil then
        self.label_current_character = {};
        self.panel = self.GUI:Create("Window")
        self.panel:EnableResize(false)
        self.panel:SetWidth(350)
        self.panel:SetHeight(450)
        self.panel:SetTitle("Island expeditions weekly tracker")
        self.panel:SetLayout("Flow")

        local rowcontainer = self.GUI:Create("SimpleGroup")
        rowcontainer:SetFullWidth(true)
        rowcontainer:SetLayout("Flow")

        local label = self.GUI:Create("Label")
        label:SetText("Character")
        label:SetRelativeWidth(col1_width)
        label:SetHeight(20)
        label:SetColor(1,1,0)
        label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
        rowcontainer:AddChild(label)
        local label = self.GUI:Create("Label")
        label:SetText("Collected azerite")
        label:SetJustifyH("RIGHT")
        label:SetRelativeWidth(col2_width)
        label:SetHeight(20)
        label:SetColor(1,1,0)
        label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
        rowcontainer:AddChild(label)
--[[
        local label = self.GUI:Create("Label")
        label:SetText("WQ")
        label:SetJustifyH("RIGHT")
        label:SetRelativeWidth(col3_width)
        label:SetHeight(20)
        label:SetColor(1,1,0)
        label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
        rowcontainer:AddChild(label)
--]]
        self.panel:AddChild(rowcontainer)

        local line = self.GUI:Create("SimpleGroup")
        line:SetLayout("Flow")
        line:SetFullWidth(true)
        local tex = line.frame:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        tex:SetColorTexture(1, 1, 0, .8)
        self.panel:AddChild(line)

        local scrollcontainer = self.GUI:Create("SimpleGroup")
        scrollcontainer:SetFullWidth(true)
        scrollcontainer:SetFullHeight(true)
        scrollcontainer:SetLayout("Fill")

        self.panel:AddChild(scrollcontainer)

        local scroll = self.GUI:Create("ScrollFrame")
        scroll:SetLayout("Flow")
        scrollcontainer:AddChild(scroll)

        local ordered_chars = addon:getProgressTable()
        local prev_realm = ""
        if ordered_chars ~= nil then
            for i = 1, #ordered_chars do
                local v = IslandExpeditionsWeeklyDB.Characters[ordered_chars[i]]

                local rowcontainer = self.GUI:Create("SimpleGroup")
                rowcontainer:SetFullWidth(true)
                rowcontainer:SetLayout("Flow")

                if prev_realm ~= v.Realm then
                    local label = self.GUI:Create("Label")
                    label:SetText("------"..v.Realm.."------")
                    label:SetJustifyH("CENTER")
                    label:SetColor(0,1,1)
                    label:SetFullWidth(true)
                    label:SetHeight(20)
                    label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
                    rowcontainer:AddChild(label)
                    prev_realm = v.Realm
                end

                local label = self.GUI:Create("Label")
                label:SetText(v.Name)
                label:SetRelativeWidth(col1_width)
                label:SetHeight(20)
                label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
                rowcontainer:AddChild(label)

                local label_progress = self.GUI:Create("Label")
                label_progress:SetRelativeWidth(col2_width)
                label_progress:SetHeight(20)
                label_progress:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
                label_progress:SetJustifyH("RIGHT")
                if v.level == 120 then
                    if v.Finished_azerite then
                        label_progress:SetText('Done')
                        label_progress:SetColor(0,1,0)
                    else
                        label_progress:SetText(v.Progress_azerite..'/36K')
                        label_progress:SetColor(1,0,0)
                    end
                else
                    label_progress:SetText("N/A")
                    label_progress:SetColor(0,1,1)
                end
                rowcontainer:AddChild(label_progress)

--[[
                local label_wq = self.GUI:Create("Label")
                label_wq:SetRelativeWidth(col3_width)
                label_wq:SetHeight(20)
                label_wq:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
                label_wq:SetJustifyH("RIGHT")
                if v.Finished_xp then
                    label_wq:SetText("DONE")
                    label_wq:SetColor(0,1,0)
                else
                    label_wq:SetText("OPEN")
                    label_wq:SetColor(1,0,0)
                end
                rowcontainer:AddChild(label_wq)
--]]
                if (v.Name == addon.name) then
                    self.label_current_character['progress'] = label_progress
                    -- self.label_current_character['wq'] = label_wq
                end
                scroll:AddChild(rowcontainer)
            end
        end
    else
        if (self.label_current_character ~= nil) then
            local current_progress = IslandExpeditionsWeeklyDB.Characters[addon.key]
            if current_progress.level == 120 then
                if current_progress.Finished_azerite then
                     self.label_current_character['progress']:SetText('Done')
                     self.label_current_character['progress']:SetColor(0,1,0)
                else
                     self.label_current_character['progress']:SetText(current_progress.Progress_azerite..'/36K')
                     self.label_current_character['progress']:SetColor(1,0,0)
                end
            else
                 self.label_current_character['progress']:SetText("N/A")
                 self.label_current_character['progress']:SetColor(0,1,1)
            end
        end
        self.panel:Show()
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
