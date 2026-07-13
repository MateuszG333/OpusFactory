--!strict
-- LevelSelect.lua
-- Ekran wyboru poziomu - siatka kafelków z gwiazdkami, pokazywany przed wejściem w HUD gry.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local LevelSelect = {}

local COLORS = {
	background = Color3.fromRGB(30, 32, 37),
	panel = Color3.fromRGB(50, 53, 61),
	panelBorder = Color3.fromRGB(70, 74, 84),
	accent = Color3.fromRGB(150, 170, 190),
	text = Color3.fromRGB(220, 222, 228),
	textDim = Color3.fromRGB(140, 143, 150),
	starFilled = Color3.fromRGB(220, 190, 120),
	starEmpty = Color3.fromRGB(70, 74, 84),
}

-- Placeholder dane poziomów - docelowo przyjdą z PuzzleDefinitions.lua
local PLACEHOLDER_LEVELS = {
	{ id = 1, name = "Pierwsze kroki", stars = 0, unlocked = true },
	{ id = 2, name = "Rotacja", stars = 0, unlocked = true },
	{ id = 3, name = "Wiązanie", stars = 0, unlocked = false },
	{ id = 4, name = "Tor", stars = 0, unlocked = false },
	{ id = 5, name = "Kalcynacja", stars = 0, unlocked = false },
	{ id = 6, name = "???", stars = 0, unlocked = false },
}

local function createStars(parent: Instance, starCount: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 18)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 2)
	layout.Parent = row

	for i = 1, 3 do
		local star = Instance.new("TextLabel")
		star.Size = UDim2.new(0, 16, 1, 0)
		star.BackgroundTransparency = 1
		star.Text = "★"
		star.TextColor3 = (i <= starCount) and COLORS.starFilled or COLORS.starEmpty
		star.Font = Enum.Font.GothamBold
		star.TextSize = 16
		star.Parent = row
	end

	return row
end

-- onLevelSelected: callback(levelId: number) wołany po kliknięciu odblokowanego poziomu
function LevelSelect.build(onLevelSelected: (number) -> ()): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LevelSelectScreen"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = COLORS.background
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.new(0, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "WYBIERZ POZIOM"
	title.TextColor3 = COLORS.text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 32
	title.Parent = backdrop

	local grid = Instance.new("ScrollingFrame")
	grid.Size = UDim2.new(0, 700, 1, -180)
	grid.Position = UDim2.new(0.5, -350, 0, 120)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 6
	grid.CanvasSize = UDim2.new(0, 0, 0, 0) -- auto przez UIGridLayout + AutomaticCanvasSize
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.Parent = backdrop

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 160, 0, 160)
	gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = grid

	for _, levelData in ipairs(PLACEHOLDER_LEVELS) do
		local tile = Instance.new("TextButton")
		tile.Name = "Level_" .. levelData.id
		tile.Text = ""
		tile.BackgroundColor3 = COLORS.panel
		tile.BorderSizePixel = 0
		tile.AutoButtonColor = levelData.unlocked

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = tile

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.panelBorder
		stroke.Thickness = 1
		stroke.Parent = tile

		if not levelData.unlocked then
			tile.BackgroundTransparency = 0.3
		end

		local numberLabel = Instance.new("TextLabel")
		numberLabel.Size = UDim2.new(1, 0, 0, 40)
		numberLabel.Position = UDim2.new(0, 0, 0, 16)
		numberLabel.BackgroundTransparency = 1
		numberLabel.Text = levelData.unlocked and tostring(levelData.id) or "🔒"
		numberLabel.TextColor3 = levelData.unlocked and COLORS.text or COLORS.textDim
		numberLabel.Font = Enum.Font.GothamBold
		numberLabel.TextSize = 28
		numberLabel.Parent = tile

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -12, 0, 36)
		nameLabel.Position = UDim2.new(0, 6, 0, 60)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = levelData.unlocked and levelData.name or ""
		nameLabel.TextColor3 = COLORS.textDim
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 13
		nameLabel.TextWrapped = true
		nameLabel.Parent = tile

		if levelData.unlocked then
			createStars(tile, levelData.stars).Position = UDim2.new(0, 0, 1, -34)

			tile.MouseButton1Click:Connect(function()
				onLevelSelected(levelData.id)
			end)
		end

		tile.Parent = grid
	end

	return screenGui
end

return LevelSelect