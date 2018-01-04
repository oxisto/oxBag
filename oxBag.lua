local debug	-- debug(msg)

ItemDB = {

}

local frame = CreateFrame("FRAME", "FooAddonFrame");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("ITEM_PUSH");
frame:RegisterEvent("DELETE_ITEM_CONFIRM");
frame:RegisterEvent("BAG_UPDATE");
frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED");

function debug(msg)
  if ( DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.35, 0.15)
  end
end

local tooltip = CreateFrame("Frame","oxBagTooltip", GameTooltip)
tooltip:SetScript("OnShow", function()
  if GameTooltip.itemLink then
    inBag, inBank, total = GetItemCount(GameTooltip.itemLink)
    GameTooltip:AddLine(inBag .. " in bags")
    GameTooltip:AddLine(inBank .. " in bank")
    GameTooltip:AddLine(total .. " total")
    GameTooltip:Show()
  end
end)

local function eventHandler()
  if event == "ADDON_LOADED" and arg1 == "oxBag" then
    InstallHooks()
  end

  if event == "BAG_UPDATE" then
    bagID = arg1

    -- ignore bag updates for bank slots, they are fired upon login, but we can only access the bank while it is open
    if bagID < 5 then
      OnBagUpdate(bagID)
    end
  end

  if event == "PLAYERBANKSLOTS_CHANGED" then
    -- we do not get any information about which bank slot has changed, so we need to check all
    for bagID = 5, 12 do
      OnBagUpdate(bagID)
    end
  end
end
frame:SetScript("OnEvent", eventHandler);

function OnBagUpdate(bagID)
  local numSlots = GetContainerNumSlots(bagID)
  --message("Container " .. bagID .. " has " .. numSlots .. " slots")

  -- empty the stored bag
  ItemDB[bagID] = {}

  -- the actual bag slots begin with 1 and end with numSlots. index 0 is the bag itself
  for slot = 1, numSlots + 1 do
    local itemLink = GetContainerItemLink(bagID, slot)

    -- ignore empty bag slots
    if itemLink then
      local _, itemCount = GetContainerItemInfo(bagID, slot)

      --message("Storing " .. itemCount .. " of " .. itemLink .. " in " .. bagID)

      -- store itemLink and count in our database
      ItemDB[bagID][itemLink] = itemCount
    end
  end
end

function InstallHooks()
  local hookSetBagItem = GameTooltip.SetBagItem
  function GameTooltip.SetBagItem(self, bagID, slotID)
    GameTooltip.itemLink = GetContainerItemLink(bagID, slotID)
    _, GameTooltip.itemCount = GetContainerItemInfo(bagID, slotID)
    return hookSetBagItem(self, bagID, slotID)
  end
end

function GetItemCount(needle)
  inBag = 0
  inBank = 0
  total = 0

  for bagID, bag in ItemDB do
    for itemLink, count in bag do
      if itemLink == needle then
        -- bags with an ID greater or equal 7 are bank slots
        if bagID >= 5 then
          inBank = inBank + count
        else
          inBag = inBag + count
        end
        total = total + count
      end
    end
  end

  return inBag, inBank, total
end
