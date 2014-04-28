--[[
*******************************************************************************************
* Game
*******************************************************************************************
--]]

local game = {}

--[[
*******************************************************************************************
* Initialize
*******************************************************************************************
--]]
function game:init()
    player = {}
    reset_player()

    -- Game over
    gameOver = false
    -- Paused
    gameIsPaused = false
    -- Dragging
    dragging = false
    -- Debugging
    debugging = false
    -- Last key pressed
    lastKey = ' '
    -- Level
    level = 1
    -- Number of missiles in the wave
    levelCounter = 10
    shots = 0
    kills = 0
    perfect = false
    -- Level timeout
    levelTimeout = 3
    -- Show level
    showLevel = true
    bonus = 0
    levelTimer = nil
    nextMissileTimer = nil
    levelTitleTimer = nil

    -- Missile turrets
    local gunoffset = 100
    guny = love.graphics.getHeight() - gunoffset
    guns = {}
    guns[1] = Gun:new({name = '1', x = gunoffset, y = guny})
    guns[2] = Gun:new({name = '2', x = midx, y = guny})
    guns[3] = Gun:new({name = '3', x = maxy - gunoffset, y = guny})
    
    -- User missiles
    nextMissile = 1
    missiles = {}
    local numMissiles = 100
    for i=1, numMissiles do
        missiles[i] = Missile:new()
    end
    
    -- Enemy missiles
    nextEnemyMissile = 1
    enemyMissiles = {}
    local numEnemyMissiles = 50
    for i=1, numEnemyMissiles do
        enemyMissiles[i] = Missile:new()
        enemyMissiles[i].isEnemy = true
        enemyMissiles[i].speed = 75
    end
    
    -- Start of an explosion
    Signals.register('start_explode', function(isEnemy, x, y)
        if isEnemy then
            love.audio.stop(die)
            love.audio.play(die)
        end
    end)
    
    -- End of an explosion
    Signals.register('end_explode', function(isEnemy, x, y)
    end)

    -- End of an explosion
    Signals.register('shot_taken', function(isEnemy, x, y)
        shots = shots + 1
    end)

    -- A missile has exploded... check for collisions
    Signals.register('explode', function(missile, isEnemy, x, y, r)
        if not isEnemy then
            for i=1, #enemyMissiles do
                if enemyMissiles[i].active
                        and dist(enemyMissiles[i].x, enemyMissiles[i].y, x, y) <= r then
                    enemyMissiles[i].active = false
                    missile.kills = missile.kills + 1
                    addScore(100 * level)
                    if r < 5 then
                        addScore(1000 * level)
                        enemyMissiles[i].crit = 1
                        enemyMissiles[i].critMsg = "CRIT! +" .. tostring(1000 * level)
                    elseif r < 10 then
                        addScore(500 * level)
                        enemyMissiles[i].crit = 1
                        enemyMissiles[i].critMsg = "BOOM! +" .. tostring(500 * level)
                    elseif r < 15 then
                        addScore(100 * level)
                        enemyMissiles[i].crit = 1
                        enemyMissiles[i].critMsg = "NICE! +" .. tostring(100 * level)
                    end
                    if missile.kills > 1 then
                        addScore(500 * level)
                        enemyMissiles[i].crit = 1
                        enemyMissiles[i].critMsg = "x" .. tostring(missile.kills) .. " +" .. tostring(500 * level)
                    end
                    kills = kills + 1
                    love.audio.stop(die)
                    love.audio.play(die)
                end
            end
        else
            for i=1, #guns do
                if dist(guns[i].x, guns[i].y, x, y) <= r then
                    guns[i]:takeDamage(1)
                elseif dist(guns[i].x - guns[i].radius, guns[i].y, x, y) <= r then
                    guns[i]:takeDamage(0.5)
                elseif dist(guns[i].x + guns[i].radius, guns[i].y, x, y) <= r then
                    guns[i]:takeDamage(0.5)
                end
            end
        end
    end)
    
end

