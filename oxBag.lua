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
    if not ItemDB then
      ItemDB = {}
    end
    InstallHooks()
  end

  if event == "BANKFRAME_OPENED" then
    -- scan the whole bank, including bags
    for bagID in BAGIDS_BANK do
      UpdateBag(bagID)
    end
  end

  if event == "BAG_UPDATE" then
    -- update the specific bag
    UpdateBag(arg1)
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

  -- empty the stored bag
  ItemDB[bagID] = {}

  -- the actual bag slots begin with 1 and end with numSlots. index 0 is the bag itself
  for slot = 1, numSlots + 1 do
    local itemLink = GetContainerItemLink(bagID, slot)

    -- ignore empty bag slots
    if itemLink then
      local _, itemCount = GetContainerItemInfo(bagID, slot)

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
end

function GetItemCount(needle)
  inBag = 0
  inBank = 0
  total = 0

  for bagID, bag in ItemDB do
    for itemLink, count in bag do
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
