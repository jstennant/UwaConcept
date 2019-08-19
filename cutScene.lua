local composer = require("composer")

local scene = composer.newScene()

local params = nil

function scene:create(event)
    local sceneGroup = self.view

    params = event.params

    -- display the parameterised background
    local background = display.newImageRect(params.background, display.actualContentWidth, display.actualContentWidth * 0.875)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    sceneGroup:insert(background)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "did") then
        local function nextScene(event)
            -- go to the parameterised scene with the parameterised options unless there was no parameterised scene in which case, default to the menu scene
            if params then
                composer.gotoScene(params.scene, params.forwardedOptions)
            else
                composer.gotoScene("menu", "fade", 500)
            end
            params = nil
        end

        timer.performWithDelay(1000, nextScene)
    end
end

function scene:hide(event)
    composer.removeScene("cutScene", true)
end

function scene:destroy(event)

end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene