
local composer = require("composer")
local scene = composer.newScene()
local sounds = require('sounds')

function scene:create(event)
    local sceneGroup = self.view

    -- Avoid delay in initial playback of sounds
    sounds.preLoadSound('click')

    local background = display.newImageRect("images/MenuBackground.png", display.actualContentWidth, display.actualContentWidth * 0.875)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    sceneGroup:insert(background)

    local menuText = display.newText("Pick your game...", display.contentCenterX, 60, "fonts/KarmaFuture.ttf", 40)
    menuText:setFillColor(0, 0, 0)
    sceneGroup:insert(menuText)

    local breakout = display.newImageRect("images/BreakoutIcon.png", 60, 60)
    breakout.x = display.contentCenterX
    breakout.y = display.contentCenterY
    sceneGroup:insert(breakout)

    local function onBreakoutTouch(event)
        if (event.phase == "began") then
            sounds.play('click')

            -- The breakout game expects the current level, score and remaining lives to be passed in as parameters
            local options = {effect = "fade", time = 500, params = {level = 1, score = 0, lives = 3}}

            composer.gotoScene("breakout", options)
        end

        return true
    end

    breakout:addEventListener("touch", onBreakoutTouch)
end

function scene:show(event)
    sounds.playStream('menu_music')
end

function scene:hide(event)

end

function scene:destroy(event)

end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene