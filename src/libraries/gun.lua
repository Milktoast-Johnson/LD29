Gun = {
    x = 0,
    y = 0,
    angle = 0,
    firing = 0,
    targetx = 0,
    targety = 0,
    radius = 25,
    length = 45,
    segments = 50,
    name = "X",
    ammo = 30,
    maxammo = 30,
    reload = 0.5,
    health = 300,
    regen = 5,
    maxhealth = 300
}

function Gun:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Gun:reset()
    self.ammo = Gun.ammo
    self.maxammo = Gun.maxammo
    self.health = Gun.health
    self.maxhealth = Gun.maxhealth
    self.reload = Gun.reload
    self.regen = Gun.regen
end

function Gun:aim(dt, x, y)
    if self.firing > 0 then
        self.firing = self.firing - dt
        if self.firing < 0 then
            self.firing = 0
        end
    end
    self.angle = math.atan2(y - self.y, x - self.x)
    
    if not firing and self.health < self.maxhealth and self.health >= self.maxhealth * 0.2 then
        self:takeDamage(-self.regen * dt)
    elseif not firing and self.health < self.maxhealth then
        self:takeDamage(-self.regen / 5 * dt)
    end
    
    if not firing and self.ammo < self.maxammo and self.health == self.maxhealth then
        self:addAmmo(self.reload * dt)
    end
end

function Gun:addAmmo(amount)
    self.ammo = self.ammo + amount
    if self.ammo < 0 then
        self.ammo = 0
    elseif self.ammo > self.maxammo then
        self.ammo = self.maxammo
    end
end

function Gun:takeDamage(damage)
    self.health = self.health - damage
    if self.health <= 0 then
        self.health = 0
    elseif self.health > self.maxhealth then
        self.health = self.maxhealth
    end
end

function Gun:fire(x, y)
    if math.floor(self.health) <= self.maxhealth * 0.05 then
        love.audio.stop(die)
        love.audio.play(die)
        return false
    elseif math.floor(self.ammo) <= 0 then
        love.audio.stop(bump)
        love.audio.play(bump)
        --self:takeDamage(10)
        return false
    end

    self.ammo = self.ammo - 1
    love.audio.stop(swipe)
    love.audio.play(swipe)
    self.firing = 0.5
    self.targetx = x
    self.targety = y
    Signals.emit('shot_taken', self.targetx, self.targety)
    return true
end

function Gun:draw()
    --if self.firing > 0 then
        --love.graphics.setColor(255, 0, 0)
        --love.graphics.line(self.x, self.y, self.targetx, self.targety)
    --end
    
    love.graphics.setColor(255, 0, 0)
    love.graphics.circle("fill", self.x, self.y, self.radius, self.segments)
    love.graphics.line(self.x, self.y, self.x + self.length * math.cos(self.angle), self.y + self.length * math.sin(self.angle))
    
    love.graphics.setColor(0, 0, 0);
    local w = smFont:getWidth(self.name)
    local h = smFont:getHeight(self.name)
    love.graphics.setFont(smFont)
    love.graphics.print(self.name, self.x - w / 2, self.y - h / 2)
    
    local ammoCount = tostring(math.floor(self.ammo))
    if math.floor(self.ammo) > 0 then
        love.graphics.setColor(0, 255, 0);
    else
        love.graphics.setColor(255, 0, 0);
        ammoCount = ammoCount .. " OUT!"
    end
    drawStringCentered(ammoCount, smFont, self.x, self.y + self.radius * 1.5)
    
    love.graphics.setColor(0, 0, 0);
    love.graphics.rectangle("fill", self.x + self.radius + 5, self.y - self.radius, 10, self.radius * 2)
    if self.health > self.maxhealth * 0.8 then
        love.graphics.setColor(0, 255, 0);
    elseif self.health > self.maxhealth * 0.4 then
        love.graphics.setColor(255, 255, 0);
    else
        love.graphics.setColor(255, 0, 0);
    end
    love.graphics.rectangle("fill", self.x + self.radius + 5, self.y + self.radius, 10, lerp(self.health / self.maxhealth, 0, -self.radius * 2))
    love.graphics.setColor(255, 255, 255);
    love.graphics.rectangle("line", self.x + self.radius + 5, self.y - self.radius, 10, self.radius * 2)
    if math.floor(self.health) <= self.maxhealth * 0.05 then
        drawStringCentered("DAMAGED!", smFont, self.x, self.y)
    end
end