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
                addon.printToChat("DB reset succesful. Please '/reload'")
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon.realm = GetRealmName()
        addon.name = UnitName("player")
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
                Progress = 0,
                Finished = false
            } ]]
        }
    }
end

function addon.storeProgress()
    local finished = IsQuestFlaggedCompleted(53435)
    if finished == false then
        local text, type, finished_fake, progress, needed = GetQuestObjectiveInfo(53435,1,false);

        IslandExpeditionsWeeklyDB.Characters[addon.key] = {
            Realm = addon.realm,
            Name = addon.name,
            Finished = finished,
            Progress = progress
        }
    else
        IslandExpeditionsWeeklyDB.Characters[addon.key] = {
            Realm = addon.realm,
            Name = addon.name,
            Finished = finished,
            Progress = nil
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

        for i = 1, #ordered do
            local line = ""
            local v = IslandExpeditionsWeeklyDB.Characters[ordered[i]]
            local line = "\124c0000FFFF"..v.Realm.."\124r "..v.Name
            if v.Finished then
                line = line.." \124cFF00FF00Finished!\124r"
            else
                line = line.." \124cFFFF0000"..v.Progress.."/40000\124r"
            end
            addon.printToChat(line);
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

