--[[
*******************************************************************************************
* Menu
*******************************************************************************************
--]]

local menu = {}

function menu:init()
    -- Stars for main menu
    fl = 300
    stars = {}
    stardt = 0
    local numStars = 1000
    for i=1, numStars do
        local x = math.random(-7000, 7000)
        local y = math.random(-7000, 7000)
        local z = math.random(0, 500)
        stars[i] = {x, y, z}
    end
end

-- Draw the menu
function menu:draw()
    love.graphics.setCanvas(canvas)

    -- Reset camera
    cam:lookAt(love.window.getWidth() / 2, love.window.getHeight() / 2)
    cam:zoomTo(1)
    cam:rotateTo(0)
    cam:draw(draw_menu_background)

    draw_score()
    
    for i=1,3 do
        love.graphics.push()
        love.graphics.translate(midx, love.graphics.getHeight() / 2 - 180 - i * 5)
        love.graphics.scale(lerp(i / 3, 0.8, 1) , i)
            love.graphics.setColor(HSV(titleColor, 255, 255))
            local font = ttFont
            if i == 3 then font = ttFont2 end
            drawStringCentered("BENEATH the SURFACE", font, 0, 0)
            titleColor = (titleColor + 10) % 255
        love.graphics.pop()
    end

    love.graphics.push()
    love.graphics.translate(midx, love.graphics.getHeight() / 2 + 150)
    love.graphics.scale(1, 1)
    --love.graphics.rotate(math.sin(wave * 10) * 0.1)
        love.graphics.setColor(255, 255, 255)
        drawStringCentered("Press ENTER to PLAY", mdFont, 0, 0)
    love.graphics.pop()
    
    love.graphics.push()
    love.graphics.translate(midx, love.graphics.getHeight() / 2 + 190)
    love.graphics.scale(1, 1)
    --love.graphics.rotate(math.sin(wave * 10) * 0.1)
        love.graphics.setColor(255, 255, 255)
        drawStringCentered("Press ESC to QUIT", mdFont, 0, 0)
    love.graphics.pop()
    
    love.graphics.setFont(tyFont)
    love.graphics.printf("Humans left Earth to explore the galaxy and discovered that we weren't alone.  The universe far is more hostile than we could have imagined. Earth was destroyed after centuries of conflict and invasion.  Humanity was scattered and relentlessly pursued. By chance, we found an ancient outpost beneath the surface of a rogue planet. We accidentally activated the outpost's power plant and alerted our enemies. Now it's a race against time to exploit the ancient technology or suffer total destruction. You must defend the outpost and defeat the aliens aided only by your team of scientists working in the labs below. The key to humanity's salvation lies... beneath the surface.", 50, love.graphics.getHeight() / 2 + 230, love.graphics.getWidth() - 100, "left")
    
    drawStringCentered("MMXIV Milktoast Johnson", mdFont, midx, love.graphics.getHeight() - 40)
    
    -- Ludum Dare logo
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(ld29, (love.graphics.getWidth() - ld29:getWidth()) / 2, 150)
    
    love.graphics.setCanvas()
    love.graphics.setShader(shader)
    love.graphics.draw(canvas)
    love.graphics.setShader()
end

-- Draw menu background
function draw_menu_background()
    --love.graphics.setColor(48, 0, 72)
    love.graphics.setColor(32, 32, 32)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    
    for i=1, #stars do
        local perspective = fl / (fl * stars[i][3])
        
        love.graphics.setColor(HSV(math.random(0,255), 128, 255))
        love.graphics.push()
        love.graphics.translate(stars[i][1] * perspective, stars[i][2] * perspective)
        love.graphics.scale(perspective)
        love.graphics.point(stars[i][1], stars[i][2])
        love.graphics.circle("fill", stars[i][1], stars[i][2], 20, 4)
        --love.graphics.draw(image, stars[i][1], stars[i][2])
        love.graphics.pop()
        
        stars[i][3] = stars[i][3] - stardt;
        if (stars[i][3] < 0) then
            stars[i][3] = 500
        end
    end
    
    love.graphics.pop()
    
    love.graphics.setColor(255, 169, 2)
    love.graphics.circle("fill", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 100, 15)
    love.graphics.setColor(145, 96, 0)
    love.graphics.circle("fill", love.graphics.getWidth() / 2 - 80, love.graphics.getHeight() / 2 + 80, 25, 10)
end

-- Menu update
function menu:update(dt)
    stardt = dt * 20
    --wave = wave + dt * 1.5
    --Timer.update(dt)
end

-- Handle menu key presses
function menu:keypressed(k)
    if k == 'escape' then
        love.event.quit()
    elseif k == 'return' or k == 'kpenter' then
        Gamestate.switch(game)
    end
end

--[[
function toggleShake()
    shakeStars = not shakeStars
    if shakeStars then
        shakeStart = wave
        love.audio.stop(die)
        love.audio.play(die)
        shakeStarsHandle = Timer.add(math.random(0.1, 0.3), toggleShake)
    else 
        shakeStarsHandle = Timer.add(math.random(1, 5), toggleShake)
    end
end

function menu:enter()
    shakeStarsHandle = Timer.add(math.random(1, 5), toggleShake)
end

function menu:leave()
    Timer.cancel(shakeStarsHandle)
end
]]--

return menu