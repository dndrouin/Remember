--Remember addon by Danielle Drouin, github.com/dndrouin

--variables

local numReminders = 0
local reminders = {}
local checkboxes = {}
local showing = true
local maxed = false
local currentOffset = -20
local checkboxId = 0

--fonts

local arial = "Interface\\AddOns\\Remember\\Fonts\\arial.ttf"
local ariali = "Interface\\AddOns\\Remember\\Fonts\\ariali.ttf"
local arialb = "Interface\\AddOns\\Remember\\Fonts\\arialbd.ttf"

--frames

--the main window
local mainWindow = CreateFrame("Frame", "main", UIParent, nil)
mainWindow:SetSize(200,300)
mainWindow:SetPoint("CENTER")
mainWindow:SetMovable(true)
mainWindow:EnableMouse(true)
mainWindow:RegisterForDrag("LeftButton")
mainWindow:SetScript("OnDragStart", mainWindow.StartMoving)
mainWindow:SetScript("OnDragStop", mainWindow.StopMovingOrSizing)

--the top bar with the arrow and num reminders
local topBar = CreateFrame("Frame", "bar", mainWindow, nil)
topBar:SetSize(200,20)
topBar:SetPoint("TOP")

topBar.color = topBar:CreateTexture(nil, "BACKGROUND")
topBar.color:SetAllPoints(true)
topBar.color:SetColorTexture(1.0, 1.0, 1.0, 0.2)

--the button to expand and contract the reminders
local expandButton = CreateFrame("Button", "expand", topBar, nil)
expandButton:SetPoint("LEFT", topBar)
expandButton:SetSize(20,20)
expandButton.text = expandButton:CreateFontString(nil, "expand")
expandButton.text:SetFont(arial, 9)
expandButton.text:SetTextColor(1.0, 1.0, 1.0, 1.0)

expandButton.text:SetPoint("LEFT", topBar, 5, 0)

expandButton.header = mainWindow:CreateFontString(nil, "header")
expandButton.header:SetPoint("CENTER", topBar)
expandButton.header:SetFont(arialb, 12)
expandButton.header:SetText(numReminders.." Reminders")

--the frame that the reminders are placed in
local containsReminders = CreateFrame("Frame", "cR", mainWindow, nil)
containsReminders:SetPoint("CENTER")
containsReminders:SetSize(200, 180)

expandButton:SetScript("OnClick", function()
    if(maxed == false) then
        --if window isnt maximized, maximize it and change the button's symbol
        expandButton.text:SetText("▲")
        containsReminders:Show()
        maxed = true
    else
        --if window is maximized, minimize it and change the button's symbol as well
        expandButton.text:SetText("▼")
        containsReminders:Hide()
        maxed = false
    end
end)

--TODO: options?

--functions

--creates the reminder "checkbox" to be placed in containsReminders
local function createCheckbox(args)
    --increment checkboxid by one so it can have a unique name
    checkboxId = checkboxId + 1
    currentOffset = currentOffset - 30


    local check = CreateFrame("Frame", "checkbox"..checkboxId, containsReminders, nil)


    --note: around 28 characters means a full row of characters when check is 100px wide
    --counts how many lines of text args is and rounds up to get the size multiplier that helps calculate the frame length
    local length = string.len(args)
    local sizeMultiplier = math.ceil(length/28)

    --place check within the containsReminders container
    check:SetPoint("TOPLEFT", topBar, 0, 10 + currentOffset)
    check:SetSize(100,sizeMultiplier*10)

    --create actual box for user to click
    check.box = check:CreateFontString(nil, "checkboxBox"..checkboxId)
    check.box:SetTextColor(0.8, 0.8, 0.8, 1.0)
    check.box:SetFont(ariali, 11)
    check.box:SetPoint("TOPLEFT", check, 0, 0)
    check.box:SetText("IN PROGRESS")

    --create text next to check box
    check.text = check:CreateFontString(nil, "checkboxText"..checkboxId)
    check.text:SetPoint("TOPLEFT", check, 30,-10)
    check.text:SetPoint("TOPRIGHT", check, 100, -10)
    check.text:SetJustifyV("TOP");
    check.text:SetJustifyH("LEFT");
    check.text:SetTextColor(1.0, 1.0, 1.0, 1.0)
    check.text:SetFont(arial, 11)
    check.text:SetText(args)

    --to make space for the next reminder when the length is over 1 line, repeatedly add a line of space to offset
    while(sizeMultiplier > 1) do
        currentOffset = currentOffset - 11
        sizeMultiplier = sizeMultiplier - 1
    end

    --check reacts when user clicks it
    check:SetScript("OnMouseDown", function(self,button)
        --if user clicks with left button, mark the reminder as COMPLETED
        if(button == "LeftButton") then
        check.box:SetTextColor(0.03, 1.0, 0.1, 1.0)
        check.box:SetText("COMPLETED")
        elseif(button == "RightButton") then
            --if user clicks with right button, ask if they want to delete or mark it uncomplete
            --TODO: this
        end
    end)

    return check;
