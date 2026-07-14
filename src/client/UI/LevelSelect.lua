--!strict
-- LevelSelect.lua
-- Campaign level select screen.
-- Reads puzzle data from shared PuzzleDefinitions and displays level number, name, description, difficulty, stars, lock state, and a back button.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResponsiveScaler = require(script.Parent.ResponsiveScaler)

local player = Players.LocalPlayer

local PuzzleDefinitions = require(ReplicatedStorage.Shared.Puzzles.PuzzleDefinitions)
type PuzzleDefinition = PuzzleDefinitions.PuzzleDefinition
type Difficulty = PuzzleDefinitions.Difficulty

local LevelSelect = {}

local COLORS = {
	background = Color3.fromRGB(20, 17, 14),
	woodDark = Color3.fromRGB(45, 30, 20),
	wood = Color3.fromRGB(72, 47, 30),
	woodLight = Color3.fromRGB(94, 64, 39),
	brassDark = Color3.fromRGB(116, 82, 35),
	brass = Color3.fromRGB(178, 132, 58),
	gold = Color3.fromRGB(224, 178, 82),
	goldSoft = Color3.fromRGB(238, 204, 130),
	ink = Color3.fromRGB(30, 24, 18),
	text = Color3.fromRGB(238, 226, 202),
	textDim = Color3.fromRGB(184, 166, 132),
	textLocked = Color3.fromRGB(125, 111, 90),
	starFilled = Color3.fromRGB(238, 204, 130),
	starEmpty = Color3.fromRGB(83, 62, 40),
	easy = Color3.fromRGB(105, 170, 115),
	medium = Color3.fromRGB(220, 178, 82),
	hard = Color3.fromRGB(198, 104, 72),
	expert = Color3.fromRGB(154, 113, 195),
}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function createStroke(parent: Instance, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = parent
end

local function createPadding(parent: Instance, top: number, bottom: number, left: number, right: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingBottom = UDim.new(0, bottom)
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right)
	padding.Parent = parent
end

local function getDifficultyColor(difficulty: Difficulty): Color3
	if difficulty == "Easy" then
		return COLORS.easy
	elseif difficulty == "Medium" then
		return COLORS.medium
	elseif difficulty == "Hard" then
		return COLORS.hard
	elseif difficulty == "Expert" then
		return COLORS.expert
	end

	return COLORS.textDim
end

local function createBackButton(parent: Instance, onBack: (() -> ())?)
	local button = Instance.new("TextButton")
	button.Name = "BackButton"
	button.Size = UDim2.new(0, 120, 0, 40)
	button.Position = UDim2.new(1, -152, 0, 32)
	button.BackgroundColor3 = COLORS.brass
	button.BorderSizePixel = 0
	button.Text = "Back"
	button.TextColor3 = COLORS.ink
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.Parent = parent

	createCorner(button, 8)
	createStroke(button, COLORS.goldSoft, 1)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = COLORS.gold
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = COLORS.brass
	end)

	button.MouseButton1Click:Connect(function()
		if onBack then
			onBack()
		end
	end)
end

local function createStars(parent: Instance, starCount: number, unlocked: boolean): Frame
	local row = Instance.new("Frame")
	row.Name = "Stars"
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
		star.Name = "Star_" .. i
		star.Size = UDim2.new(0, 16, 1, 0)
		star.BackgroundTransparency = 1
		star.Text = "★"
		star.TextColor3 = if unlocked and i <= starCount then COLORS.starFilled else COLORS.starEmpty
		star.Font = Enum.Font.GothamBold
		star.TextSize = 16
		star.Parent = row
	end

	return row
end

local function createLockedBadge(parent: Instance)
	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockedBadge"
	lockLabel.Size = UDim2.new(0, 28, 0, 28)
	lockLabel.Position = UDim2.new(1, -36, 0, 8)
	lockLabel.BackgroundColor3 = COLORS.ink
	lockLabel.BorderSizePixel = 0
	lockLabel.Text = "🔒"
	lockLabel.TextColor3 = COLORS.textDim
	lockLabel.Font = Enum.Font.GothamBold
	lockLabel.TextSize = 14
	lockLabel.Parent = parent

	createCorner(lockLabel, 999)
	createStroke(lockLabel, COLORS.brassDark, 1)
end

local function createDifficultyBadge(parent: Instance, difficulty: Difficulty, unlocked: boolean)
	local badge = Instance.new("TextLabel")
	badge.Name = "DifficultyBadge"
	badge.Size = UDim2.new(0, 88, 0, 22)
	badge.Position = UDim2.new(0.5, -44, 0, 106)
	badge.BackgroundColor3 = getDifficultyColor(difficulty)
	badge.BackgroundTransparency = if unlocked then 0 else 0.45
	badge.BorderSizePixel = 0
	badge.Text = difficulty
	badge.TextColor3 = COLORS.ink
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 12
	badge.Parent = parent

	createCorner(badge, 999)
end

