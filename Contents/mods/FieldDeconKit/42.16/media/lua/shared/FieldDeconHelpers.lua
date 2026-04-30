-- Field Decon Kit — shared helpers.
-- Namespaced under FieldDecon to avoid colliding with TheArk's BWOAEvents
-- helpers if/when the parent mod ships its own equivalents.

FieldDecon = FieldDecon or {}

local function predicateAll(item)
    return true
end

-- Clear modData.radiated on world items, bag/container contents, dead bodies
-- and their inventories, players standing on the square, and zombies on the
-- square. Does NOT drain decontaminator concentration or play voice lines.
FieldDecon.ScrubSquare = function(square)
    if not square then return end

    local player = square:getPlayer()
    if player then
        local items = ArrayList.new()
        player:getInventory():getAllEvalRecurse(predicateAll, items)
        for i = 0, items:size() - 1 do
            items:get(i):getModData().radiated = false
        end
    end

    local wobs = square:getWorldObjects()
    for i = 0, wobs:size() - 1 do
        local item = wobs:get(i):getItem()
        if item then
            item:getModData().radiated = false
            if instanceof(item, "InventoryContainer") then
                local inv = item:getInventory()
                if inv then
                    local contents = ArrayList.new()
                    inv:getAllEvalRecurse(predicateAll, contents)
                    for j = 0, contents:size() - 1 do
                        contents:get(j):getModData().radiated = false
                    end
                end
            end
        end
    end

    local objects = square:getStaticMovingObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if instanceof(object, "IsoDeadBody") then
            object:getModData().radiated = false
            local inv = object:getContainer()
            if inv then
                local items = ArrayList.new()
                inv:getAllEvalRecurse(predicateAll, items)
                for j = 0, items:size() - 1 do
                    items:get(j):getModData().radiated = false
                end
            end
        end
    end

    local chrs = square:getMovingObjects()
    for i = 0, chrs:size() - 1 do
        local chr = chrs:get(i)
        if instanceof(chr, "IsoZombie") then
            chr:getModData().radiated = false
        end
    end
end

-- Walk every part on a vehicle and clear modData.radiated on its container's
-- contents (trunk, glovebox, seat-storage). Defensively pcall-wrapped because
-- the Lua-side BaseVehicle API differs across PZ builds.
FieldDecon.ScrubVehicle = function(vehicle)
    if not vehicle then return end
    local ok, nparts = pcall(function() return vehicle:getPartCount() end)
    if not ok or not nparts then return end
    for i = 0, nparts - 1 do
        local okPart, part = pcall(function() return vehicle:getPartByIndex(i) end)
        if okPart and part then
            local okInv, inv = pcall(function() return part:getItemContainer() end)
            if okInv and inv then
                local contents = ArrayList.new()
                inv:getAllEvalRecurse(predicateAll, contents)
                for j = 0, contents:size() - 1 do
                    contents:get(j):getModData().radiated = false
                end
            end
        end
    end
end
