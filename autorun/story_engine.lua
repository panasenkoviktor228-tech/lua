-- ==========================================
-- СЮЖЕТНЫЙ ДВИЖОК (ГЛОБАЛЬНЫЙ ПРОГРЕСС)
-- ==========================================
StorySteps = StorySteps or {}

if SERVER then

    hook.Add("PlayerInitialSpawn", "InitPlayerStoryFlags", function(ply)
    ply.HasReadNote = false
end)

    local IsWaiting = false -- Общий статус ожидания перехода
    local next_check = 0
    local StoryStarted = false
    SERVER_StoryStep = 0 -- Глобальный шаг для всего сервера

    util.AddNetworkString("SyncStoryStep") -- Для мгновенного обновления HUD

    local function RunStepCommands(stepID)
        if not StorySteps or not StorySteps[stepID] then return end
        local data = StorySteps[stepID]
        if not data.onStart then return end
        
        -- Выполняем серверные команды
        for _, cmd in ipairs(data.onStart.server or {}) do
            game.ConsoleCommand(cmd .. "\n")
        end

        -- Выполняем клиентские команды для ВСЕХ
        for _, cmd in ipairs(data.onStart.client or {}) do
            for _, p in ipairs(player.GetAll()) do
                p:ConCommand(cmd)
            end
        end
    end

    -- Функция для смены шага всем игрокам
        local function SetGlobalStep(step)
        SERVER_StoryStep = step
        SetGlobalInt("CurrentStoryStep", step) -- Правильная функция GMod
        net.Start("SyncStoryStep")
            net.WriteInt(step, 16)
        net.Broadcast()
    end


    concommand.Add("sv_start_story", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        
        local chapterNum = args[1] or "1"
        local fileName = "chapter" .. chapterNum .. ".lua"

        if file.Exists("autorun/" .. fileName, "LUA") then
            include(fileName)
            AddCSLuaFile(fileName)
            
            -- Заставляем всех клиентов подгрузить файл главы
            for _, p in ipairs(player.GetAll()) do
                p:SendLua([[include("]] .. fileName .. [[")]])
            end
            
            StoryStarted = true
            SetGlobalStep(1)
            
            for _, p in ipairs(player.GetAll()) do
                p:EmitSound("ambient/alarms/warningbell1.wav", 75, 100)
                p:ChatPrint("[СЮЖЕТ] Запущена Глава " .. chapterNum)
            end
            
            timer.Simple(1, function() RunStepCommands(1) end)
        end
    end)

     hook.Add("Think", "StoryZoneLogic", function()
        if not StoryStarted or not StorySteps or IsWaiting then return end
        if (next_check or 0) > CurTime() then return end
        next_check = CurTime() + 0.5

        local data = StorySteps[SERVER_StoryStep]
        if not data then return end

        local stepTriggered = false

        for _, ply in ipairs(player.GetAll()) do
            if not ply:Alive() then continue end

            local targetPos = data.waitPos or data.pos
            local dist = ply:GetPos():Distance(targetPos)

            -- НОВАЯ ЛОГИКА: Проверка записки
            if data.isNote then
                if dist < 200 and ply.HasReadNote then 
                    stepTriggered = true 
                    break 
                end
            elseif data.isInteract then
                if dist < 100 and ply:KeyDown(IN_USE) then stepTriggered = true break end
            else
                if dist < 200 then stepTriggered = true break end
            end
        end

        if stepTriggered then
            IsWaiting = true
            
            -- Сбрасываем флаг чтения для следующего шага
            for _, p in ipairs(player.GetAll()) do p.HasReadNote = false end
            
            for _, p in ipairs(player.GetAll()) do
                p:EmitSound("buttons/button14.wav", 60, 100)
                p:PrintMessage(HUD_PRINTCENTER, "ЗАДАНИЕ ВЫПОЛНЕНО")
            end

            timer.Simple(3, function()
                local nextStep = SERVER_StoryStep + 1
                if StorySteps[nextStep] then
                    SetGlobalStep(nextStep)
                    RunStepCommands(nextStep)
                    IsWaiting = false
                else
                    for _, p in ipairs(player.GetAll()) do
                        p:ChatPrint("[СЮЖЕТ] Глава завершена.")
                    end
                    StoryStarted = false
                    SetGlobalStep(0)
                end
            end)
        end
    end)

    -- ХУК: Ловим момент прочтения записки
    hook.Add("OnStoryNoteRead", "RegisterNoteProgress", function(noteEnt, ply)
        if not IsValid(ply) then return end
        
        -- Помечаем, что игрок прочитал записку
        ply.HasReadNote = true
        ply:ChatPrint("[!] Вы изучили информацию.") 
    end)
end

if CLIENT then
    local CurrentStep = 0

    net.Receive("SyncStoryStep", function()
        CurrentStep = net.ReadInt(16)
    end)

    hook.Add("HUDPaint", "DrawStoryHUD", function()
        if not StorySteps or CurrentStep == 0 then return end
        local data = StorySteps[CurrentStep]
        if not data then return end

        draw.SimpleText("ОБЩАЯ ЗАДАЧА: " .. data.msg, "GModNotify", ScrW()/2, ScrH() - 80, Color(255, 255, 255), TEXT_ALIGN_CENTER)

        if data.hideMarker then return end

        local lp = LocalPlayer()
        local dist_to_marker = lp:GetPos():Distance(data.pos)
        local dist_meters = math.floor(dist_to_marker * 0.019)
        
        draw.SimpleText("РАССТОЯНИЕ: " .. dist_meters .. "м", "GModNotify", ScrW()/2, ScrH() - 60, Color(255, 200, 0), TEXT_ALIGN_CENTER)

        local screenPos = data.pos:ToScreen()
        if screenPos.visible then
            draw.SimpleText("!", "DermaLarge", screenPos.x, screenPos.y, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(data.name, "ChatFont", screenPos.x, screenPos.y + 25, Color(255, 200, 0), TEXT_ALIGN_CENTER)
        end
    end)
end
