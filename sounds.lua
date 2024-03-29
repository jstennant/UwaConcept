
local _M = {}

_M.isSoundOn = true
_M.isMusicOn = true

local sounds =
{
    menu_music = 'sounds/menu_music.mp3',
    game_music = 'sounds/game_music.mp3',
    click = 'sounds/Click.wav',
    smash = 'sounds/Smash.wav',
    bounce = 'sounds/Bounce.wav',
    trap = 'sounds/Trap.wav',
    loseLife = 'sounds/LoseLife.wav'
}

-- Reserve two channels for streams and switch between them with a nice fade out / fade in transition
local audioChannel, otherAudioChannel, currentStreamSound = 1, 2
function _M.playStream(sound, force)
    if not _M.isMusicOn then return end
    if not sounds[sound] then
        print('sounds: no such sound: ' .. tostring(sound))
        return
    end
    sound = sounds[sound]
    if currentStreamSound == sound and not force then return end
    audio.fadeOut({channel = audioChannel, time = 500})
    audioChannel, otherAudioChannel = otherAudioChannel, audioChannel
    audio.setVolume(0.5, {channel = audioChannel})
    audio.play(audio.loadStream(sound), {channel = audioChannel, loops = -1, fadein = 500})
    currentStreamSound = sound
end
audio.reserveChannels(2)

-- Keep all loaded sounds here
local loadedSounds = {}
local function loadSound(sound)
    if not loadedSounds[sound] then
        loadedSounds[sound] = audio.loadSound(sounds[sound])
    end
    return loadedSounds[sound]
end

function _M.preLoadSound(sound)
    loadSound(sound)
end

function _M.play(sound, params)
    if not _M.isSoundOn then return end
    if not sounds[sound] then
        print('sounds: no such sound: ' .. tostring(sound))
        return
    end
    return audio.play(loadSound(sound), params)
end

function _M.stop()
    currentStreamSound = nil
    audio.stop()
end

return _M
