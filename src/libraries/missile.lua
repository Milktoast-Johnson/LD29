Missile = {
    x = 0,
    y = 0,
    xvel = 0,
    yvel = 0,
    startx = 0,
    starty = 0,
    targetx = 0,
    targety = 0,
    speed = 300,
    radius = 2,
    segments = 12,
    active = false,
    explode = 0,
    kills = 0,
    maxExplode = 3,
    explodeSize = 150,
    crit = 0,
    critMsg = "",
    isEnemy = false
}

function Missile:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Missile:reset()
    self.x = Missile.x
    self.y = Missile.y
    self.xvel = Missile.xvel
    self.yvel = Missile.yvel
    self.speed = Missile.speed
    self.radius = Missile.radius
    self.active = Missile.active
    self.explode = Missile.explode
    self.kills = 0
end

function Missile:spawn(x, y, targetx, targety)
    self.x = x
    self.y = y
    self.startx = x
    self.starty = y
    self.targetx = targetx
    self.targety = targety
    local angle = math.atan2(targety - y, targetx - x)
    self.xvel = math.cos(angle) * self.speed
    self.yvel = math.sin(angle) * self.speed
    self.active = true
    self.kills = 0
end

function Missile:update(dt)
    if self.crit > 0 then
        self.crit = self.crit - dt
        if self.crit <= 0 then
            self.crit = 0
        end
    end
    if self.explode > 0 then
        self.explode = self.explode - dt
        if self.explode <= 0 then
            self.active = false
            Signals.emit('end_explode', self.isEnemy, self.targetx, self.targety)
        end
        return
    end

    if not self.active then
        return
    end
    
    local xq1 = self.targetx - self.x
    local yq1 = self.targety - self.y
    
    self.x = self.x + self.xvel * dt
    self.y = self.y + self.yvel * dt
    
    local xq2 = self.targetx - self.x
    local yq2 = self.targety - self.y
    
    if xq1 * xq2 < 0 or yq1 * yq2 < 0 then
        self.explode = self.maxExplode
        Signals.emit('start_explode', self.isEnemy, self.targetx, self.targety)
        return
    end
    
    if self.y < 0
            or self.y > love.graphics.getHeight()
            or self.x < 0
            or self.x > love.graphics.getWidth() then
        self.active = false
    end
end

function Missile:drawMessages()
    if self.crit > 0 then
        love.graphics.setColor(255, 255, 255)
        drawStringCentered(self.critMsg, smFont, self.x, self.y)
    end
end

function Missile:draw()
    if self.explode > 0 then
        local p = (self.maxExplode - self.explode) / self.maxExplode
        local r = lerp(p, 0, self.explodeSize)
        if p > 0.5 then
            r = lerp(p, self.explodeSize, 0)
        end
        love.graphics.setColor(HSV(math.random(0,255), 255, 255))
        love.graphics.circle("fill", self.targetx, self.targety, r, self.segments)
        Signals.emit('explode', self, self.isEnemy, self.targetx, self.targety, r)
        return
    elseif not self.active then
        return
    end
    
    -- Draw an 'x' on the target
    if not self.isEnemy then
        local size = 5
        love.graphics.setColor(255, 0, 0)
        love.graphics.line(self.targetx - size, self.targety - size, self.targetx + size, self.targety + size)
        love.graphics.line(self.targetx + size, self.targety - size, self.targetx - size, self.targety + size)
    end

    if self.isEnemy then
        love.graphics.setColor(128, 0, 0)
    else
        love.graphics.setColor(128, 128, 128)
    end
    love.graphics.line(self.startx, self.starty, self.x, self.y)
    
    if self.isEnemy then
        love.graphics.setColor(255, 0, 0)
    else
        love.graphics.setColor(255, 255, 255)
    end
    love.graphics.circle("fill", self.x, self.y, self.radius, self.segments)
end
