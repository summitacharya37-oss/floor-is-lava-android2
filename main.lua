-- main.lua
-- Floor is Lava - 100 Levels! (Mobile Version)

local game = {
    state = "menu", -- menu, playing, level_complete, gameover
    level = 1,
    score = 0,
    lives = 3,
    timer = 60
}

local player = {
    x = 50,
    y = 400,
    width = 30,
    height = 30,
    velocity = {x = 0, y = 0},
    speed = 300,
    jumpForce = -500,
    grounded = false,
    color = {0.2, 0.8, 0.2}
}

local lava = {
    y = 550,
    height = 50,
    speed = 0,
    color = {1, 0.3, 0.1}
}

-- Mobile controls
local mobileControls = {
    left = {x = 50, y = 500, width = 60, height = 60, active = false},
    right = {x = 130, y = 500, width = 60, height = 60, active = false},
    jump = {x = 700, y = 500, width = 80, height = 60, active = false},
    visible = true
}

local platforms = {}
local coins = {}
local levelTime = 60

function love.load()
    love.window.setTitle("Floor is Lava - 100 Levels! (Mobile)")
    love.window.setMode(800, 600)
    loadLevel(1)
end

function loadLevel(levelNum)
    game.level = levelNum
    game.timer = levelTime
    platforms = {}
    coins = {}
    
    -- Reset player position
    player.x = 50
    player.y = 400
    player.velocity = {x = 0, y = 0}
    
    -- Level-based lava speed
    lava.speed = 0.5 + (levelNum * 0.1)
    
    generateLevel(levelNum)
end