end

local function reminderExists(args)
    --returns true if reminder already exists
    local doesIt = tContains(reminders, args)
    return doesIt
end

local function addReminder(args)
    --add a reminder to the list
    --store a copy of args as lowercase so caps don't give different results when checking if exists
    local argsLower = string.lower(args)
    --check if reminder already exists
    if(reminderExists(argsLower) == true) then
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Reminder for "..args.." already exists!");
    else
        --if doesn't already exist, add it to reminders table (but as lowercase for easy duplicate checking)
        table.insert(reminders,argsLower)
        --also make a checkbox for it and add it to the checkboxes table
        table.insert(checkboxes, createCheckbox(args))
        --increase numReminders by 1
        numReminders = numReminders + 1
        --change text
        expandButton.header:SetText(numReminders.." Reminders")
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Reminder for "..args.." has been added.");
    end
end

--[[
local function removeReminder(args)
    --remove a reminder from the list
    local indexAt
    --make args lowercase so caps don't give different results when checking if exists
    args = string.lower(args)
    --make sure reminder is on list first
    if(reminderExists(args) == true) then
        --find the reminder's index in the table
        for index,value in ipairs(reminders) do
            i1, i2 = string.find(value,args)
            --if the string could be found, then store the current index in indexAt
            if(i1 ~= nil and i2 ~= nil) then
                indexAt = index
            end
        end
        --then remove the reminder at indexAt
        table.remove(reminders, indexAt)
        --remove a reminder from numReminders
        numReminders = numReminders - 1
        --change text
        mainWindow.text:SetText("You have "..numReminders.." reminders")
        --realign text
        moveUp()
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Reminder for "..args.." has been removed.");
    else
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Reminder for "..args.." doesn't exist!");
    end
end
]]--

--returns 1 or 0 based on if player is horde or alliance
local function getFaction()
    local faction = UnitFactionGroup("Player")
    if(faction == "Alliance") then
        --player must be alliance
        return 1
    else
        --player must be horde
        return 0
    end
end

--returns true or false based on if the player is currently in a city
local function isInCity()
    local zone = GetZoneText()
    local faction = getFaction()
    if(faction == 1) then
        --player is alliance
        if(zone == "Stormwind City" or zone == "Ironforge" or zone == "Darnassus") then
            --player must be in a city
            return true;
        end
    else
        --player is horde
        if(zone == "Orgrimmar" or zone == "Thunder Bluff" or zone == "Undercity") then
            --player must be in a city
            return true;
        end
    end
    --player is not in a city
    return false;
end



local function showMinimized()
    --show minimized, undetailed version of window when outside of city
    maxed = false
    expandButton.text:SetText("▼")
    containsReminders:Hide()
end

local function showMaximized()
    maxed = true
    expandButton.text:SetText("▲")
    containsReminders:Show()
end

