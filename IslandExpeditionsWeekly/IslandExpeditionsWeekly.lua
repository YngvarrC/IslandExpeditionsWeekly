--[[
==============
==============                   IslandExpeditionsWeekly
==============              An addon by Lyrenia - EU - Draenor
==============  Keep track of your island expeditions weekly quest progress
==============
--]]

local addon = CreateFrame("FRAME", "IslandExpeditionsWeekly", UIParent);
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("ISLAND_AZERITE_GAIN")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")

addon:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "IslandExpeditionsWeekly" then
        if IslandExpeditionsWeeklyDB == nil then
            addon.initDB()
        end

       -- addon.panel = addon.createUI()

        -- Slash Command List
        SLASH_IslandExpeditionsWeekly1 = "/islandexpeditionsweekly";
        SLASH_IslandExpeditionsWeekly2 = "/iew";
        SlashCmdList["IslandExpeditionsWeekly"] = function(cmd)
            if not cmd or cmd == "" then
                local text = "List of available commands:"..
                "\n\124c0000FFFFshow\124r: Show the progress for the weekly on all characters (Note: Only those logged in since using the addon)"..
                "\n\124c0000FFFFreset\124r: Reset the database. This will clear all your characters progress!"..
                "\nNote that both /islandexpeditionsweekly and /iew work for slash commands"
                addon.printToChat(text)
            elseif cmd == "show" then
                addon.showProgress()
            --    addon.panel:Show()
            elseif cmd == "reset" then
                addon.initDB()
                addon.printToChat("DB reset succesful. Please '/reload' to fetch current character progress")
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon.realm = GetRealmName()
        addon.name = UnitName("player")
        addon.playerlevel = UnitLevel("player")
        addon.key = format("%s.%s", addon.realm, addon.name)
        addon.storeProgress()
    elseif event == "ISLAND_AZERITE_GAIN" then
        addon.storeProgress()
    end
end)


function addon.initDB()
    IslandExpeditionsWeeklyDB = {
        Characters = {
        --[[    ["Realm.Name"] = {
                Realm = "some realm",
                Name = "some name",
                level = player level integer,
                Finished_azerite = finished azerite quest?, 120 level only
                Progress_azerite = progress azerite quest,
                Finished_xp = finished weekly xp WQ? [110-119] level range
            } ]]
        }
    }
end

function addon.storeProgress()
    -- track weekly azerite quest for 120+
    local finished_azerite = IsQuestFlaggedCompleted(53435)
    local progress_azerite = 0
    if finished_azerite == false then
        local text, type, finished_fake, progress, needed = GetQuestObjectiveInfo(53435,1,false);
        progress_azerite = progress
    end

    -- track weekly xp WQ for 110-119 characters
    local finished_xp = nil
    local faction, localizedfaction = UnitFactionGroup("player");
    if faction == "Horde" then
        finished_xp = IsQuestFlaggedCompleted(54166)
    elseif faction == "Alliance" then
        finished_xp = IsQuestFlaggedCompleted(54167)
    end

    if addon.playerlevel >= 110 then
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

function addon.printToChat(text)
    DEFAULT_CHAT_FRAME:AddMessage("\124cFFFFFF00[IEW] "..text.."\124r")
end

function addon.showProgress()
    if IslandExpeditionsWeeklyDB ~= nil then
        local ordered = {}
        for key in pairs(IslandExpeditionsWeeklyDB.Characters) do
            table.insert(ordered, key)
        end
        table.sort(ordered)

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
            elseif v.level >= 110 and v.level <= 119 then
                if v.Finished_xp == true then
                    line_xp = line_xp..line.." \124cFF00FF00Finished xp quest!\124r\n"
                elseif v.Finished_xp == false then
                    line_xp = line_xp..line.." \124cFFFF0000Xp quest not completed!\124r\n"
                end
            end
        end

        if string.len(line_max) > 0 then
            addon.printToChat(line_max_header..line_max);
        end
        if string.len(line_xp) > 0 then
            addon.printToChat(line_xp_header..line_xp);
        end
    else
        addon.printToChat("no data!")
    end
end

function addon.createUI()
    local panel = CreateFrame("Frame", "IslandExpeditionsWeeklyFrame", UIParent, "UIPanelDialogTemplate")
    panel:Hide()
    panel:SetPoint("LEFT", 20, 0)
    panel:SetSize(300, 500)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:SetToplevel(true)
    panel:RegisterForDrag("LeftButton")
    panel:HookScript("OnDragStart", function(self) self:StartMoving() end)
    panel:HookScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    panel.Title:SetText("Island Expeditions Weekly Progress")

    return panel
end