function generateLevel(level)
    -- Base platforms
    table.insert(platforms, {x = 0, y = 500, width = 100, height = 20, color = {0.6, 0.6, 0.8}})
    
    -- Level-specific platform generation
    local numPlatforms = 10 + math.floor(level * 0.8)
    local platformGap = 600 / numPlatforms
    
    for i = 1, numPlatforms do
        local platform = {
            x = math.random(50, 700),
            y = 450 - (i * 40) + math.random(-20, 20),
            width = math.random(40, 120),
            height = 20,
            color = {math.random(0.3, 0.7), math.random(0.3, 0.7), math.random(0.3, 0.7)}
        }
        
        -- Make platforms smaller and more spaced in higher levels
        if level > 20 then
            platform.width = math.random(30, 80)
        end
        if level > 50 then
            platform.width = math.random(20, 60)
        end
        
        table.insert(platforms, platform)
    end
    
    -- Add moving platforms in higher levels
    if level > 10 then
        for i = 1, math.min(3, math.floor(level/10)) do
            table.insert(platforms, {
                x = math.random(100, 600),
                y = math.random(200, 400),
                width = 60,
                height = 15,
                color = {0.8, 0.6, 0.2},
                moving = true,
                moveX = true,
                speed = 50 + (level * 2),
                range = 100
            })
        end
    end
    
    -- Add disappearing platforms in higher levels
    if level > 25 then
        for i = 1, math.min(5, math.floor(level/15)) do
            table.insert(platforms, {
                x = math.random(100, 600),
                y = math.random(150, 350),
                width = 40,
                height = 15,
                color = {1, 0.5, 0.5},
                disappearing = true,
                timer = 2,
                visible = true
            })
        end
    end
    
    -- Generate coins
    local numCoins = 3 + math.floor(level / 5)
    for i = 1, numCoins do
        local platform = platforms[math.random(2, #platforms)]
        table.insert(coins, {
            x = platform.x + math.random(10, platform.width - 20),
            y = platform.y - 20,
            width = 15,
            height = 15,
            collected = false,
            color = {1, 0.8, 0.2}
        })
    end
    
    -- Goal platform (always at top)
    table.insert(platforms, {
        x = 700,
        y = 50,
        width = 80,
        height = 20,
        color = {0.2, 0.8, 0.2},
        isGoal = true
    })
end

function love.update(dt)
    if game.state == "playing" then
        game.timer = game.timer - dt
        
        if game.timer <= 0 then
            loseLife()
        end
        
        updatePlayer(dt)
        updatePlatforms(dt)
        updateLava(dt)
        checkCoinCollection()
        checkGoalReached()
    end
end

function updatePlayer(dt)
    -- Apply gravity
    player.velocity.y = player.velocity.y + 800 * dt
    
    -- Movement
    player.velocity.x = 0
    
    -- Keyboard controls (for testing)
    if love.keyboard.isDown("a", "left") or mobileControls.left.active then
        player.velocity.x = -player.speed
    end
    if love.keyboard.isDown("d", "right") or mobileControls.right.active then
        player.velocity.x = player.speed
    end
    if (love.keyboard.isDown("w", "up", "space") or mobileControls.jump.active) and player.grounded then
        player.velocity.y = player.jumpForce
        player.grounded = false
    end
    
    -- Update position
    player.x = player.x + player.velocity.x * dt
    player.y = player.y + player.velocity.y * dt
    
    -- Boundary checking
    if player.x < 0 then player.x = 0 end
    if player.x > 800 - player.width then player.x = 800 - player.width end
    
    -- Check if player fell in lava
    if player.y + player.height > lava.y then
        loseLife()
        return
    end
    
    -- Platform collision
    player.grounded = false
    for _, platform in ipairs(platforms) do
        if platform.visible ~= false and checkCollision(player, platform) and player.velocity.y > 0 then
            player.y = platform.y - player.height
            player.velocity.y = 0
            player.grounded = true
        end
    end
end

function updatePlatforms(dt)
    for _, platform in ipairs(platforms) do
        -- Moving platforms
        if platform.moving then
            if platform.moveX then
                platform.x = platform.x + platform.speed * dt
                if platform.x < 50 or platform.x > 750 - platform.width then
                    platform.speed = -platform.speed
                end
            end
        end
        
        -- Disappearing platforms
        if platform.disappearing then
            platform.timer = platform.timer - dt
            if platform.timer <= 0 then
                platform.visible = not platform.visible
                platform.timer = platform.visible and 2 or 1
            end
        end
    end
end

function updateLava(dt)
    -- Lava rises over time and with level progression
    lava.y = lava.y - (lava.speed * dt)
    
    -- Lava rises faster when timer is low
    if game.timer < 10 then
        lava.y = lava.y - (1 * dt)
    end
end

function checkCoinCollection()
    for i, coin in ipairs(coins) do
        if not coin.collected and checkCollision(player, coin) then
            coin.collected = true
            game.score = game.score + 100
        end
    end
end

function checkGoalReached()
    local goal = nil
    for _, platform in ipairs(platforms) do
        if platform.isGoal and checkCollision(player, platform) then
            completeLevel()
            return
        end
    end
end

function completeLevel()
    game.state = "level_complete"
    game.score = game.score + math.ceil(game.timer * 10)
    
    -- Bonus for collecting all coins
    local allCoinsCollected = true
    for _, coin in ipairs(coins) do
        if not coin.collected then
            allCoinsCollected = false
            break
        end
    end
    
    if allCoinsCollected then
        game.score = game.score + 500
    end
end

function loseLife()
    game.lives = game.lives - 1
    if game.lives <= 0 then
        game.state = "gameover"
    else
        loadLevel(game.level) -- Retry current level
    end
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

-- Mobile touch input handling
function love.touchpressed(id, x, y, dx, dy, pressure)
    x, y = x * 800, y * 600 -- Convert to screen coordinates
    
    if game.state == "menu" then
        game.state = "playing"
        return
    elseif game.state == "level_complete" then
        if game.level < 100 then
            loadLevel(game.level + 1)
            game.state = "playing"
        else
            game.state = "game_complete"
        end
        return
    elseif game.state == "gameover" or game.state == "game_complete" then
        resetGame()
        return
    end
    
    -- Check mobile controls
    if mobileControls.visible then
        if checkCollisionPoint(x, y, mobileControls.left) then
            mobileControls.left.active = true
        elseif checkCollisionPoint(x, y, mobileControls.right) then
            mobileControls.right.active = true
        elseif checkCollisionPoint(x, y, mobileControls.jump) then
            mobileControls.jump.active = true
        end
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    x, y = x * 800, y * 600 -- Convert to screen coordinates
    
    -- Reset mobile controls
    mobileControls.left.active = false
    mobileControls.right.active = false
    mobileControls.jump.active = false
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    x, y = x * 800, y * 600 -- Convert to screen coordinates
    
    -- Update mobile controls based on touch position
    if mobileControls.visible then
        mobileControls.left.active = checkCollisionPoint(x, y, mobileControls.left)
        mobileControls.right.active = checkCollisionPoint(x, y, mobileControls.right)
        mobileControls.jump.active = checkCollisionPoint(x, y, mobileControls.jump)
    end
end

function checkCollisionPoint(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
           y >= rect.y and y <= rect.y + rect.height
end

function love.keypressed(key)
    if game.state == "menu" then
        if key == "return" then
            game.state = "playing"
        end
    elseif game.state == "level_complete" then
        if key == "return" then
            if game.level < 100 then
                loadLevel(game.level + 1)
                game.state = "playing"
            else
                game.state = "game_complete"
            end
        end
    elseif game.state == "gameover" then
        if key == "r" then
            resetGame()
        end
    elseif game.state == "game_complete" then
        if key == "r" then
            resetGame()
        end
    end
end

function resetGame()
    game.level = 1
    game.score = 0
    game.lives = 3
    game.state = "menu"
    loadLevel(1)
end

function love.draw()
    if game.state == "menu" then
        drawMenu()
    elseif game.state == "playing" then
        drawGame()
    elseif game.state == "level_complete" then
        drawLevelComplete()
    elseif game.state == "gameover" then
        drawGameOver()
    elseif game.state == "game_complete" then
        drawGameComplete()
    end
    
    -- Always draw mobile controls when playing
    if game.state == "playing" and mobileControls.visible then
        drawMobileControls()
    end
end

function drawMobileControls()
    -- Left button
    love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    love.graphics.rectangle("fill", mobileControls.left.x, mobileControls.left.y, 
                           mobileControls.left.width, mobileControls.left.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("←", mobileControls.left.x, mobileControls.left.y + 15, 
                        mobileControls.left.width, "center")
    
    -- Right button
    love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    love.graphics.rectangle("fill", mobileControls.right.x, mobileControls.right.y, 
                           mobileControls.right.width, mobileControls.right.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("→", mobileControls.right.x, mobileControls.right.y + 15, 
                        mobileControls.right.width, "center")
    
    -- Jump button
    love.graphics.setColor(0.2, 0.7, 0.2, 0.7)
    love.graphics.rectangle("fill", mobileControls.jump.x, mobileControls.jump.y, 
                           mobileControls.jump.width, mobileControls.jump.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("JUMP", mobileControls.jump.x, mobileControls.jump.y + 15, 
                        mobileControls.jump.width, "center")
    
    -- Highlight active buttons
    if mobileControls.left.active then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("fill", mobileControls.left.x, mobileControls.left.y, 
                               mobileControls.left.width, mobileControls.left.height)
    end
    if mobileControls.right.active then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("fill", mobileControls.right.x, mobileControls.right.y, 
                               mobileControls.right.width, mobileControls.right.height)
    end
    if mobileControls.jump.active then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("fill", mobileControls.jump.x, mobileControls.jump.y, 
                               mobileControls.jump.width, mobileControls.jump.height)
    end
end

function drawMenu()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.3)
    
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.printf("FLOOR IS LAVA", 0, 100, 800, "center", 0, 2, 2)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("100 LEVELS OF FIREY ADVENTURE!", 0, 200, 800, "center")
    
    love.graphics.printf("Mobile Controls:", 0, 280, 800, "center")
    love.graphics.printf("Left/Right Buttons: Move", 0, 310, 800, "center")
    love.graphics.printf("Jump Button: Jump", 0, 340, 800, "center")
    love.graphics.printf("Tap anywhere to start/continue", 0, 370, 800, "center")
    
    love.graphics.printf("Avoid the rising lava!", 0, 420, 800, "center")
    love.graphics.printf("Reach the GREEN platform to win!", 0, 450, 800, "center")
    love.graphics.printf("Collect coins for bonus points!", 0, 480, 800, "center")
    
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.printf("Tap Screen to Start!", 0, 540, 800, "center")
end

function drawGame()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.15)
    
    -- Draw lava
    love.graphics.setColor(lava.color[1], lava.color[2], lava.color[3], 0.8)
    love.graphics.rectangle("fill", 0, lava.y, 800, lava.height)
    
    -- Draw lava glow effect
    for i = 1, 3 do
        love.graphics.setColor(lava.color[1], lava.color[2], lava.color[3], 0.3/i)
        love.graphics.rectangle("fill", 0, lava.y - (i*10), 800, 10)
    end
    
    -- Draw platforms
    for _, platform in ipairs(platforms) do
        if not platform.disappearing or platform.visible then
            love.graphics.setColor(platform.color)
            love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height)
        end
    end
    
    -- Draw coins
    for _, coin in ipairs(coins) do
        if not coin.collected then
            love.graphics.setColor(coin.color)
            love.graphics.rectangle("fill", coin.x, coin.y, coin.width, coin.height)
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", coin.x + coin.width/2, coin.y + coin.height/2, coin.width/2)
        end
    end
    
    -- Draw player
    love.graphics.setColor(player.color)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    
    -- Draw HUD
    drawHUD()
end

function drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level: " .. game.level .. "/100", 10, 10)
    love.graphics.print("Score: " .. game.score, 10, 30)
    love.graphics.print("Lives: " .. game.lives, 10, 50)
    love.graphics.print("Time: " .. math.ceil(game.timer), 10, 70)
    
    -- Progress bar for level
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", 600, 10, 190, 20)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", 600, 10, (game.level / 100) * 190, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Progress: " .. game.level .. "%", 650, 12)
    
    -- Timer warning
    if game.timer < 10 then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("HURRY UP! " .. math.ceil(game.timer), 0, 100, 800, "center")
    end
end

function drawLevelComplete()
    drawGame() -- Show game in background
    
    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 200, 150, 400, 300)
    
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.printf("LEVEL " .. game.level .. " COMPLETE!", 200, 180, 400, "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Score: +" .. math.ceil(game.timer * 10), 200, 230, 400, "center")
    
    if game.level < 100 then
        love.graphics.printf("Tap Screen for Level " .. (game.level + 1), 200, 350, 400, "center")
    else
        love.graphics.printf("CONGRATULATIONS! YOU BEAT ALL 100 LEVELS!", 200, 320, 400, "center")
        love.graphics.printf("Final Score: " .. game.score, 200, 350, 400, "center")
        love.graphics.printf("Tap Screen to play again", 200, 380, 400, "center")
    end
end

function drawGameOver()
    love.graphics.setBackgroundColor(0.3, 0.1, 0.1)
    
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.printf("GAME OVER", 0, 200, 800, "center", 0, 3, 3)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("You reached Level " .. game.level, 0, 300, 800, "center")
    love.graphics.printf("Final Score: " .. game.score, 0, 330, 800, "center")
    
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.printf("Tap Screen to Restart", 0, 400, 800, "center")
end

function drawGameComplete()
    love.graphics.setBackgroundColor(0.1, 0.3, 0.1)
    
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.printf("CONGRATULATIONS!", 0, 150, 800, "center", 0, 3, 3)
    
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.printf("YOU MASTERED THE LAVA!", 0, 250, 800, "center", 0, 2, 2)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("All 100 Levels Completed!", 0, 320, 800, "center")
    love.graphics.printf("Final Score: " .. game.score, 0, 350, 800, "center")
    
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.printf("Tap Screen to Play Again", 0, 450, 800, "center")
end