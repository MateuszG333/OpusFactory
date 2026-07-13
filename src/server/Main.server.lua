--!strict
print("[Client] Rojo sync działa po stronie klienta!")

local Players = game:GetService("Players")
local HUD = require(script.Parent.UI.HUD)

HUD.build()

print("[Client] HUD zbudowany")