local function createLevelTile(
	parent: Instance,
	puzzle: PuzzleDefinition,
	onLevelSelected: (number) -> ()
)
	local unlocked = puzzle.unlockedByDefault
	local difficulty = PuzzleDefinitions.getDisplayDifficulty(puzzle)
	local starCount = 0

	local tile = Instance.new("TextButton")
	tile.Name = "Level_" .. puzzle.id
	tile.Text = ""
	tile.BackgroundColor3 = if unlocked then COLORS.wood else COLORS.woodDark
	tile.BorderSizePixel = 0
	tile.AutoButtonColor = unlocked
	tile.Active = unlocked
	tile.LayoutOrder = puzzle.id
	tile.Parent = parent

	createCorner(tile, 12)
	createStroke(tile, if unlocked then COLORS.brass else COLORS.brassDark, 2)

	local numberLabel = Instance.new("TextLabel")
	numberLabel.Name = "LevelNumber"
	numberLabel.Size = UDim2.new(0, 54, 0, 42)
	numberLabel.Position = UDim2.new(0, 12, 0, 10)
	numberLabel.BackgroundTransparency = 1
	numberLabel.Text = tostring(puzzle.id)
	numberLabel.TextColor3 = if unlocked then COLORS.goldSoft else COLORS.textLocked
	numberLabel.Font = Enum.Font.Garamond
	numberLabel.TextSize = 34
	numberLabel.TextXAlignment = Enum.TextXAlignment.Left
	numberLabel.Parent = tile

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "LevelName"
	nameLabel.Size = UDim2.new(1, -78, 0, 36)
	nameLabel.Position = UDim2.new(0, 68, 0, 14)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = puzzle.name
	nameLabel.TextColor3 = if unlocked then COLORS.text else COLORS.textLocked
	nameLabel.Font = Enum.Font.Garamond
	nameLabel.TextSize = 24
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = tile

	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "Description"
	descriptionLabel.Size = UDim2.new(1, -24, 0, 42)
	descriptionLabel.Position = UDim2.new(0, 12, 0, 58)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Text = puzzle.description
	descriptionLabel.TextColor3 = if unlocked then COLORS.textDim else COLORS.textLocked
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.TextSize = 12
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
	descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
	descriptionLabel.Parent = tile

	createDifficultyBadge(tile, difficulty, unlocked)

	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "ScoreHint"
	scoreLabel.Size = UDim2.new(1, -24, 0, 18)
	scoreLabel.Position = UDim2.new(0, 12, 1, -52)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = "Best: -- cycles / -- cost / -- area"
	scoreLabel.TextColor3 = if unlocked then COLORS.textDim else COLORS.textLocked
	scoreLabel.Font = Enum.Font.Gotham
	scoreLabel.TextSize = 11
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Center
	scoreLabel.Parent = tile

	local stars = createStars(tile, starCount, unlocked)
	stars.Position = UDim2.new(0, 0, 1, -28)

	if not unlocked then
		createLockedBadge(tile)
	end

	if unlocked then
		tile.MouseEnter:Connect(function()
			tile.BackgroundColor3 = COLORS.woodLight
		end)

		tile.MouseLeave:Connect(function()
			tile.BackgroundColor3 = COLORS.wood
		end)

		tile.MouseButton1Click:Connect(function()
			onLevelSelected(puzzle.id)
		end)
	end
end

function LevelSelect.build(onLevelSelected: (number) -> (), onBack: (() -> ())?): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LevelSelectScreen"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	ResponsiveScaler.attach(screenGui)

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = COLORS.background
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	createBackButton(backdrop, onBack)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.new(0, 0, 0, 42)
	title.BackgroundTransparency = 1
	title.Text = "LEVEL SELECT"
	title.TextColor3 = COLORS.goldSoft
	title.Font = Enum.Font.Garamond
	title.TextSize = 44
	title.Parent = backdrop

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 28)
	subtitle.Position = UDim2.new(0, 0, 0, 96)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Choose a puzzle, review its difficulty, and improve your solution."
	subtitle.TextColor3 = COLORS.textDim
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 15
	subtitle.Parent = backdrop

	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "GridFrame"
	gridFrame.Size = UDim2.new(0, 900, 1, -180)
	gridFrame.Position = UDim2.new(0.5, -450, 0, 140)
	gridFrame.BackgroundColor3 = COLORS.woodDark
	gridFrame.BorderSizePixel = 0
	gridFrame.Parent = backdrop

	createCorner(gridFrame, 16)
	createStroke(gridFrame, COLORS.brass, 2)
	createPadding(gridFrame, 12, 12, 12, 12)

	local grid = Instance.new("ScrollingFrame")
	grid.Name = "LevelGrid"
	grid.Size = UDim2.new(1, 0, 1, 0)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 6
	grid.ScrollBarImageColor3 = COLORS.brass
	grid.CanvasSize = UDim2.new(0, 0, 0, 0)
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.Parent = gridFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 270, 0, 190)
	gridLayout.CellPadding = UDim2.new(0, 22, 0, 22)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	local puzzles = PuzzleDefinitions.getAll()

	for _, puzzle in ipairs(puzzles) do
		createLevelTile(grid, puzzle, onLevelSelected)
	end

	return screenGui
end

return LevelSelect