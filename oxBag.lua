local debug	-- debug(msg)

ItemDB = {

}


local frame = CreateFrame("FRAME", "FooAddonFrame");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("ITEM_PUSH");
frame:RegisterEvent("DELETE_ITEM_CONFIRM");
frame:RegisterEvent("BAG_UPDATE");
frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
frame:RegisterEvent("BANKFRAME_OPENED");

function debug(msg)
  if ( DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.35, 0.15)
  end
end

function info(msg)
  if ( DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage(msg, 0.2, 1.0, 0.15)
  end
end

local function eventHandler(self, event, ...)
  debug("Got event " .. event)
  if event == "ADDON_LOADED" then
    name = ...

    if name == "oxBag" then
      info("oxBag loaded")

      InstallHooks()
    end
  end

  if event == "BAG_UPDATE" then
    bagID = ...

    -- ignore bag updates for bank slots, they are fired upon login, but we can only access the bank while it is open
    --if bagID < 5 then
      OnBagUpdate(bagID)
    --end
  end

  if event == "PLAYERBANKSLOTS_CHANGED" then
    -- we do not get any information about which bank slot has changed, so we need to check all
    for bagID = 5, 11 do
      OnBagUpdate(bagID)
    end

    OnBagUpdate(-1)
  end

  if event == "BANKFRAME_OPENED" then
    -- we do not get any information about which bank slot has changed, so we need to check all
    for bagID = 5, 11 do
      OnBagUpdate(bagID)
    end

    OnBagUpdate(-1)
  end
end
frame:SetScript("OnEvent", eventHandler);

function OnBagUpdate(bagID)
  local numSlots = GetContainerNumSlots(bagID)
  --debug("Container " .. bagID .. " has " .. numSlots .. " slots")

  -- empty the stored bag
  ItemDB[bagID] = {}

  -- the actual bag slots begin with 1 and end with numSlots. index 0 is the bag itself
  for slot = 1, numSlots + 1 do
    local itemLink = GetContainerItemLink(bagID, slot)

    -- ignore empty bag slots
    if itemLink then
      local _, itemCount = GetContainerItemInfo(bagID, slot)

      --debug("Storing " .. itemCount .. " of " .. itemLink .. " in " .. bagID)

      -- store itemLink and count in our database
      if ItemDB[bagID][itemLink] == nil then
        ItemDB[bagID][itemLink] = itemCount
      else
        ItemDB[bagID][itemLink] = ItemDB[bagID][itemLink] + itemCount
      end
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

  GameTooltip:HookScript("OnTooltipSetItem", function(tooltip, ...)
    local name, link = tooltip:GetItem()

    inBag, inBank, total = GetItemCount(link)

    GameTooltip:AddDoubleLine("Total: " .. total, "Bags: " .. inBag .. ", Bank:" .. inBank)
    GameTooltip:Show()
  end)
end

function GetItemCount(needle)
  inBag = 0
  inBank = 0
  total = 0

  for bagID, bag in pairs(ItemDB) do
    for itemLink, count in pairs(bag) do
      if itemLink == needle then
        -- bags with an ID greater or equal 7 are bank slots
        if bagID >= 5 or bagID == -1 then
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
