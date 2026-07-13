--!strict
print("[Client] Rojo sync działa po stronie klienta!")

local LevelSelect = require(script.Parent.UI.LevelSelect)
local HUD = require(script.Parent.UI.HUD)

local levelSelectGui = LevelSelect.build(function(levelId: number)
	print("Wybrano poziom:", levelId)
	levelSelectGui:Destroy()
	HUD.build()
	-- TODO: tu docelowo załadujemy dane konkretnego poziomu (PuzzleDefinitions)
end)

print("[Client] Ekran wyboru poziomu zbudowany")