local birds_to_mute = {
    ["brd1"] = true,
    ["brd2"] = true,
    ["brd3"] = true,
    ["brd4"] = true
}

-- 1. БЛОКИРОВКА ЗВУКОВ ПТИЦ
hook.Add("EntityEmitSound", "GlobalSilentBirds", function(data)
    if not data.SoundName then return end
    local soundName = string.StripExtension(string.GetFileFromFilename(data.SoundName:lower()))
    if birds_to_mute[soundName] then
        return false 
    end
end)

-- ==========================================
-- СЕРВЕРНАЯ ЧАСТЬ
-- ==========================================
if SERVER then
    -- Сброс освещения при загрузке карты
    hook.Add("InitPostEntity", "ResetLightOnStart", function()
        engine.LightStyle(0, "z") 
    end)

    -- Принудительный дневной свет для зашедшего игрока
    hook.Add("PlayerInitialSpawn", "ForceLightReset", function(ply)
        timer.Simple(2, function()
            if IsValid(ply) then
                engine.LightStyle(0, "z")
                ply:SendLua("render.RedownloadAllLightmaps()")
            end
        end)
    end)

    -- ВЫДАЧА ОРУЖИЯ (Фонарик здесь только разрешаем, настройки убраны)
    hook.Add("PlayerLoadout", "CustomStoryLoadout", function(ply)
        ply:StripWeapons() 
        ply:Give("weapon_fists")        
        ply:Give("gmod_camera")
        ply:Give("weapon_medkit")
        
        ply:AllowFlashlight(true) 
        return true 
    end)

    -- Команда управления ночным режимом (Серверная часть)
    concommand.Add("sv_story_night", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end 
        local state = tonumber(args[1]) == 1
        if state then
            engine.LightStyle(0, "d") 
            PrintMessage(HUD_PRINTTALK, "[СЕРВЕР] Режим ночи активирован.")
        else
            engine.LightStyle(0, "z") 
            for _, v in ipairs(player.GetAll()) do
                v:ConCommand("ent_fire env_sun exposure 1")
                v:ConCommand("ent_fire env_skypaint setlightcolor 255 255 255")
            end
            PrintMessage(HUD_PRINTTALK, "[СЕРВЕР] Режим ночи отключен.")
        end
        for _, v in ipairs(player.GetAll()) do
            v:SendLua("render.RedownloadAllLightmaps()")
        end
    end)
end

-- ==========================================
-- КЛИЕНТСКАЯ ЧАСТЬ
-- ==========================================
if CLIENT then
    local night_active = false 
    local bob_time = 0
    local bob_offset = Vector(0, 0, 0)

    -- Переключатель визуальных эффектов ночи
    concommand.Add("story_night", function(ply, cmd, args)
        local state = tonumber(args[1]) == 1
        night_active = state
        chat.AddText(Color(255, 200, 0), "[КЛИЕНТ] Визуальный эффект ночи: ", Color(255, 255, 255), state and "ВКЛ" or "ВЫКЛ")
    end)

    -- 1. ЦВЕТОКОРРЕКЦИЯ
    hook.Add("RenderScreenspaceEffects", "NightVisionEffect", function()
        if not night_active then return end 
        local nightScale = {
            [ "$pp_colour_addr" ] = 0, [ "$pp_colour_addg" ] = 0, [ "$pp_colour_addb" ] = 0.02,
            [ "$pp_colour_brightness" ] = -0.07, [ "$pp_colour_contrast" ] = 1.4, [ "$pp_colour_colour" ] = 0.3,
            [ "$pp_colour_mulr" ] = 0, [ "$pp_colour_mulg" ] = 0, [ "$pp_colour_mulb" ] = 0
        }
        DrawColorModify(nightScale)
    end)

    -- 2. ПОКАЧИВАНИЕ КАМЕРЫ (Sway) ПРИ ДВИЖЕНИИ
    hook.Add("PreRender", "FlashlightSway", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:FlashlightIsOn() then return end
        local vel = ply:GetVelocity():Length()
        if vel > 10 then
            bob_time = bob_time + FrameTime() * (vel / 110)
            bob_offset = Vector(math.sin(bob_time * 2) * 1.2, math.cos(bob_time * 4) * 0.6, 0)
        else
            bob_offset = LerpVector(FrameTime() * 5, bob_offset, Vector(0,0,0))
        end
    end)

    -- 3. ПРИМЕНЕНИЕ ПОКАЧИВАНИЯ
    hook.Add("CalcView", "FlashlightViewSway", function(ply, pos, angles, fov)
        if not night_active or not ply:FlashlightIsOn() then return end
        angles.roll = angles.roll + bob_offset.x * 0.5
        angles.pitch = angles.pitch + bob_offset.y
        angles.yaw = angles.yaw + bob_offset.x
    end)
end