local function updateWindow()
    if(isInCity() == false) then
        showMinimized()
    else
        showMaximized()
    end
end

local function hideWindow()
    if(showing == true) then
        mainWindow:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Window hidden!");
        showing = false
    else
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Window is already hidden.");
    end
end

local function showWindow()
    if(showing == false) then
        mainWindow:Show()
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Window un-hidden!");
        showing = true
    else
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Window is already showing.");
    end
end


--creating slash commands for use in chat
SLASH_REMEMBER1 = "/remember"
SlashCmdList["REMEMBER"] = function(msg)
    local args
    local actionCompleted = false
    --checks if user has included the add command after /remember (example: /remember add buy arrows)
    i1, i2 = string.find(msg,"add")
    if(i1 == 1 and i2 == 3) then
        --removes "add" and spaces from the string received so it's just the arguments
        args = string.sub(msg,5)
        --if user didn't enter any arguments after the command, tells them
        if(string.len(args) == 0) then
            DEFAULT_CHAT_FRAME:AddMessage("Remember: Add what? To add a reminder: /remember add call mom");
        else
            addReminder(args)
            updateWindow()
        end
        --mark actionCompleted as true because user entered a valid command
        actionCompleted = true
    end

    --checks if user has included the remove command after /remember (example: /remember remove buy arrows)
    i1, i2 = string.find(msg,"remove")
    if(i1 == 1 and i2 == 6) then
        --removes "remove" and spaces from the string received so it's just the arguments
        args = string.sub(msg,8)
        --if user didn't enter any arguments after the command, tells them
        if(string.len(args) == 0) then
            DEFAULT_CHAT_FRAME:AddMessage("Remember: Remove what? To remove a reminder: /remember remove call mom");
        else
            removeReminder(args)
            updateWindow()
        end
        --mark actionCompleted as true because user entered a valid command
        actionCompleted = true
    end

    --checks if user has included the help command after /remember (example: /remember help)
    i1, i2 = string.find(msg, "help")
    if(i1 == 1 and i2 == 4) then
        --user is asking for help, so give them help with syntax
        DEFAULT_CHAT_FRAME:AddMessage("Remember Help:")
        DEFAULT_CHAT_FRAME:AddMessage("To add a reminder: /remember add call mom")
        DEFAULT_CHAT_FRAME:AddMessage("To remove a reminder: /remember remove buy enchants")
        DEFAULT_CHAT_FRAME:AddMessage("To hide or show the window: /remember hide, /remember show")
        --mark actionCompleted as true because user entered a valid command
        actionCompleted = true
    end

    --checks if user has included the hide command after /remember (example: /remember hide)
    i1, i2 = string.find(msg, "hide")
    if(i1 == 1 and i2 == 4) then
        --user is asking for help, so give them help with syntax
        hideWindow()
        --mark actionCompleted as true because user entered a valid command
        actionCompleted = true
    end

    --checks if user has included the hide command after /remember (example: /remember hide)
    i1, i2 = string.find(msg, "show")
    if(i1 == 1 and i2 == 4) then
        --user is asking for help, so give them help with syntax
        showWindow()
        --mark actionCompleted as true because user entered a valid command
        actionCompleted = true
    end

    if(i1 == nil and i2 == nil and actionCompleted == false) then
        --user has not input any commands, so let them know what commands they can use
        DEFAULT_CHAT_FRAME:AddMessage("Remember: Invalid command entered. Try /remember help for a list of commands.")
    end

end


--events
mainWindow:RegisterEvent("PLAYER_LOGIN")
mainWindow:RegisterEvent("ZONE_CHANGED_NEW_AREA")

mainWindow:SetScript("OnEvent", function(self,event,...)
    if(event == "PLAYER_LOGIN") then
        --show minimized frame if user is not in city, show maximized frame if user is in city
        updateWindow()
    end
    if(event == "ZONE_CHANGED_NEW_AREA") then
        --show minimized frame if user is not in city, show maximized frame if user is in city
        updateWindow()
    end
end)


