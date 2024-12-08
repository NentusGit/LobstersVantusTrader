local lobstersVantusFrame = CreateFrame("Frame", "LobstersVantusFrame")
lobstersVantusFrame:RegisterEvent("TRADE_SHOW")
lobstersVantusFrame:RegisterEvent("TRADE_CLOSED")
lobstersVantusFrame:RegisterEvent("BAG_UPDATE_DELAYED")

local vantusIds = {
    -- Just add a new entry for each tier.
    226036, -- Nerub-ar Palace R3
}


function LVTRuneTrade(bagId,slot)
    local itemInfo = C_Container.GetContainerItemInfo(bagId,slot)
    if not itemInfo then return false end
    if itemInfo.stackCount > 1 then
        ClearCursor()
        SplitContainerItem(bagId,slot,1)
        ClickTradeButton(1)
        return true
    else
        C_Container.PickupContainerItem(bagId,slot)
        ClickTradeButton(1)
        return true
    end
end


function LVTcountVantusRunes()
    local total = 0
    for bagId = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bagId)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bagId, slot)
            if itemInfo then
                local itemId = itemInfo.itemID
                if LVTIsVantusRune(itemId) then
                    total = total + itemInfo.stackCount
                end
            end
        end
    end
    return total
end


local function createTradeWindow()
    local container = CreateFrame("Frame", "LobstersVantusTradeContainer", TradeFrame, "DefaultPanelTemplate" )
    container:SetSize(150,100)
    container:SetPoint("BOTTOMLEFT", TradeFrame, "BOTTOMRIGHT", 10, 0)

    LobstersVantusTradeContainerTitleText:SetText("Vantus Trader")

    local counter = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    counter:SetPoint("TOP", container, "CENTER", 0,0)
    container.counter = counter
    
    function container:UpdateCounter()
        local count = LVTcountVantusRunes()
        local color = count > 0 and "00FF00" or "FF0000"
        counter:SetText(string.format("|cFF%sAvailable Runes: %d|r", color, count))
    end

    local button = CreateFrame("Button", "VantusTradeButton", container, "UIPanelButtonTemplate")
    button:SetSize(120, 25)
    button:SetPoint("TOP", counter, "BOTTOM", 0, -5)
    button:SetText("Insert a Vantus Rune")

    button:SetScript("OnClick", function()
        local bagId, slot = LVTFindVantusRune()
        if bagId and slot then
            if LVTRuneTrade(bagId,slot) then
                container:UpdateCounter()
            else
                print("|cFFee5555[LobstersVantusTrade]|r Failed to trade.")
            end
        else
            print("|cFFee5555[LobstersVantusTrade]|r No runes found in your inventory.")

        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to insert a rune.")
        local count = LVTcountVantusRunes()
        GameTooltip:AddLine(string.format("You have %d Vantus Rune%s available", count, count == 1 and "" or "s"), 0, 1, 0, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    container:Hide()
    return container
end

function LVTIsVantusRune(itemId)
    for _, runeId in ipairs(vantusIds) do
        if itemId == runeId then
            return true
        end
    end
    return false
end

function LVTFindVantusRune()
    for bagId = 0,4 do
        local numSlots = C_Container.GetContainerNumSlots(bagId)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bagId, slot)
            if itemInfo then
                local itemId = itemInfo.itemID
                if LVTIsVantusRune(itemId) then
                    return bagId, slot
                end
            end
        end
    end
    return nil
end

local tradeContainer = createTradeWindow()

lobstersVantusFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRADE_SHOW" then
        tradeContainer:Show()  
        tradeContainer:UpdateCounter()
    elseif event == "TRADE_CLOSED" then
        tradeContainer:Hide()
    elseif event == "BAG_UPDATE_DELAYED" then
        if tradeContainer:IsVisible() then
            tradeContainer:UpdateCounter()
        end
    end
end)

local function OnSlashCommand(msg)
    print("|cFFee5555[LobstersVantusTrade]|r Ready to trade Vantus Runes!")
    -- Show current rune count when using slash command
    local count = LVTcountVantusRunes()
    print(string.format("|cFFee5555[LobstersVantusTrade]|r You currently have %d Vantus Rune%s in your bags.", 
        count, count == 1 and "" or "s"))
end

-- Register our slash command
SLASH_LOBSTERSVANTUSTRADE1 = "/lvt"
SlashCmdList["LOBSTERSVANTUSTRADE"] = OnSlashCommand
