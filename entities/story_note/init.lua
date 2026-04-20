AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- РЕГИСТРИРУЕМ ВСЕ СТРОКИ ЗАРАНЕЕ
util.AddNetworkString("AdminSetNoteText")
util.AddNetworkString("ShowStoryNote")

function ENT:Initialize()
    self:SetModel("models/props_lab/clipboard.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if activator:IsSuperAdmin() and activator:KeyDown(IN_SPEED) then
        net.Start("AdminSetNoteText")
            net.WriteEntity(self) -- ИСПРАВЛЕНО (было Entity)
        net.Send(activator)
    else
        net.Start("ShowStoryNote")
            net.WriteString(self:GetNoteText() or "Тут пусто.")
        net.Send(activator)
    end
end

net.Receive("AdminSetNoteText", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    local ent = net.ReadEntity()
    local text = net.ReadString()
    
    -- Добавляем проверку безопасности
    if IsValid(ent) and ent:GetClass() == "story_note" then
        ent:SetNoteText(text)
        -- Чтобы изменения сохранились при перезагрузке (опционально)
        ent:Activate() 
    end
end)

