-- Field Decon Kit — context menu wiring.
-- Self-contained: does not modify TheArk's BWOAMenu, just adds its own
-- OnFillWorldObjectContextMenu and OnFillInventoryObjectContextMenu hooks.

FieldDeconMenu = FieldDeconMenu or {}

local SPRAY_TYPE  = "Base.Decon9"
local TABLET_TYPE = "Bandits.NBCTablets"

local function findEquippedSpray(player)
    local prim = player:getPrimaryHandItem()
    if prim and prim:getFullType() == SPRAY_TYPE then return prim end
    local sec = player:getSecondaryHandItem()
    if sec and sec:getFullType() == SPRAY_TYPE then return sec end
    return nil
end

FieldDeconMenu.SprayDecontaminate = function(player, square, spray)
    if not luautils.walkAdj(player, square, true) then return end
    ISTimedActionQueue.add(TADecontaminate:new(player, spray, square))
end

FieldDeconMenu.RefillSpray = function(player, spray)
    local inv = player:getInventory()
    local tablet = inv:getFirstTypeRecurse(TABLET_TYPE)
    if not tablet then return end
    inv:Remove(tablet)
    if instanceof(spray, "DrainableComboItem") then
        spray:setUsedDelta(1.0)
    end
    HaloTextHelper.addGoodText(player, "Spray Refilled")
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local spray = findEquippedSpray(player)
    if not spray then return end

    local square
    for _, wo in ipairs(worldObjects) do
        local sq = wo:getSquare()
        if sq then square = sq; break end
    end
    if not square then return end

    context:addOption("Decontaminate Area", player, FieldDeconMenu.SprayDecontaminate, square, spray)
end

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local item = items[1]
    if not instanceof(item, "InventoryItem") then
        item = items[1].items[1]
    end
    if not item or item:getFullType() ~= SPRAY_TYPE then return end

    local option = context:addOption("Refill with NBC Tablets", player, FieldDeconMenu.RefillSpray, item)
    local hasTablet = player:getInventory():containsTypeRecurse(TABLET_TYPE)
    if not hasTablet then
        local tooltip = ISToolTip:new()
        option.notAvailable = true
        tooltip.description = "Need NBC Tablets"
        option.toolTip = tooltip
    end
end

Events.OnFillWorldObjectContextMenu.Remove(onFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

Events.OnFillInventoryObjectContextMenu.Remove(onFillInventoryObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