--[[
*******************************************************************************************
* Distance between two points
*******************************************************************************************
--]]
function dist(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt(dx * dx + dy * dy)
end

--[[
*******************************************************************************************
* Draw score
*******************************************************************************************
--]]
function draw_score()
    love.graphics.setColor(255, 0, 0)
    drawStringCentered("HIGH SCORE", mdFont, midx, 30)
    drawStringCentered("1UP", mdFont, 120, 30)
    
    love.graphics.setColor(255, 255, 255)
    
    love.graphics.push()
    love.graphics.translate(midx, 70)
    love.graphics.scale(2, 2)
    drawStringCentered(string.format("%06.0f", highScore), scFont, 0, 0)
    love.graphics.pop()
    
    love.graphics.push()
    love.graphics.translate(120, 70)
    love.graphics.scale(2, 2)
    drawStringCentered(string.format("%06.0f", score), scFont, 0, 0)
    love.graphics.pop()
end

--[[
*******************************************************************************************
* Reset
*******************************************************************************************
--]]
function reset_player()
    player.image = image
    player.x = love.window.getWidth() / 2 - player.image:getWidth() / 2
    player.y = love.window.getHeight() / 2 - player.image:getHeight() / 2
    player.xvel = 0
    player.yvel = 0
    player.speed = 100
    player.maxvel = 15
    player.friction = 5
    player.alpha = 0
    player.fade_time = 0.5
    player.fade_timer = 0.5
end

--[[
*******************************************************************************************
* Spawn the next enemy missile
*******************************************************************************************
--]]
function spawnEnemyMissile()
    if not enemyMissiles[nextEnemyMissile].active then
        if levelCounter > 0 then
            enemyMissiles[nextEnemyMissile]:spawn(math.random(0, maxx), 0, math.random(0, maxx), guny)
            nextEnemyMissile = nextEnemyMissile + 1
            if nextEnemyMissile > #enemyMissiles then
                nextEnemyMissile = 1
            end
            levelCounter = levelCounter - 1
        end
    end
    nextMissileTimer = Timer.add(levelTimeout, function()
        spawnEnemyMissile()
    end)
end

--[[
*******************************************************************************************
* Update the game
*******************************************************************************************
--]]
function game:update(dt)
    if gameIsPaused or gameOver then
        return
    end
    
    -- Game over
    local damagedGuns = 0
    for i=1, #guns do
        if math.floor(guns[i].health) <= guns[i].maxhealth * 0.05 then
            damagedGuns = damagedGuns + 1
        end
    end
    if damagedGuns == #guns then
        gameOver = true
    end
    
    -- Next level
    if levelCounter == 0 then

        local numActiveMissiles = 0
        for i=1, #enemyMissiles do
            if enemyMissiles[i].active then
                numActiveMissiles = numActiveMissiles + 1
            end
        end
        
        if numActiveMissiles == 0 then
            -- Go to next level
            level = level + 1
            
            -- Bonus for ammo not used
            bonus = 0
            for i=1, #guns do
                if math.floor(guns[i].ammo) > 0 then
                    bonus = bonus + math.floor(guns[i].ammo) * (10 * (level - 1))
                end
            end
            
            perfect = false
            if shots <= kills then
                perfect = true
                bonus = bonus + 1000 * (level - 1)
            end
            
            shots = 0
            kills = 0
            
            -- Enemy missiles spawn faster
            levelTimeout = levelTimeout - level / 5
            if levelTimeout < 0.35 then
                levelTimeout = 0.35
            end
            
            -- Enemy missiles get faster
            for i=1, #enemyMissiles do
                enemyMissiles[i].speed = enemyMissiles[i].speed + 2 * level
            end
            
            -- More missiles in the next wave
            levelCounter = 10 * level
            
            -- Launch the missiles!
            if nextMissileTimer ~= nil then
                Timer.cancel(nextMissileTimer)
            end
            nextMissileTimer = Timer.add(3, function()
                -- Upgrades
                if level % 2 == 0 then
                    for i=1, #missiles do
                        missiles[i].speed = missiles[i].speed + 150
                    end
                    for i=1, #guns do
                        guns[i].ammo = guns[i].ammo + 5
                        if guns[i].ammo > guns[i].maxammo then
                            guns[i].ammo = guns[i].maxammo
                        end
                    end
                end
                if level % 4 == 0 then
                    for i=1, #guns do
                        guns[i].maxammo = guns[i].maxammo + 5
                        guns[i].ammo = guns[i].maxammo
                    end
                end
                if level % 5 == 0 then
                    for i=1, #missiles do
                        missiles[i].explodeSize = missiles[i].explodeSize + 75
                    end
                end
                if level % 6 == 0 then
                    for i=1, #guns do
                        guns[i].health = guns[i].maxhealth
                        guns[i].ammo = guns[i].maxammo
                    end
                end
                if level % 7 == 0 then
                    for i=1, #guns do
                        guns[i].regen = guns[i].regen + 5
                        guns[i].reload = guns[i].reload + 0.1
                    end
                end
                
                showLevel = true
                addScore(bonus)
                levelTitleTimer = Timer.add(3, function()
                    showLevel = false
                    spawnEnemyMissile()
                end)
            end)
        end
    end
    
    Timer.update(dt)
    
    aimGuns(dt, player.x + player.image:getWidth() / 2, player.y + player.image:getHeight() / 2)
    for i=1, #missiles do
        missiles[i]:update(dt)
    end
    for i=1, #enemyMissiles do
        enemyMissiles[i]:update(dt)
    end
    
    if dragging == true then
        -- Drag from the middle of the image
        local x, y = cam:worldCoords(love.mouse.getPosition())
        player.x = x - player.image:getWidth() / 2
        player.y = y - player.image:getHeight() / 2
        check_player_bounds()
        player.xvel = 0
        player.yvel = 0
    else
        player_control(dt)
    end
end

--[[
*******************************************************************************************
* Draw the game
*******************************************************************************************
--]]
function game:draw()
    love.graphics.setCanvas(canvas)

    update_camera()
    cam:draw(draw_world)
    draw_score()
    draw_hud()
    
    love.graphics.setCanvas()
    love.graphics.setShader(shader)
    love.graphics.draw(canvas)
    love.graphics.setShader()
end

--[[
*******************************************************************************************
* Start the game
*******************************************************************************************
--]]
function game:enter()
    gameOver = false
    gameIsPaused = false
    dragging = false
    lastKey = ' '
    level = 1
    levelTimeout = 3
    levelCounter = 10
    showLevel = true
    perfect = false
    score = 0
    bonus = 0
    shots = 0
    kills = 0
    reset_player()
    love.audio.play(powerup)
    for i=1, #guns do
        guns[i]:reset()
    end
    for i=1, #missiles do
        missiles[i]:reset()
    end
    for i=1, #enemyMissiles do
        enemyMissiles[i]:reset()
        enemyMissiles[i].speed = 75
    end
    nextMissileTimer = Timer.add(1, function()
        showLevel = true
        levelTitleTimer = Timer.add(2, function() showLevel = false end)
        spawnEnemyMissile()
    end)
end

-- Leave the game
function game:leave()
    love.audio.stop(die)
    love.audio.play(die)
    if nextMissileTimer ~= nil then
        Timer.cancel(nextMissileTimer)
    end
    if levelTimer ~= nil then
        Timer.cancel(levelTimer)
    end
    if levelTitleTimer ~= nil then
        Timer.cancel(levelTitleTimer)
    end
end

-- Handle game key presses
function game:keypressed(k)
    if k == 'escape' then
        -- Back to menu
        Gamestate.switch(menu)
    end
    if k == ' ' then
        -- Pause game
        lastKey = k
        gameIsPaused = not gameIsPaused
    end
   
    if gameIsPaused then
        return
    end

    local x = player.x + player.image:getWidth() / 2
    local y = player.y + player.image:getHeight() / 2
    
    if k == '1' then
        -- fire left silo
        if guns[1]:fire(x, y) then
            missiles[nextMissile]:spawn(guns[1].x, guns[1].y, x, y)
        end
    end
    if k == '2' then
        -- fire middle silo
        if guns[2]:fire(x, y) then
            missiles[nextMissile]:spawn(guns[2].x, guns[2].y, x, y)
        end
    end
    if k == '3' then
        -- fire right silo
        if guns[3]:fire(x, y) then
            missiles[nextMissile]:spawn(guns[3].x, guns[3].y, x, y)
        end
    end
    
    nextMissile = nextMissile + 1
    if nextMissile > #missiles then
        nextMissile = 1
    end
   
    if k == 'f1' then
        -- toggle debugging
        debugging = not debugging
    end
    
    lastKey = k
end

-- Handle game mouse presses
function game:mousepressed(x, y, button)
    if gameIsPaused then
        return
    end
    
    -- Drag the player
    if button == 'l' then
        local x, y = cam:worldCoords(love.mouse.getPosition())
        player.x = x - player.image:getWidth() / 2
        player.y = y - player.image:getHeight() / 2
        check_player_bounds()
        player.xvel = 0
        player.yvel = 0
        dragging = true
    end
end

-- Handle game mouse releases
function game:mousereleased(x, y, button)
    if gameIsPaused then
        return
    end
   
    -- End dragging
    if button == "l" then
        dragging = false
        --player.fade_time = 0.5
        --player.fade_timer = 0.5
    end
end

-- Aim the guns at the cursor
function aimGuns(dt, x, y)
    for i=1, #guns do
        guns[i]:aim(dt, x, y)
    end
end

-- Add points to the score
function addScore(points)
    score = score + points
    if score > highScore then
        highScore = score
    end
end

--[[
*******************************************************************************************
* Update the camera position, zoom, and rotation
*******************************************************************************************
--]]
function update_camera()
    -- Follow player
    --cam:move((player.x - cam.x) / 2, (player.y - cam.y)/2)
    
    -- Sea sickness
    --cam:rotateTo(math.sin(wave) * math.pi / 2)
    -- Added sea sickness
    --cam:zoomTo(1 + math.cos(wave) / 2)
    
    --[[
    cam:move((player.x - cam.x) / 2, (player.y - cam.y)/2)    
    cam:zoomTo(2 - (love.window.getHeight() - player.y) / love.window.getHeight())
    ]]--
end

--[[
*******************************************************************************************
* Draw the world
*******************************************************************************************
--]]
function draw_world()
    draw_background()
    draw_missiles()
    draw_guns()
    draw_player()
end

-- Draw guns
function draw_guns()
    for i=1, #guns do
        guns[i]:draw()
    end
end

-- Draw missiles
function draw_missiles()
    for i=1, #enemyMissiles do
        enemyMissiles[i]:draw()
    end
    for i=1, #missiles do
        missiles[i]:draw()
    end
    for i=1, #enemyMissiles do
        enemyMissiles[i]:drawMessages()
    end
end

--[[
*******************************************************************************************
* Draw the background
*******************************************************************************************
--]]
function draw_background()
    -- Black background
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    love.graphics.setColor(32, 32, 32)
    love.graphics.rectangle("fill", -w, -h, w * 3, h * 3)
end

--[[
*******************************************************************************************
* Draw the paused message
*******************************************************************************************
--]]
function draw_paused()
    local str = "PAUSED"
    love.graphics.setColor(255, 0, 0)
    drawStringCentered(str, mdFont, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
end

--[[
*******************************************************************************************
* Draw the HUD (stuff that doesn't move with camera)
*******************************************************************************************
--]]
function draw_hud()
    love.graphics.setColor(255, 0, 0)
    love.graphics.setFont(mdFont)
    local str = "Arrow keys move cursor. 1, 2, 3 fire guns. ESC quits."
    local w = mdFont:getWidth(str)
    local h = mdFont:getHeight(str)
    love.graphics.print(str, (love.graphics.getWidth() - w) / 2, love.graphics.getHeight() - h * 1.5)
    
    if debugging then
        draw_debug_info()
    end

    if gameOver == true then
        print("Game over!")
        love.graphics.setColor(255, 0, 0)
        drawStringCentered("GAME OVER", lgFont, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
        return
    end
    
    if showLevel then
        love.graphics.setColor(255, 0, 0)
        drawStringCentered("LEVEL " .. level, mdFont, midx, 200)
        if bonus > 0 then
            drawStringCentered("BONUS " .. bonus, mdFont, midx, midy)
            if perfect == true then
                drawStringCentered("PERFECT!", mdFont, midx, midy - 40)
            end
        end
        local y = 250
        if level == 1 then
            drawStringCentered("DEFEND THE UNDERGROUND LABS", mdFont, midx, y)
            y = y + 100
            drawStringCentered("GIVE YOUR SCIENTISTS THE TIME THEY NEED", mdFont, midx, y)
            y = y + 50
            drawStringCentered("TO DEVELOP STRONGER WEAPONS", mdFont, midx, y)
            y = y + 300
            drawStringCentered("YOU ARE HUMANITY'S LAST HOPE", mdFont, midx, y)
            y = y + 100
        end
        if level % 2 == 0 then
            drawStringCentered("MISSILE SPEED UPGRADE", mdFont, midx, y)
            y = y + 50
        end
        if level % 4 == 0 then
            drawStringCentered("MISSILE BATTERY CAPACITY INCREASE", mdFont, midx, y)
            y = y + 50
        end
        if level % 5 == 0 then
            drawStringCentered("BIG BADDA BOOM -- INCREASED WARHEAD YIELD", mdFont, midx, y)
            y = y + 50
        end
        if level % 6 == 0 then
            drawStringCentered("REPAIR AND RELOAD ALL MISSILE BATTERIES", mdFont, midx, y)
            y = y + 50
        end
        if level % 7 == 0 then
            drawStringCentered("FASTER MISSILE BATTERY HEALTH REGEN", mdFont, midx, y)
            y = y + 50
            drawStringCentered("FASTER MISSILE PRODUCTION", mdFont, midx, y)
            y = y + 50
        end
    end
    
    if gameIsPaused == true then
        draw_paused()
    end
end

--[[
*******************************************************************************************
* Debug info
*******************************************************************************************
--]]
function draw_debug_info()
    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(smFont)
    local x = 10
    local y = 125
    local h = smFont:getHeight()
    
    local xvel = string.format("%12.4f", player.xvel)
    local yvel = string.format("%12.4f", player.yvel)
    local alpha = string.format("%12.4f", player.alpha)
    local fps = tostring(love.timer.getFPS())
    
    love.graphics.print('Last key = ' .. lastKey, x, y)
    y = y + h
    love.graphics.print("x velocity = " .. xvel, x, y)
    y = y + h
    love.graphics.print("y velocity = " .. yvel, x, y)
    y = y + h
    love.graphics.print("alpha = " .. alpha, x, y)
    y = y + h
    love.graphics.print("Shots = " .. tostring(shots), x, y)
    y = y + h
    love.graphics.print("Kills = " .. tostring(kills), x, y)
    y = y + h
    love.graphics.print("FPS = " .. fps, x, y)
    y = y + h
    
    for i=1, #guns do
        local ammoStr = "ammo=" .. string.format("%3.1f", guns[i].ammo)
        local healthStr = "health=" .. string.format("%4.1f", guns[i].health)
        love.graphics.print("Gun #" .. tostring(i) .. ": " .. ammoStr .. " " .. healthStr, x, y)
        y = y + h
    end
    
    local str = "Cursor (" .. math.floor(player.x) .. "," .. math.floor(player.y) .. ")"
    local w = labelFont:getWidth(str)
    x = player.x + (player.image:getWidth() - w) / 2
    y = player.y + player.image:getHeight()
    love.graphics.setFont(labelFont)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print(str, x, y)
end

--[[
*******************************************************************************************
* Draw the player
*******************************************************************************************
--]]
function draw_player()
    love.graphics.setColor(255, 255, 255, player.alpha)
    love.graphics.draw(player.image, player.x, player.y)
end

--[[
*******************************************************************************************
* Check player bounds
*******************************************************************************************
--]]
function check_player_bounds()
    if player.x < 0 then
        player.x = 0
        player.xvel = -player.xvel
        love.audio.stop(bump)
        love.audio.play(bump)
    elseif player.x > love.window.getWidth() - player.image:getWidth() then
        player.x = love.window.getWidth() - player.image:getWidth()
        player.xvel = -player.xvel
        love.audio.stop(bump)
        love.audio.play(bump)
    end
    if player.y < 0 then
        player.y = 0
        player.yvel = -player.yvel
        love.audio.stop(blip)
        love.audio.play(blip)
    elseif player.y > love.window.getHeight() - player.image:getHeight() then
        player.y = love.window.getHeight() - player.image:getHeight()
        player.yvel = -player.yvel
        love.audio.stop(blip)
        love.audio.play(blip)
    end
end

--[[
*******************************************************************************************
* Player Control
*******************************************************************************************
--]]
function player_control(dt)
    if player.fade_time > 0 then
        player.fade_time = player.fade_time - dt
        if player.fade_time < 0 then player.fade_time = 0 end
        player.alpha = 255 * (1 - (player.fade_time / player.fade_timer))
    else
        player.alpha = 255
    end
    
    player.x = player.x + player.xvel
    player.y = player.y + player.yvel
    
    check_player_bounds()
    
    player.xvel = player.xvel * (1 - math.min(dt * player.friction, 1))
    player.yvel = player.yvel * (1 - math.min(dt * player.friction, 1))
    if love.keyboard.isDown("d", "right") and player.xvel < player.maxvel then
        player.xvel = player.xvel + player.speed * dt
    end
    if love.keyboard.isDown("a", "left") and player.xvel > -player.maxvel then
        player.xvel = player.xvel - player.speed * dt
    end
    if love.keyboard.isDown("s", "down") and player.yvel < player.maxvel then
        player.yvel = player.yvel + player.speed * dt
    end
    if love.keyboard.isDown("w", "up") and player.yvel > -player.maxvel then
        player.yvel = player.yvel - player.speed * dt
    end
    if math.abs(player.xvel) < 0.1 then
        player.xvel = 0
    end
    if math.abs(player.yvel) < 0.1 then
        player.yvel = 0
    end
end

return game