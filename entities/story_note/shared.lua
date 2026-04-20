ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Сюжетная записка"
ENT.Author = "HorrorMod"
ENT.Spawnable = true
ENT.Category = "Horror Story"

-- Переменная для текста, которую мы сможем менять
function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "NoteText")
end
