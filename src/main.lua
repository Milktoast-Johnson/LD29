--[[
*******************************************************************************************
*
* LOVE2D Demo
*
*******************************************************************************************
--]]

Camera = require "libraries.camera"
Gamestate = require "libraries.gamestate"
Timer = require "libraries.timer"
Signals = require "libraries.signal"
require "libraries.gun"
require "libraries.missile"
menu = require "libraries.gamestates.menu"
game = require "libraries.gamestates.game"

--[[
*******************************************************************************************
* Load
*******************************************************************************************
--]]
function love.load()

    -- Set the background colour
    love.graphics.setBackgroundColor(255, 255, 255)
    
    -- Title color
    titleColor = 0
    -- Score
    score = 0
    -- High score
    highScore = 0
    
    -- Camera
    maxx = love.graphics.getWidth()
    maxy = love.graphics.getHeight()
    midx = maxx / 2
    midy = maxy / 2
    cam = Camera(midx, midy)
    
    -- Setup fonts
    labelFont = love.graphics.setNewFont("res/fonts/orbitron/orbitron-black.otf", 12)
    tyFont = love.graphics.setNewFont("res/fonts/orbitron/orbitron-black.otf", 20)
    smFont = love.graphics.setNewFont("res/fonts/orbitron/orbitron-black.otf", 24)
    mdFont = love.graphics.setNewFont("res/fonts/orbitron/orbitron-black.otf", 28)
    lgFont = love.graphics.setNewFont("res/fonts/orbitron/orbitron-black.otf", 64)
    scFont = love.graphics.setNewFont("res/fonts/mplus1/mplus-1m-medium.ttf", 28)
    ttFont = love.graphics.setNewFont("res/fonts/gunship/gun4fs.ttf", 48)
    ttFont2 = love.graphics.setNewFont("res/fonts/gunship/gun4f.ttf", 48)
    
    -- Sounds
    die = love.audio.newSource(love.sound.newSoundData("res/sounds/die.wav"))
    blip = love.audio.newSource(love.sound.newSoundData("res/sounds/blip.wav"))
    bump = love.audio.newSource(love.sound.newSoundData("res/sounds/bump.wav"))
    swipe = love.audio.newSource(love.sound.newSoundData("res/sounds/swipe.wav"))
    powerup = love.audio.newSource(love.sound.newSoundData("res/sounds/powerup.wav"))
    
    -- Load the player image
    ld29 = love.graphics.newImage("res/images/LD2009.png")
    image = love.graphics.newImage("res/images/cursor.png")

    -- CRT shader
    canvas = love.graphics.newCanvas()
    local str = love.filesystem.read('res/shaders/CRT.frag')
    shader = love.graphics.newShader(str)
    shader:send('inputSize', {love.graphics.getWidth(), love.graphics.getHeight()})
    shader:send('textureSize', {love.graphics.getWidth(), love.graphics.getHeight()})
    shader:send('distortion', 0.4)
    
    -- Game state
    Gamestate.registerEvents()
    Gamestate.switch(menu)
end

--[[
*******************************************************************************************
* Linear interpolation
*******************************************************************************************
--]]
function lerp(norm, min, max)
    return (max - min) * norm + min
end

--[[
*******************************************************************************************
* Draw a string centered on a point
*******************************************************************************************
--]]
function drawStringCentered(str, font, x, y)
    local w = font:getWidth(str)
    local h = font:getHeight(str)
    love.graphics.setFont(font)
    love.graphics.print(str, x - w/2, y - h/2)
end

--[[
*******************************************************************************************
* HSV
*******************************************************************************************
--]]
function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h, s, v = h/256*6, s/255, v/255
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m)*255,(g+m)*255,(b+m)*255
end

--[[
*******************************************************************************************
* Focus Handler
*******************************************************************************************
--]]
function love.focus(f)
   -- If we've lost focus, pause the game.
   gameIsPaused = not f
end

--[[
*******************************************************************************************
* Quit
*******************************************************************************************
--]]
function love.quit()
   print("Game over, man!  Game over!")
end