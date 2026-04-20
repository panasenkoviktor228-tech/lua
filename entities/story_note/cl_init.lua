include("shared.lua")

-- [1. СОЗДАНИЕ МАТЕРИАЛОВ И ШРИФТОВ]
-- Используем стандартные градиенты GMod, они точно не будут "розовыми"
local grad_tex = Material("gui/gradient")
local paper_color = Color(240, 230, 200) -- Цвет старой бумаги
local ink_color = Color(30, 40, 70)      -- Цвет темно-синих чернил

if CLIENT then
    surface.CreateFont("HandwrittenNote", {
        font = "Comic Sans MS", 
        size = 24,
        weight = 500,
        italic = true, 
        antialias = true,
    })
end

-- [2. СИСТЕМА СВЕЧЕНИЯ (HALO)]
hook.Add("PreDrawHalos", "NoteHighlight", function()
    local ply = LocalPlayer()
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if IsValid(ent) and ent:GetClass() == "story_note" and ply:GetPos():Distance(ent:GetPos()) < 150 then
        halo.Add({ent}, Color(255, 255, 255, 255), 3, 3, 2, true, true)
    end
end)

-- [3. ЛОГИКА СВЕТА]
function ENT:Think()
    if LocalPlayer():GetPos():Distance(self:GetPos()) > 500 then return end

    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = self:GetPos() + Vector(0, 0, 10)
        dlight.r = 255
        dlight.g = 180
        dlight.b = 50
        dlight.brightness = 2 
        dlight.Size = 100 + (math.sin(CurTime() * 4) * 10)
        dlight.Decay = 1000
        dlight.DieTime = CurTime() + 0.1
    end
end

-- [4. ОКНО ПРОЧТЕНИЯ (НОВЫЙ ДИЗАЙН БЕЗ ОШИБОК)]
net.Receive("ShowStoryNote", function()
    local text = net.ReadString()
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(450, 550) -- Чуть увеличили для солидности
    frame:Center()
    frame:SetTitle("") 
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        -- 1. Основной фон бумаги
        draw.RoundedBox(0, 0, 0, w, h, paper_color) 
        
        -- 2. Имитация теней и грязи по краям через градиент
        surface.SetMaterial(grad_tex)
        surface.SetDrawColor(0, 0, 0, 40) -- Легкое затемнение по бокам
        surface.DrawTexturedRectRotated(w/2, h/2, w, h, 90) -- Вертикальный градиент
        surface.DrawTexturedRectRotated(w/2, h/2, w, h, 0)  -- Горизонтальный градиент
        
        -- 3. Плотная темная рамка
        surface.SetDrawColor(50, 40, 20, 220)
        surface.DrawOutlinedRect(0, 0, w, h, 5)
    end

    local label = vgui.Create("DLabel", frame)
    label:SetPos(40, 60)
    label:SetSize(370, 420)
    label:SetText(text)
    label:SetFont("HandwrittenNote") 
    label:SetTextColor(ink_color) 
    label:SetWrap(true)
    label:SetContentAlignment(7)

    local btn = vgui.Create("DButton", frame)
    btn:SetSize(140, 40)
    btn:SetPos(155, 490)
    btn:SetText("ПОЛОЖИТЬ")
    btn.DoClick = function() 
        frame:Close() 
        LocalPlayer():EmitSound("ambient/materials/paper_flick1.wav", 50, 100)
    end
end)

-- [5. ОКНО РЕДАКТОРА]
net.Receive("AdminSetNoteText", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 250)
    frame:SetTitle("Редактор текста")
    frame:Center()
    frame:MakePopup()

    local textEntry = vgui.Create("DTextEntry", frame)
    textEntry:Dock(FILL)
    textEntry:SetMultiline(true)
    textEntry:SetText(ent:GetNoteText() or "")

    local save = vgui.Create("DButton", frame)
    save:Dock(BOTTOM)
    save:SetSize(0, 40)
    save:SetText("СОХРАНИТЬ")
    save.DoClick = function()
        net.Start("AdminSetNoteText")
            net.WriteEntity(ent)
            net.WriteString(textEntry:GetText())
        net.SendToServer()
        frame:Close()
    end
end)
