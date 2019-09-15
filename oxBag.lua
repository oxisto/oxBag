local debug	-- debug(msg)

BAGID_TOKENS_BAG = -4
BAGID_KEYRING = -2
BAGID_BANK_CONTENT = -1
BAGID_BACKPACK = 0
BAGID_BAG1 = 1
BAGID_BAG2 = 2
BAGID_BAG3 = 2
BAGID_BAG4 = 4
BAGID_BANK_BAG1 = 5
BAGID_BANK_BAG2 = 6
BAGID_BANK_BAG3 = 7
BAGID_BANK_BAG4 = 8
BAGID_BANK_BAG5 = 9
BAGID_BANK_BAG6 = 10

BAGIDS_BANK = { BAGID_BANK_CONTENT, BAGID_BANK_BAG1 ,BAGID_BANK_BAG2, BAGID_BANK_BAG3, BAGID_BANK_BAG4, BAGID_BANK_BAG5, BAGID_BANK_BAG6 }

local frame = CreateFrame("FRAME", "FooAddonFrame");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("BAG_UPDATE");
frame:RegisterEvent("BANKFRAME_OPENED");
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
      if not ItemDB then
        ItemDB = {}
      end

      InstallHooks()

      info("oxBag loaded")
    end
  end

  if event == "BAG_UPDATE" then
    bagID = ...

    -- update the specific bag
    UpdateBag(bagID)
  end

  if event == "PLAYERBANKSLOTS_CHANGED" then
    -- update the bank itself
    UpdateBag(BAGID_BANK_CONTENT)
  end
end
frame:SetScript("OnEvent", eventHandler);

function UpdateBag(bagID)
  -- only update bank-related bags if bank is open
  if IsBagIDInBank(bagID) and not BankFrame then
    return
  end

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
      if not ItemDB[bagID][itemLink] then
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
        if IsBagIDInBank(bagID) then
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

function IsBagIDInBank(bagID)
  return (bagID >= BAGID_BANK_BAG1 or bagID == BAGID_BANK_CONTENT)
end
