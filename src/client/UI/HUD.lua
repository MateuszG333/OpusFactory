--!strict
-- HUD.lua
-- In-level UI styled like the main menu.
-- Includes piece palette icons and a sequencer-like instruction cycle table:
-- command blocks at the top, arm rows below, and expandable cycle columns.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local PieceIcons = require(script.Parent.PieceIcons)
local ResponsiveScaler = require(script.Parent.ResponsiveScaler)
local CommandCycle = require(script.Parent.CommandCycle)

local HUD = {}

export type PuzzleLike = {
	id: number,
	name: string,
	description: string,
	difficulty: string,
	gridRadius: number,
}

type InstructionDef = {
	label: string,
	short: string,
	color: Color3,
}

type PieceDef = {
	name: string,
	description: string,
}

local COLORS = {
	background = Color3.fromRGB(24, 24, 26),
	woodDark = Color3.fromRGB(38, 38, 41),
	wood = Color3.fromRGB(52, 52, 56),
	woodLight = Color3.fromRGB(66, 66, 71),
	brassDark = Color3.fromRGB(70, 68, 62),
	brass = Color3.fromRGB(108, 102, 88),
	gold = Color3.fromRGB(140, 132, 112),
	goldSoft = Color3.fromRGB(160, 152, 132),
	ink = Color3.fromRGB(24, 24, 26),
	text = Color3.fromRGB(214, 212, 206),
	textDim = Color3.fromRGB(150, 148, 144),
	greenGlass = Color3.fromRGB(88, 128, 100),
	blueSteel = Color3.fromRGB(88, 112, 132),
	redWax = Color3.fromRGB(140, 78, 70),
	slotEmpty = Color3.fromRGB(44, 44, 48),
	slotFilled = Color3.fromRGB(70, 70, 76),
	rowLabel = Color3.fromRGB(54, 54, 58),
}

-- === Layout constants (design resolution 1920x1080) ===
local MARGIN = 16
local GAP = 12
local TOP_Y = 20
local TOP_HEIGHT = 52
local PARTS_WIDTH = 240
local LEVEL_WIDGET_W = 180
local LEVEL_WIDGET_H = 120
local COMMAND_HEIGHT = 230

local PIECES: { PieceDef } = {
	{ name = "Arm", description = "Move and rotate atoms." },
	{ name = "Track", description = "Move an arm base." },
	{ name = "Bonder", description = "Create bonds." },
	{ name = "Glyph", description = "Transform atoms." },
}

local INSTRUCTIONS: { InstructionDef } = {
	{ label = "Grab", short = "GR", color = COLORS.greenGlass },
	{ label = "Drop", short = "DR", color = COLORS.redWax },
	{ label = "RotateCW", short = "R+", color = COLORS.brass },
	{ label = "RotateCCW", short = "R-", color = COLORS.brassDark },
	{ label = "Forward", short = "FW", color = COLORS.blueSteel },
	{ label = "Backward", short = "BW", color = COLORS.blueSteel },
	{ label = "Wait", short = "..", color = COLORS.woodLight },
}

local INSTRUCTION_BY_LABEL: { [string]: InstructionDef } = {}
for _, instruction in ipairs(INSTRUCTIONS) do
	INSTRUCTION_BY_LABEL[instruction.label] = instruction
end

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

