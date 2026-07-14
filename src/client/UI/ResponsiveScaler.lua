--!strict
-- ResponsiveScaler.lua
-- Adds a UIScale to a ScreenGui and updates it based on the current viewport size.
-- This keeps large fixed-position UI layouts usable on smaller screens.

local Workspace = game:GetService("Workspace")

local ResponsiveScaler = {}

local DESIGN_WIDTH = 1280
local DESIGN_HEIGHT = 720

local MIN_SCALE = 0.62
local MAX_SCALE = 1.05

local function getViewportSize(): Vector2
	local camera = Workspace.CurrentCamera

	if not camera then
		return Vector2.new(DESIGN_WIDTH, DESIGN_HEIGHT)
	end

	return camera.ViewportSize
end

local function calculateScale(viewportSize: Vector2): number
	local widthScale = viewportSize.X / DESIGN_WIDTH
	local heightScale = viewportSize.Y / DESIGN_HEIGHT
	local scale = math.min(widthScale, heightScale)

	return math.clamp(scale, MIN_SCALE, MAX_SCALE)
end

function ResponsiveScaler.attach(screenGui: ScreenGui): UIScale
	local existing = screenGui:FindFirstChild("ResponsiveScale")

	if existing and existing:IsA("UIScale") then
		return existing
	end

	local uiScale = Instance.new("UIScale")
	uiScale.Name = "ResponsiveScale"
	uiScale.Scale = calculateScale(getViewportSize())
	uiScale.Parent = screenGui

	local camera = Workspace.CurrentCamera

	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if uiScale.Parent then
				uiScale.Scale = calculateScale(camera.ViewportSize)
			end
		end)
	end

	return uiScale
end

return ResponsiveScaler