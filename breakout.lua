
local composer = require("composer")
local physics = require ("physics")
-- to modify the physics bodies, use https://www.codeandweb.com/physicseditor to edit the shapedefs.pes file and publish for Corona SDK to shapedefs.lua
local physicsData25 = (require "shapedefs").physicsData(0.25)
local sounds = require('sounds')

local scene = composer.newScene()

function scene:create(event)
    local sceneGroup = self.view

    -- Avoid delay in initial playback of sounds
    sounds.preLoadSound('smash')
    sounds.preLoadSound('bounce')
    sounds.preLoadSound('trap')
    sounds.preLoadSound('loseLife')

    physics.start()
    physics.setGravity(0, 0)
    physics.pause()

    -- Scale the background image to always fit the display's width and acommodate the height independent of aspect ratio
    local background = display.newImageRect("images/BreakoutBackground.png", display.actualContentWidth, display.actualContentWidth * 0.875)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    sceneGroup:insert(background)

    local ball = display.newImageRect("images/Apples.png", 15, 15)
    ball.x = display.contentCenterX
    ball.y = display.contentCenterY
    physics.addBody(ball, physicsData25:get("Apples"))
    ball.angularDamping = 0.5 -- this stops the ball from spinning too crazily, it also removes energy from the system however wich is accounted for later
    ball.objectType = "ball"
    ball.moved = false
    ball.losingLife = false
    ball.respawnTransition = nil
    sceneGroup:insert(ball)

    local rightBounds = display.newRect(display.screenOriginX + display.actualContentWidth, display.contentCenterY, 30 , display.actualContentHeight)
    rightBounds.anchorX = 0
    physics.addBody(rightBounds, "static")
    rightBounds.objectType = "wall"
    sceneGroup:insert(rightBounds)

    local leftBounds = display.newRect(display.screenOriginX, display.contentCenterY, 30 , display.actualContentHeight)
    leftBounds.anchorX = 1
    physics.addBody(leftBounds, "static")
    leftBounds.objectType = "wall"
    sceneGroup:insert(leftBounds)

    local topBounds = display.newRect(display.contentCenterX, display.screenOriginY, display.actualContentWidth + 60, 30)
    topBounds.anchorY = 1
    physics.addBody(topBounds, "static")
    topBounds.objectType = "wall"
    sceneGroup:insert(topBounds)

    local bottomBounds = display.newRect(display.contentCenterX, display.screenOriginY + display.actualContentHeight, display.actualContentWidth + 60, 30)
    bottomBounds.anchorY = 0
    physics.addBody(bottomBounds, "static")
    bottomBounds.objectType = "floor"
    sceneGroup:insert(bottomBounds)

    local paddle = display.newImageRect("images/Adam.png", 100, 30)
    paddle.x = display.contentCenterX
    paddle.y = display.screenOriginY + display.actualContentHeight - 45
    physics.addBody(paddle, "static", physicsData25:get("Adam"))
    paddle.objectType = "paddle"
    sceneGroup:insert(paddle)

    local trap = display.newImageRect("images/Eve.png", 15, 60)
    trap.x = display.contentCenterX
    trap.y = display.screenOriginY + 5 + display.actualContentHeight / 12
    physics.addBody(trap, "static", physicsData25:get("Eve"))
    trap.objectType = "trap"
    trap.activeTransition = nil
    sceneGroup:insert(trap)

    local function trapBackAndForth(obj)
        trap.activeTransition = transition.to(trap, {time = 20000, transition = easing.continuousLoop, iterations = -1, x = display.screenOriginX + display.actualContentWidth - 30})
    end

    local currentScore = event.params.score
    local scoreText = display.newText("Time Spent : " .. currentScore, display.screenOriginX + 5, display.screenOriginY + 5, "fonts/KarmaFuture.ttf", 20)
    scoreText:setFillColor(0, 0, 0)
    scoreText.anchorX = 0
    scoreText.anchorY = 0
    sceneGroup:insert(scoreText)

    local updateScore = function()
        currentScore = currentScore + 1

        -- Limit the score to a maximum of 999
        if currentScore > 999 then currentScore = 999 end

        scoreText.text = "Time Spent : " .. currentScore
    end

    local scoreTimer = timer.performWithDelay(1000, updateScore, -1)
    timer.pause(scoreTimer)

    -- Get the remaining lives which may have changed in previous levels
    local remainingLives = event.params.lives
    local lifeSprites = {}

    for i = 1, remainingLives, 1 do
        local life = display.newImageRect("images/Apples.png", 15, 15)
        life.x = display.screenOriginX + display.actualContentWidth - 20 * i
        life.y = display.screenOriginY + 20
        sceneGroup:insert(life)

        lifeSprites[i] = life
    end

    -- These sprites just count down 3 .. 2 .. 1 when the ball respawns after losing a life
    local respawnTextOne = display.newText("1", display.contentCenterX, display.contentCenterY, "fonts/KarmaFuture.ttf", 40)
    respawnTextOne:setFillColor(0, 0, 0)
    respawnTextOne.alpha = 0
    sceneGroup:insert(respawnTextOne)
    local respawnTextTwo = display.newText("2", display.contentCenterX, display.contentCenterY, "fonts/KarmaFuture.ttf", 40)
    respawnTextTwo:setFillColor(0, 0, 0)
    respawnTextTwo.alpha = 0
    sceneGroup:insert(respawnTextTwo)
    local respawnTextThree = display.newText("3", display.contentCenterX, display.contentCenterY, "fonts/KarmaFuture.ttf", 40)
    respawnTextThree:setFillColor(0, 0, 0)
    respawnTextThree.alpha = 0
    sceneGroup:insert(respawnTextThree)

    local function cancelRespawnTransition()
        respawnTextOne.alpha = 0
        respawnTextTwo.alpha = 0
        respawnTextThree.alpha = 0

        transition.cancel(ball.respawnTransition)
        ball.respawnTransition = nil
    end

    local function loseLife()
        lifeSprites[remainingLives + 1]:removeSelf()

        local function onThreeComplete()
            respawnTextThree.alpha = 0

            ball.respawnTransition = nil
            ball:setLinearVelocity(0, 150)
        end

        local function onTwoComplete()
            respawnTextTwo.alpha = 0

            respawnTextThree.xScale = 0.2
            respawnTextThree.yScale = 0.2
            respawnTextThree.alpha = 1
            ball.respawnTransition = transition.to(respawnTextThree, {time = 500, xScale = 1, yScale = 1, onComplete = onThreeComplete})
        end

        local function onOneComplete()
            respawnTextOne.alpha = 0

            respawnTextTwo.xScale = 0.2
            respawnTextTwo.yScale = 0.2
            respawnTextTwo.alpha = 1
            ball.respawnTransition = transition.to(respawnTextTwo, {time = 500, xScale = 1, yScale = 1, onComplete = onTwoComplete})
        end

        local function resetBall()
            ball.x = display.contentCenterX
            ball.y = display.contentCenterY
            ball.rotation = 0
            ball.angularVelocity = 0
            ball:setLinearVelocity(0,0)
            ball.angularVelocity = 0
            ball.losingLife = false
        end

        -- physics object properties such as position can't be changed from a physics callback so do it as soon as possible afterwards
        timer.performWithDelay(0, resetBall)

        respawnTextOne.xScale = 0.2
        respawnTextOne.yScale = 0.2
        respawnTextOne.alpha = 1
        ball.respawnTransition = transition.to(respawnTextOne, {time = 500, xScale = 1, yScale = 1, onComplete = onOneComplete})
    end

    local trapScoreText = display.newText("+ 3", display.screenOriginX + 115, display.screenOriginY + 5, "fonts/KarmaFuture.ttf", 20)
    trapScoreText:setFillColor(1, 0, 0)
    trapScoreText.anchorX = 0
    trapScoreText.anchorY = 0
    trapScoreText.alpha = 0
    trapScoreText.yOriginal = trapScoreText.y
    trapScoreText.activeTransition = nil
    sceneGroup:insert(trapScoreText)

    local function trapScoreTextEndTransition(obj)
        trapScoreText.activeTransition = nil
    end

    local currentLevel = event.params.level

    local finalScoreText = display.newText("Your Score: 999", display.contentCenterX, display.contentCenterY, "fonts/KarmaFuture.ttf", 40)
    finalScoreText:setFillColor(0, 0, 0)
    finalScoreText.alpha = 0
    sceneGroup:insert(finalScoreText)

    local endingLevel = false

    local function endLevel()
        -- stopping the physics may take an extra tick, so things might collide again causing endLevel to be called again, here we just ignore such repeated calls
        endingLevel = true

        local function stopPhysics()
            physics.stop()
        end

        -- physics can't be stopped from a physics callback so do it as soon as possible afterwards
        timer.performWithDelay(0, stopPhysics)

        -- this disables any touch callbacks for the paddle which might stop this scene from being cleaned up
        paddle:removeSelf()

        timer.cancel(scoreTimer)

        cancelRespawnTransition()

        if trap.activeTransition then
            transition.cancel(trap.activeTransition)
        end

        if trapScoreText.activeTransition then
            transition.cancel(trapScoreText.activeTransition)
            trapScoreText.alpha = 0
        end
    end

    local function winLevel()
        endLevel()

        local nextLevel = currentLevel + 1

        if nextLevel > 3 then
            -- Game completed

            scoreText.alpha = 0

            finalScoreText.text = "Your Score: " .. currentScore
            finalScoreText.alpha = 1

            local function goToMenu()
                composer.gotoScene("menu", "fade", 500)
            end

            -- Show the final score for 5 seconds before going back to the main menu
            timer.performWithDelay(5000, goToMenu)
        else
            -- Level completed, need to go to next level
            local breakoutOptions = {effect = "fade", time = 500, params = {level = nextLevel, score = currentScore, lives = remainingLives}}

            -- cutScene just displays the parameterised background then calls the parameterised scene with the forwarded options, here it is just reloading breakout with new options
            local options = {effect = "fade", time = 500, params = {scene = "breakout", background = "images/GetReadyBackground.png", forwardedOptions = breakoutOptions}}

            composer.gotoScene("cutScene", options)
        end
    end

    local function loseLevel()
        endLevel()

        local options = {effect = "fade", time = 500, params = {scene = "menu", background = "images/YouLoseBackground.png", forwardedOptions = {effect = "fade", time = 500}}}

        composer.gotoScene("cutScene", options)
    end

    local levelDetails =
    {
        brickRows =
        {
            3,
            4,
            4
        },

        brickColumns =
        {
            8,
            8,
            10
        },

        brickType =
        {
            "BrickBrick",
            "MarbleBrick",
            "BlueBrick"
        }
    }

    local remainingBricks = 0
    local brickColumns = levelDetails.brickColumns[currentLevel]
    local brickRows = levelDetails.brickRows[currentLevel]
    local brickXIncrement = display.actualContentWidth / brickColumns
    local brickYOffset = display.actualContentHeight / 6
    local brickYIncrement = (brickYOffset*2) / brickRows

    for i = 0, brickColumns-1, 1 do
        for j = 0, brickRows-1, 1 do
            local brick = display.newImageRect("images/" .. levelDetails.brickType[currentLevel] .. ".png", 15, 15)
            brick.x = display.screenOriginX + brickXIncrement / 2 + i * brickXIncrement
            brick.y = display.screenOriginY + brickYOffset + brickYIncrement / 2 + j * brickYIncrement
            physics.addBody(brick, "static", physicsData25:get("Brick"))
            brick.objectType = "brick"
            brick.brickState = "unsmashed"
            sceneGroup:insert(brick)

            remainingBricks = remainingBricks + 1

            function brick:smash()
                sounds.play('smash')

                 -- brick may be collided with again before the physics body can be removed so it is marked as smashed in order to not have the smash function called again
                brick.brickState = "smashed"

                local function removeBrick()
                    brick:removeSelf()
                    remainingBricks = remainingBricks - 1

                    if remainingBricks == 0 then
                        winLevel()
                    end
                end

                -- physics body can't be removed from a physics callback so do it as soon as possible afterwards
                timer.performWithDelay(0, removeBrick)
            end
        end
    end

    function paddle:touch(event)
        if endingLevel then return true end

        if event.phase == "began" then
            -- ensure that the paddle still receives the "moved" events of an ongoing touch even if it is not being touched directly anymore
            display.getCurrentStage():setFocus(event.target, event.id)

            -- only consider "moved" touch events if the paddle also received the "began" touch event for a particular touch
            paddle.touched = true

            -- if the ball hasn't moved yet during this level, start it moving now
            if not ball.moved then
                ball:setLinearVelocity(0, 150)
                ball.moved = true
                timer.resume(scoreTimer)

                -- transition the trap to one side of the screen once, then trigger the back and forth transition
                trap.activeTransition = transition.to(trap, {time = 5000, x = display.screenOriginX + 30, onComplete = trapBackAndForth})
            end
        end

        if (event.phase == "moved" or event.phase == "began") and paddle.touched and remainingBricks > 0 then
            paddle.x = event.x

            -- don't allow the paddle to leave the screen
            if paddle.x > display.screenOriginX + display.actualContentWidth then
                paddle.x = display.screenOriginX + display.actualContentWidth
            elseif paddle.x < display.screenOriginX then
                paddle.x = display.screenOriginX
            end
        else
            display.getCurrentStage():setFocus(event.target, nil)
            paddle.touched = false
        end

        return true
    end

    paddle:addEventListener("touch", paddle)

    function ball:collision(event)
        if endingLevel then return end

        if event.phase == "began" and not ball.losingLife then
            if event.other.objectType == "brick" and event.other.brickState == "unsmashed" then
                event.other:smash()
            elseif event.other.objectType == "wall" or event.other.objectType == "paddle" then
                sounds.play('bounce')
            elseif event.other.objectType == "trap" and not trapScoreText.activeTransition then -- give a grace period before hitting the trap again will count towards score
                sounds.play('trap')

                currentScore = currentScore + 3
                if currentScore < 0 then currentScore = 0 end

                scoreText.text = "Time Spent : " .. currentScore

                trapScoreText.alpha = 1
                trapScoreText.y = trapScoreText.yOriginal
                trapScoreText.activeTransition = transition.to(trapScoreText, {time = 1000, alpha = 0, y = trapScoreText.yOriginal + 60, onComplete = trapScoreTextEndTransition})
            elseif event.other.objectType == "floor" then
                remainingLives = remainingLives - 1

                sounds.play('loseLife')

                -- ball may collide with floor again before its physics body can be reset, so prevent it from being counted as another life lost
                ball.losingLife = true

                if remainingLives > 0 then
                    loseLife()
                else
                    loseLevel()
                end
            end
        end
    end

    -- account for energy lost in the ball's movement by resetting its linear velocity magnitude after each collision
    function ball:postCollision(event)
        if endingLevel then return end

        local linVelX, linVelY = ball:getLinearVelocity()

        local hypotenuse = math.sqrt(linVelX * linVelX + linVelY * linVelY)

        local scaleFactor = 150 / hypotenuse

        ball:setLinearVelocity(linVelX * scaleFactor, linVelY * scaleFactor)
    end

    ball:addEventListener("collision", ball)
    ball:addEventListener("postCollision", ball)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    sounds.playStream('game_music')

    if phase == "did" then
        physics.start()
    end
end

function scene:hide(event)
    local sceneGroup = self.view

    local phase = event.phase

    if event.phase == "will" then
        composer.removeScene("breakout", true)
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
