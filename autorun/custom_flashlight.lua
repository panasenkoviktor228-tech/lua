-- ==========================================
-- КАСТОМНЫЙ ФОНАРИК С ГУЛОМ (БЕЗ ТРЕСКА)
-- ==========================================

if SERVER then
    AddCSLuaFile()
    resource.AddFile("sound/flashLightHum.wav")    
    util.AddNetworkString("SyncCustomFlashlight")
    hook.Add("PlayerSwitchFlashlight", "BlockAllFlashlights", function(ply) return false end)
end

if CLIENT then
    local light = nil
    local is_on = false
    local next_flicker = 0
    local current_flicker_val = 1
    local hum_sound = nil 

    local cfg = {
        fov = 25,
        far = 1200,
        brightness = 4,
        color = Color(255, 120, 0)
    }

    local function ToggleLight()
        local ply = LocalPlayer()
        is_on = not is_on

        if is_on then
            ply:EmitSound("items/flashlight1.wav", 60, 100)
            
            -- ЗАПУСК ГУЛА
            hum_sound = CreateSound(ply, "flashLightHum.wav")
            if hum_sound then 
                hum_sound:Play() 
                hum_sound:ChangeVolume(0.4, 0) 
            end

            light = ProjectedTexture()
            light:SetTexture("effects/flashlight001") 
            light:SetFarZ(cfg.far)
            light:SetFOV(cfg.fov)
            light:SetColor(cfg.color)
            light:SetEnableShadows(true)
        else
            -- ОСТАНОВКА ГУЛА
            if hum_sound then hum_sound:Stop() end
            
            if IsValid(light) then light:Remove() end
            light = nil
            is_on = false
            ply:EmitSound("items/flashlight1.wav", 60, 85)
        end
    end

    net.Receive("SyncCustomFlashlight", ToggleLight)
    concommand.Add("cl_toggle_light", ToggleLight)

    hook.Add("Think", "UpdateCustomFlashlightPos", function()
        if is_on and IsValid(light) then
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            
            -- ЛОГИКА МЕРЦАНИЯ ЯРКОСТИ
            if next_flicker < CurTime() then
                local dice = math.random(1, 100)
                if dice > 97 then
                    current_flicker_val = math.Rand(0.05, 0.2)
                    next_flicker = CurTime() + math.Rand(0.1, 0.3)
                elseif dice > 75 then
                    current_flicker_val = math.Rand(0.5, 1.1)
                    next_flicker = CurTime() + 0.03
                else
                    current_flicker_val = math.Rand(0.98, 1.02)
                    next_flicker = CurTime() + 0.1
                end
            end
            
            light:SetPos(ply:GetShootPos())
            light:SetAngles(ply:EyeAngles())
            light:SetBrightness(cfg.brightness * current_flicker_val)
            light:Update()
        end
    end)

    hook.Add("PlayerBindPress", "CustomFlashlightBind", function(ply, bind, pressed)
    if string.find(bind, "impulse 100") and pressed then
        RunConsoleCommand("cl_toggle_light")
        return true -- Это заблокирует стандартный фонарик Garry's Mod
    end
end)


    hook.Add("PlayerDeath", "RemoveLightDeath", function()
        if hum_sound then hum_sound:Stop() end
        if IsValid(light) then light:Remove() light = nil is_on = false end
    end)
end