local function createPanel(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local outer = Instance.new("Frame")
	outer.Name = name
	outer.Size = size
	outer.Position = position
	outer.BackgroundColor3 = COLORS.woodDark
	outer.BorderSizePixel = 0
	outer.Parent = parent

	createCorner(outer, 8)
	createStroke(outer, COLORS.brassDark, 1)

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.new(1, -8, 1, -8)
	inner.Position = UDim2.new(0, 4, 0, 4)
	inner.BackgroundColor3 = COLORS.wood
	inner.BorderSizePixel = 0
	inner.Parent = outer

	createCorner(inner, 6)

	return inner
end

local function pointInside(gui: GuiObject, point: Vector2): boolean
	local position = gui.AbsolutePosition
	local size = gui.AbsoluteSize

	return point.X >= position.X
		and point.X <= position.X + size.X
		and point.Y >= position.Y
		and point.Y <= position.Y + size.Y
end

local function createBackButton(parent: Instance, onBack: (() -> ())?)
	local button = Instance.new("TextButton")
	button.Name = "BackButton"
	button.Size = UDim2.new(0, 120, 0, 40)
	button.Position = UDim2.new(1, -152, 0, 24)
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

local function createLevelWidget(parent: Instance, puzzle: PuzzleLike)
	local panel = createPanel(
		parent,
		"LevelWidget",
		UDim2.new(0, LEVEL_WIDGET_W, 0, LEVEL_WIDGET_H),
		UDim2.new(1, -(MARGIN + LEVEL_WIDGET_W), 0, TOP_Y + TOP_HEIGHT + GAP)
	)
	createPadding(panel, 8, 8, 10, 10)

	local title = Instance.new("TextLabel")
	title.Name = "PuzzleTitle"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = string.format("%02d  %s", puzzle.id, puzzle.name)
	title.TextColor3 = COLORS.text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = panel

	local meta = Instance.new("TextLabel")
	meta.Name = "PuzzleMeta"
	meta.Size = UDim2.new(1, 0, 0, 16)
	meta.Position = UDim2.new(0, 0, 0, 22)
	meta.BackgroundTransparency = 1
	meta.Text = puzzle.difficulty .. "  ·  R" .. puzzle.gridRadius
	meta.TextColor3 = COLORS.textDim
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 11
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.Parent = panel

	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "Description"
	descriptionLabel.Size = UDim2.new(1, 0, 1, -46)
	descriptionLabel.Position = UDim2.new(0, 0, 0, 44)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Text = puzzle.description
	descriptionLabel.TextColor3 = COLORS.textDim
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.TextSize = 10
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
	descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
	descriptionLabel.Parent = panel
end

local function createControls(parent: Instance, onCenterCamera: (() -> ())?)
	local panel = createPanel(
		parent,
		"TopControlsPanel",
		UDim2.new(1, -MARGIN * 2, 0, TOP_HEIGHT),
		UDim2.new(0, MARGIN, 0, TOP_Y)
	)
	createPadding(panel, 6, 6, 12, 12)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local buttons = {
		{ name = "RunButton", text = "Run", color = COLORS.greenGlass, order = 1 },
		{ name = "PauseButton", text = "Pause", color = COLORS.brass, order = 2 },
		{ name = "StepButton", text = "Step", color = COLORS.blueSteel, order = 3 },
		{ name = "ResetButton", text = "Reset", color = COLORS.redWax, order = 4 },
	}

	for _, data in ipairs(buttons) do
		local button = Instance.new("TextButton")
		button.Name = data.name
		button.LayoutOrder = data.order
		button.Size = UDim2.new(0, 72, 0, 38)
		button.BackgroundColor3 = data.color
		button.BorderSizePixel = 0
		button.Text = data.text
		button.TextColor3 = COLORS.ink
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.Parent = panel

		createCorner(button, 8)
		createStroke(button, COLORS.goldSoft, 1)
	end

	local centerButton = Instance.new("TextButton")
	centerButton.Name = "CenterCameraButton"
	centerButton.LayoutOrder = 5
	centerButton.Size = UDim2.new(0, 92, 0, 38)
	centerButton.BackgroundColor3 = COLORS.woodLight
	centerButton.BorderSizePixel = 0
	centerButton.Text = "Center"
	centerButton.TextColor3 = COLORS.text
	centerButton.Font = Enum.Font.GothamBold
	centerButton.TextSize = 14
	centerButton.Parent = panel

	createCorner(centerButton, 8)
	createStroke(centerButton, COLORS.brass, 1)

	centerButton.MouseButton1Click:Connect(function()
		if onCenterCamera then
			onCenterCamera()
		end
	end)

	local cycleLabel = Instance.new("TextLabel")
	cycleLabel.Name = "CycleCounter"
	cycleLabel.LayoutOrder = 6
	cycleLabel.Size = UDim2.new(0, 92, 0, 38)
	cycleLabel.BackgroundColor3 = COLORS.ink
	cycleLabel.BorderSizePixel = 0
	cycleLabel.Text = "Cycle: 0"
	cycleLabel.TextColor3 = COLORS.goldSoft
	cycleLabel.Font = Enum.Font.GothamBold
	cycleLabel.TextSize = 13
	cycleLabel.Parent = panel

	createCorner(cycleLabel, 8)
	createStroke(cycleLabel, COLORS.brassDark, 1)
end

local function createInstructionVisual(parent: Instance, instruction: InstructionDef, size: UDim2): TextButton
	local block = Instance.new("TextButton")
	block.Name = instruction.label .. "Instruction"
	block.Size = size
	block.BackgroundColor3 = instruction.color
	block.BorderSizePixel = 0
	block.Text = ""
	block.ZIndex = 20
	block.Parent = parent

	createCorner(block, 8)
	createStroke(block, COLORS.goldSoft, 1)

	local shortLabel = Instance.new("TextLabel")
	shortLabel.Name = "Short"
	shortLabel.Size = UDim2.new(1, 0, 0, 22)
	shortLabel.Position = UDim2.new(0, 0, 0, 5)
	shortLabel.BackgroundTransparency = 1
	shortLabel.Text = instruction.short
	shortLabel.TextColor3 = COLORS.ink
	shortLabel.Font = Enum.Font.GothamBold
	shortLabel.TextSize = 15
	shortLabel.ZIndex = block.ZIndex + 1
	shortLabel.Parent = block

	local fullLabel = Instance.new("TextLabel")
	fullLabel.Name = "Full"
	fullLabel.Size = UDim2.new(1, -6, 0, 16)
	fullLabel.Position = UDim2.new(0, 3, 1, -19)
	fullLabel.BackgroundTransparency = 1
	fullLabel.Text = instruction.label
	fullLabel.TextColor3 = COLORS.ink
	fullLabel.Font = Enum.Font.Gotham
	fullLabel.TextSize = 10
	fullLabel.TextWrapped = true
	fullLabel.ZIndex = block.ZIndex + 1
	fullLabel.Parent = block

	return block
end

local function setSlotInstruction(slot: Frame, instruction: InstructionDef?)
	local content = slot:FindFirstChild("Content")

	if content then
		content:Destroy()
	end

	if not instruction then
		slot.BackgroundColor3 = COLORS.slotEmpty
		return
	end

	slot.BackgroundColor3 = COLORS.slotFilled

	local block = createInstructionVisual(slot, instruction, UDim2.new(1, -6, 1, -6))
	block.Name = "Content"
	block.Position = UDim2.new(0, 3, 0, 3)
	block.AutoButtonColor = false
	block.Active = false
	block.ZIndex = 5

	for _, child in ipairs(block:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.ZIndex = 6
		end
	end
end

local function createCycleSlot(parent: Instance, cycleIndex: number): Frame
	local slot = Instance.new("Frame")
	slot.Name = "Cycle_" .. cycleIndex
	slot.LayoutOrder = cycleIndex
	slot.Size = UDim2.new(0, 56, 0, 46)
	slot.BackgroundColor3 = COLORS.slotEmpty
	slot.BorderSizePixel = 0
	slot.Parent = parent

	createCorner(slot, 8)
	createStroke(slot, COLORS.brassDark, 1)

	local cycleNumber = Instance.new("TextLabel")
	cycleNumber.Name = "CycleNumber"
	cycleNumber.Size = UDim2.new(0, 18, 0, 14)
	cycleNumber.Position = UDim2.new(0, 3, 0, 2)
	cycleNumber.BackgroundTransparency = 1
	cycleNumber.Text = tostring(cycleIndex)
	cycleNumber.TextColor3 = COLORS.textDim
	cycleNumber.Font = Enum.Font.GothamBold
	cycleNumber.TextSize = 9
	cycleNumber.ZIndex = 8
	cycleNumber.Parent = slot

	return slot
end

local function createArmRowLabel(parent: Instance, armIndex: number)
	local label = Instance.new("TextLabel")
	label.Name = "Arm_" .. armIndex .. "_Label"
	label.LayoutOrder = 0
	label.Size = UDim2.new(0, 68, 0, 46)
	label.BackgroundColor3 = COLORS.rowLabel
	label.BorderSizePixel = 0
	label.Text = "Arm " .. armIndex
	label.TextColor3 = COLORS.goldSoft
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Parent = parent

	createCorner(label, 8)
	createStroke(label, COLORS.brassDark, 1)
end

local function createCycleHeader(parent: Instance, cycleIndex: number)
	local label = Instance.new("TextLabel")
	label.Name = "CycleHeader_" .. cycleIndex
	label.LayoutOrder = cycleIndex
	label.Size = UDim2.new(0, 64, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = tostring(cycleIndex)
	label.TextColor3 = COLORS.textDim
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.Parent = parent
end

local function createPiecePalette(parent: Instance)
	local panel = createPanel(
	parent,
	"PiecePalette",
	UDim2.new(0, PARTS_WIDTH, 1, -(TOP_Y + TOP_HEIGHT + GAP + COMMAND_HEIGHT + GAP + MARGIN)),
	UDim2.new(0, MARGIN, 0, TOP_Y + TOP_HEIGHT + GAP)
)
	createPadding(panel, 8, 8, 6, 6)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = panel

	for _, piece in ipairs(PIECES) do
		local button = Instance.new("TextButton")
		button.Name = piece.name .. "Button"
		button.Size = UDim2.new(1, 0, 0, 64)
		button.BackgroundColor3 = COLORS.woodDark
		button.BorderSizePixel = 0
		button.Text = ""
		button.Parent = panel

		createCorner(button, 8)
		createStroke(button, COLORS.brassDark, 1)

		local iconHolder = Instance.new("Frame")
		iconHolder.Name = "Icon"
		iconHolder.Size = UDim2.new(1, -10, 1, -10)
		iconHolder.Position = UDim2.new(0, 5, 0, 5)
		iconHolder.BackgroundTransparency = 1
		iconHolder.Parent = button

		PieceIcons.create(piece.name, iconHolder)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 16)
		label.Position = UDim2.new(0, 0, 1, -18)
		label.BackgroundTransparency = 1
		label.Text = piece.name
		label.TextColor3 = COLORS.text
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.Parent = button

		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = COLORS.woodLight
		end)

		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = COLORS.woodDark
		end)
	end
end

function HUD.build(puzzle: PuzzleLike, onBack: (() -> ())?, onCenterCamera: (() -> ())?): (ScreenGui, any)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OpusFactoryHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	ResponsiveScaler.attach(screenGui)

	createControls(screenGui, onCenterCamera)
	createLevelWidget(screenGui, puzzle)
	createBackButton(screenGui, onBack)
	local cycleController = CommandCycle.build(screenGui)
	createPiecePalette(screenGui)

	-- na razie: dodaj jedno ramię od razu, żeby tabela nie była pusta
	-- (docelowo to zniknie - ramiona pojawią się dopiero gdy gracz je postawi na planszy)
	cycleController.addArm()

	return screenGui, cycleController
end

return HUD