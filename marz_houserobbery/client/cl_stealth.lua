-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

-- Localized functions
local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local GetEntityVelocity = GetEntityVelocity
local IsPedRunning = IsPedRunning
local IsPedSprinting = IsPedSprinting
local IsPedJumping = IsPedJumping
local IsPedFalling = IsPedFalling
local NetworkIsPlayerTalking = NetworkIsPlayerTalking
local PlaySoundFrontend = PlaySoundFrontend
local DoScreenFadeOut = DoScreenFadeOut
local DoScreenFadeIn = DoScreenFadeIn

-- Check if stealth system is enabled
if not Config.StealthSystem or not Config.StealthSystem.enabled then
    return
end

-- Stealth System Variables
local StealthActive = false
local NoiseLevel = 0
local NPCAwakened = {}
local VoiceDetection = { enabled = false, system = nil }
local lastMovementType = "still"
local lastVoiceLevel = 0
local lastIsTalking = false
local currentNPC = nil
local hasTriggeredWakeup = false
local hasShownNotification = false
local currentHouse = nil

-- Performance variables
local lastNoiseUpdate = 0
local noiseUpdateInterval = 50
local lastUIUpdate = 0
local uiUpdateInterval = 100

-- Initialize voice detection
if Config.StealthSystem.voice and Config.StealthSystem.voice.enabled then
    CreateThread(function()
        Wait(5000) -- Wait for resources to load
        
        local voiceSystems = {
            'pma-voice',
            'saltychat',
            'tokovoip',
            'mumble-voip'
        }
        
        for _, system in ipairs(voiceSystems) do
            if GetResourceState(system) == 'started' then
                VoiceDetection.system = system
                VoiceDetection.enabled = true
                break
            end
        end
    end)
end

-- Optimized stealth update thread
function StartStealthSystem(house)
    if not Config.StealthSystem or not Config.StealthSystem.enabled then return end
    
    local pedConfig = getPedConfig(house)
    if not pedConfig or not pedConfig.sleeping then return end
    
    StealthActive = true
    NoiseLevel = 0
    NPCAwakened[house] = false
    hasTriggeredWakeup = false
    hasShownNotification = false
    currentHouse = house
    
    -- Show UI
    SendNUIMessage({
        action = 'showStealthUI'
    })
    
    -- Main stealth thread
    CreateThread(function()
        while StealthActive do
            local currentTime = GetGameTimer()
            
            -- Update noise calculation
            if (currentTime - lastNoiseUpdate) >= noiseUpdateInterval then
                lastNoiseUpdate = currentTime
                HandlePlayerMovement()
                HandleVoiceDetection()
                UpdateNoiseLevel()
            end
            
            -- Update UI less frequently
            if (currentTime - lastUIUpdate) >= uiUpdateInterval then
                lastUIUpdate = currentTime
                UpdateStealthUI()
            end
            
            Wait(10)
        end
    end)
end

function StopStealthSystem()
    StealthActive = false
    NoiseLevel = 0
    currentNPC = nil
    hasTriggeredWakeup = false
    hasShownNotification = false
    currentHouse = nil
    
    SendNUIMessage({
        action = 'hideStealthUI'
    })
end

-- Optimized movement detection
local movementCache = {
    lastSpeed = 0,
    lastMovementType = "still"
}

function HandlePlayerMovement()
    if not Config.StealthSystem or not Config.StealthSystem.footsteps then return end
    
    local ped = PlayerPedId()
    local velocity = GetEntityVelocity(ped)
    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
    
    -- Cache movement type to reduce calculations
    if math.abs(speed - movementCache.lastSpeed) < 0.1 and movementCache.lastMovementType == lastMovementType then
        return
    end
    
    movementCache.lastSpeed = speed
    
    local movementType = "still"
    local noiseIncrease = 0
    
    if speed > 0.1 then
        local isCrouching = GetPedStealthMovement(ped)
        
        if IsPedSprinting(ped) then
            movementType = "sprinting"
            noiseIncrease = Config.StealthSystem.footsteps.sprintingNoise
        elseif IsPedRunning(ped) then
            movementType = "running"
            noiseIncrease = Config.StealthSystem.footsteps.runningNoise
        elseif isCrouching then
            movementType = "crouching"
            noiseIncrease = Config.StealthSystem.footsteps.crouchingNoise
        else
            movementType = "walking"
            noiseIncrease = Config.StealthSystem.footsteps.walkingNoise
        end
        
        if IsPedJumping(ped) or IsPedFalling(ped) then
            noiseIncrease = noiseIncrease + 5.0
        end
        
        IncreaseNoise(noiseIncrease)
    end
    
    if movementType ~= lastMovementType then
        lastMovementType = movementType
        movementCache.lastMovementType = movementType
        
        SendNUIMessage({
            action = 'updateMovement',
            movementType = movementType,
            noiseLevel = NoiseLevel
        })
    end
end

-- Optimized voice detection
local voiceCheckInterval = 200
local lastVoiceCheck = 0

