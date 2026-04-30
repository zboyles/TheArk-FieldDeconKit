require "TimedActions/ISBaseTimedAction"

TADecontaminate = ISBaseTimedAction:derive("TADecontaminate")

local function predicateAll(item)
    return true
end

local CHARGE_PER_SPRAY = 0.05
local SCRUB_RADIUS = 5  -- square radius around player; (2R+1)^2 tiles total

local function scrubArea(character)
    local cell = getCell()
    local cx = math.floor(character:getX())
    local cy = math.floor(character:getY())
    local cz = character:getZ()

    local seenVehicles = {}
    for dy = -SCRUB_RADIUS, SCRUB_RADIUS do
        for dx = -SCRUB_RADIUS, SCRUB_RADIUS do
            local sq = cell:getGridSquare(cx + dx, cy + dy, cz)
            FieldDecon.ScrubSquare(sq)
            if sq then
                local ok, v = pcall(function() return sq:getVehicleContainer() end)
                if ok and v then
                    local id = tostring(v)
                    if not seenVehicles[id] then
                        seenVehicles[id] = true
                        FieldDecon.ScrubVehicle(v)
                    end
                end
            end
        end
    end

    -- explicitly scrub the wielder's inventory in case square:getPlayer() misses
    local items = ArrayList.new()
    character:getInventory():getAllEvalRecurse(predicateAll, items)
    for i = 0, items:size() - 1 do
        items:get(i):getModData().radiated = false
    end
end

local function spawnMist(character)
    local cx, cy, cz = character:getX(), character:getY(), character:getZ()
    local offset = -3 * cz
    local span = SCRUB_RADIUS * 2
    for i = 1, 12 do
        local effect = {
            x = cx - SCRUB_RADIUS + ZombRand(span + 1) + offset,
            y = cy - SCRUB_RADIUS + ZombRand(span + 1) + offset,
            z = 0,
            size = 320,
            name = "mist",
            frameCnt = 40,
            frameRnd = true,
            repCnt = 12,
            colors = {r = 0.9, g = 0.9, b = 1.0, a = 0.2},
        }
        if BWOAEventControl and BWOAEventControl.Add then
            BWOAEventControl.Add("Effect", effect, 1 + (i * 6) + ZombRand(8))
        end
    end
end

function TADecontaminate:isValid()
    if not self.spray then return false end
    -- spray is valid as long as the character still has it on them — covers
    -- held, attached to a bag slot, or loose in inventory
    return self.spray:getContainer() ~= nil
end

function TADecontaminate:update() end

function TADecontaminate:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Mid")
    if self.square then
        self.character:faceLocationF(self.square:getX() + 0.5, self.square:getY() + 0.5)
    end
    local emitter = self.character:getEmitter()
    if emitter then emitter:playSound("AmbientMist") end
end

function TADecontaminate:stop()
    ISBaseTimedAction.stop(self)
end

function TADecontaminate:perform()
    scrubArea(self.character)
    spawnMist(self.character)
    -- charge tracking parked until the runtime drainable API is confirmed
    ISBaseTimedAction.perform(self)
end

function TADecontaminate:new(character, spray, square)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.spray = spray
    o.square = square
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 120
    return o
end

return TADecontaminate
