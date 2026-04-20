AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

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

    -- Режим редактора для админа (Shift + E)
    if activator:IsSuperAdmin() and activator:KeyDown(IN_SPEED) then
        net.Start("AdminSetNoteText")
            net.WriteEntity(self)
        net.Send(activator)
    else
        -- Обычное прочтение
        net.Start("ShowStoryNote")
            net.WriteString(self:GetNoteText() or "Тут пусто.")
        net.Send(activator)

        -- [ВОТ ТУТ ПРАВИЛЬНОЕ МЕСТО ДЛЯ ХУКА]
        -- Сообщаем системе сюжета, что эта записка прочитана
        hook.Run("OnStoryNoteRead", self, activator)
    end
end

net.Receive("AdminSetNoteText", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    local ent = net.ReadEntity()
    local text = net.ReadString()
    
    if IsValid(ent) and ent:GetClass() == "story_note" then
        ent:SetNoteText(text)
    end
end)