function HandleVoiceDetection()
    if not VoiceDetection.enabled or not Config.StealthSystem.voice or not Config.StealthSystem.voice.enabled then 
        return 
    end
    
    local currentTime = GetGameTimer()
    if (currentTime - lastVoiceCheck) < voiceCheckInterval then
        return
    end
    lastVoiceCheck = currentTime
    
    local voiceLevel = 0
    local isTalking = false
    
    -- Try native detection first (most performant)
    if NetworkIsPlayerTalking(PlayerId()) then
        isTalking = true
        voiceLevel = 60
    elseif VoiceDetection.system == 'pma-voice' then
        -- Try LocalPlayer state (faster than exports)
        local state = LocalPlayer and LocalPlayer.state
        if state and state['voip:talking'] then
            isTalking = true
            voiceLevel = state['voip:level'] or 50
        end
    end
    
    -- Apply voice noise if talking
    if isTalking and voiceLevel > 0 then
        local voiceConfig = Config.StealthSystem.voice
        local noiseIncrease = 0
        
        if voiceLevel <= voiceConfig.whisperThreshold then
            noiseIncrease = voiceConfig.whisperNoise
        elseif voiceLevel <= voiceConfig.normalThreshold then
            noiseIncrease = voiceConfig.normalNoise
        else
            noiseIncrease = voiceConfig.shoutNoise
        end
        
        IncreaseNoise(noiseIncrease)
    end
    
    -- Update UI only if state changed
    if isTalking ~= lastIsTalking or math.abs(voiceLevel - lastVoiceLevel) > 10 then
        lastIsTalking = isTalking
        lastVoiceLevel = voiceLevel
        
        SendNUIMessage({
            action = 'updateVoice',
            isTalking = isTalking,
            voiceLevel = voiceLevel
        })
    end
end

-- Optimized noise level update
function UpdateNoiseLevel()
    if not Config.StealthSystem or not Config.StealthSystem.noiseBar then return end
    
    local config = Config.StealthSystem.noiseBar
    
    -- Check threshold
    if NoiseLevel >= config.wakeupThreshold and not hasTriggeredWakeup then
        WakeUpNPC()
        return
    end
    
    -- Decay noise
    if NoiseLevel > 0 and not hasTriggeredWakeup then
        NoiseLevel = math.max(0, NoiseLevel - config.decayRate)
    end
end

function IncreaseNoise(amount)
    if not Config.StealthSystem or not Config.StealthSystem.noiseBar then return end
    
    NoiseLevel = math.min(Config.StealthSystem.noiseBar.maxNoise, NoiseLevel + amount)
    
    -- Check threshold immediately
    if NoiseLevel >= Config.StealthSystem.noiseBar.wakeupThreshold and not hasTriggeredWakeup then
        WakeUpNPC()
    end
end

-- Optimized UI update
function UpdateStealthUI()
    if not StealthActive then return end
    
    local barConfig = Config.StealthSystem.noiseBar
    
    SendNUIMessage({
        action = 'updateNoise',
        noiseLevel = NoiseLevel,
        maxNoise = barConfig.maxNoise,
        threshold = barConfig.wakeupThreshold
    })
    
    -- Only show hints when needed
    local showCrouch = NoiseLevel > 30 and lastMovementType ~= "still" and lastMovementType ~= "crouching"
    local showVoice = lastIsTalking and lastVoiceLevel > Config.StealthSystem.voice.whisperThreshold
    
    SendNUIMessage({
        action = 'showHints',
        showCrouch = showCrouch,
        showVoice = showVoice,
        isTalking = lastIsTalking,
        voiceLevel = lastVoiceLevel
    })
end

-- Optimized NPC wakeup
function WakeUpNPC()
    if not currentHouse or hasTriggeredWakeup then return end
    
    hasTriggeredWakeup = true
    NPCAwakened[currentHouse] = true
    NoiseLevel = Config.StealthSystem.noiseBar.maxNoise
    
    if not hasShownNotification then
        hasShownNotification = true
        
        lib.notify({
            title = 'STEALTH COMPROMISED!',
            description = 'You made too much noise and woke up the resident!',
            type = 'error',
            duration = 8000
        })
    end
    
    -- Alert sounds
    CreateThread(function()
        PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
        Wait(300)
        PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
    end)
    
    -- Trigger NPC wakeup
    TriggerEvent("marz_houserobbery:npcAwakened", currentHouse)
    TriggerServerEvent("marz_houserobbery:wakeUpNPC", currentHouse)
end

-- Export functions
exports('StartStealthSystem', StartStealthSystem)
exports('StopStealthSystem', StopStealthSystem)
exports('IncreaseNoise', IncreaseNoise)
exports('IsStealthActive', function() return StealthActive end)
exports('GetNoiseLevel', function() return NoiseLevel end)
exports('ResetStealthSystem', function(house) 
    NPCAwakened[house] = nil
    hasTriggeredWakeup = false
    hasShownNotification = false
    if currentHouse == house then
        NoiseLevel = 0
        currentNPC = nil
    end
end)
exports('SetCurrentNPC', function(npc) currentNPC = npc end)