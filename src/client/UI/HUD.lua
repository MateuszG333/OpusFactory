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
	greenGlass = Color3.fromRGB(88, 145, 105),
	blueSteel = Color3.fromRGB(92, 133, 160),
	redWax = Color3.fromRGB(145, 56, 46),
	slotEmpty = Color3.fromRGB(56, 39, 26),
	slotFilled = Color3.fromRGB(90, 63, 38),
	rowLabel = Color3.fromRGB(62, 42, 27),
}

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

	createCorner(outer, 14)
	createStroke(outer, COLORS.brassDark, 2)

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.new(1, -12, 1, -12)
	inner.Position = UDim2.new(0, 6, 0, 6)
	inner.BackgroundColor3 = COLORS.wood
	inner.BorderSizePixel = 0
	inner.Parent = outer

	createCorner(inner, 10)

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

local function createTopInfo(parent: Instance, puzzle: PuzzleLike)
	local panel = createPanel(parent, "PuzzleInfoPanel", UDim2.new(0, 430, 0, 118), UDim2.new(0, 24, 0, 24))
	createPadding(panel, 14, 14, 16, 16)

	local title = Instance.new("TextLabel")
	title.Name = "PuzzleTitle"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = string.format("%02d  %s", puzzle.id, puzzle.name)
	title.TextColor3 = COLORS.goldSoft
	title.Font = Enum.Font.Garamond
	title.TextSize = 27
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local meta = Instance.new("TextLabel")
	meta.Name = "PuzzleMeta"
	meta.Size = UDim2.new(1, 0, 0, 20)
	meta.Position = UDim2.new(0, 0, 0, 34)
	meta.BackgroundTransparency = 1
	meta.Text = string.format("Difficulty: %s     Board radius: %d", puzzle.difficulty, puzzle.gridRadius)
	meta.TextColor3 = COLORS.textDim
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 13
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.Parent = panel

	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, 0, 0, 42)
	description.Position = UDim2.new(0, 0, 0, 62)
	description.BackgroundTransparency = 1
	description.Text = puzzle.description
	description.TextColor3 = COLORS.text
	description.Font = Enum.Font.Gotham
	description.TextSize = 13
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Parent = panel
end

local function createHintPanel(parent: Instance)
	local panel = createPanel(parent, "HintPanel", UDim2.new(0, 330, 0, 138), UDim2.new(1, -354, 0, 78))
	createPadding(panel, 14, 14, 16, 16)

	local title = Instance.new("TextLabel")
	title.Name = "HintTitle"
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Text = "Workshop Hint"
	title.TextColor3 = COLORS.goldSoft
	title.Font = Enum.Font.Garamond
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local body = Instance.new("TextLabel")
	body.Name = "HintBody"
	body.Size = UDim2.new(1, 0, 1, -36)
	body.Position = UDim2.new(0, 0, 0, 36)
	body.BackgroundTransparency = 1
	body.Text = "Drag command blocks from the top row into arm timelines. Each row is one arm, and each column is one cycle."
	body.TextColor3 = COLORS.textDim
	body.Font = Enum.Font.Gotham
	body.TextSize = 13
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = panel
end

local function createControls(parent: Instance, onCenterCamera: (() -> ())?)
	local panel = createPanel(parent, "ControlsPanel", UDim2.new(0, 560, 0, 74), UDim2.new(0.5, -280, 0, 150))
	createPadding(panel, 10, 10, 12, 12)

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
	slot.Size = UDim2.new(0, 64, 0, 48)
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
	label.Size = UDim2.new(0, 82, 0, 48)
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

local function createCycleTable(parent: Instance, screenGui: ScreenGui)
	local panel = createPanel(parent, "CycleTablePanel", UDim2.new(0, 980, 0, 218), UDim2.new(0.5, -490, 1, -230))
	createPadding(panel, 10, 10, 12, 12)

	local armCount = 3
	local cycleCount = 10

	local program: { [number]: { [number]: string? } } = {}
	local slotByArmAndCycle: { [number]: { [number]: Frame } } = {}

	for armIndex = 1, armCount do
		program[armIndex] = {}
		slotByArmAndCycle[armIndex] = {}
	end

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 180, 0, 24)
	title.BackgroundTransparency = 1
	title.Text = "Command Cycle"
	title.TextColor3 = COLORS.goldSoft
	title.Font = Enum.Font.Garamond
	title.TextSize = 23
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local commandRow = Instance.new("Frame")
	commandRow.Name = "CommandSourceRow"
	commandRow.Size = UDim2.new(1, -120, 0, 50)
	commandRow.Position = UDim2.new(0, 0, 0, 30)
	commandRow.BackgroundTransparency = 1
	commandRow.Parent = panel

	local commandLayout = Instance.new("UIListLayout")
	commandLayout.FillDirection = Enum.FillDirection.Horizontal
	commandLayout.Padding = UDim.new(0, 8)
	commandLayout.Parent = commandRow

	local addCycleButton = Instance.new("TextButton")
	addCycleButton.Name = "AddCycleButton"
	addCycleButton.Size = UDim2.new(0, 96, 0, 34)
	addCycleButton.Position = UDim2.new(1, -96, 0, 8)
	addCycleButton.BackgroundColor3 = COLORS.brass
	addCycleButton.BorderSizePixel = 0
	addCycleButton.Text = "+ Cycle"
	addCycleButton.TextColor3 = COLORS.ink
	addCycleButton.Font = Enum.Font.GothamBold
	addCycleButton.TextSize = 13
	addCycleButton.Parent = panel

	createCorner(addCycleButton, 8)
	createStroke(addCycleButton, COLORS.goldSoft, 1)

	local timelineScroll = Instance.new("ScrollingFrame")
timelineScroll.Name = "TimelineScroll"
timelineScroll.Size = UDim2.new(1, -72, 1, -88)
timelineScroll.Position = UDim2.new(0, 36, 0, 88)
timelineScroll.BackgroundTransparency = 1
timelineScroll.BorderSizePixel = 0
timelineScroll.Active = true
timelineScroll.ScrollingEnabled = true
timelineScroll.ScrollBarThickness = 8
timelineScroll.ScrollBarImageColor3 = COLORS.brass
timelineScroll.ScrollingDirection = Enum.ScrollingDirection.X
timelineScroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
timelineScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
timelineScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
timelineScroll.Parent = panel

local scrollLeftButton = Instance.new("TextButton")
scrollLeftButton.Name = "ScrollLeftButton"
scrollLeftButton.Size = UDim2.new(0, 28, 0, 72)
scrollLeftButton.Position = UDim2.new(0, 0, 0, 104)
scrollLeftButton.BackgroundColor3 = COLORS.brassDark
scrollLeftButton.BorderSizePixel = 0
scrollLeftButton.Text = "<"
scrollLeftButton.TextColor3 = COLORS.goldSoft
scrollLeftButton.Font = Enum.Font.GothamBold
scrollLeftButton.TextSize = 18
scrollLeftButton.Parent = panel

createCorner(scrollLeftButton, 8)

local scrollRightButton = Instance.new("TextButton")
scrollRightButton.Name = "ScrollRightButton"
scrollRightButton.Size = UDim2.new(0, 28, 0, 72)
scrollRightButton.Position = UDim2.new(1, -28, 0, 104)
scrollRightButton.BackgroundColor3 = COLORS.brassDark
scrollRightButton.BorderSizePixel = 0
scrollRightButton.Text = ">"
scrollRightButton.TextColor3 = COLORS.goldSoft
scrollRightButton.Font = Enum.Font.GothamBold
scrollRightButton.TextSize = 18
scrollRightButton.Parent = panel

createCorner(scrollRightButton, 8)

scrollLeftButton.MouseButton1Click:Connect(function()
	local newX = math.max(0, timelineScroll.CanvasPosition.X - 260)
	timelineScroll.CanvasPosition = Vector2.new(newX, 0)
end)

scrollRightButton.MouseButton1Click:Connect(function()
	local maxX = math.max(0, timelineScroll.AbsoluteCanvasSize.X - timelineScroll.AbsoluteWindowSize.X)
	local newX = math.min(maxX, timelineScroll.CanvasPosition.X + 260)
	timelineScroll.CanvasPosition = Vector2.new(newX, 0)
end)

	local timelineContent = Instance.new("Frame")
timelineContent.Name = "TimelineContent"
timelineContent.Size = UDim2.new(0, 860, 0, 124)
timelineContent.BackgroundTransparency = 1
timelineContent.Parent = timelineScroll

	local headerRow = Instance.new("Frame")
	headerRow.Name = "HeaderRow"
	headerRow.Size = UDim2.new(1, 0, 0, 20)
	headerRow.BackgroundTransparency = 1
	headerRow.Parent = timelineContent

	local headerLabelSpacer = Instance.new("Frame")
	headerLabelSpacer.Name = "ArmLabelSpacer"
	headerLabelSpacer.LayoutOrder = 0
	headerLabelSpacer.Size = UDim2.new(0, 90, 0, 20)
	headerLabelSpacer.BackgroundTransparency = 1
	headerLabelSpacer.Parent = headerRow

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.Padding = UDim.new(0, 8)
	headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerLayout.Parent = headerRow

	local rowsHolder = Instance.new("Frame")
	rowsHolder.Name = "Rows"
	rowsHolder.Size = UDim2.new(1, 0, 1, -24)
	rowsHolder.Position = UDim2.new(0, 0, 0, 24)
	rowsHolder.BackgroundTransparency = 1
	rowsHolder.Parent = timelineContent

	local rowsLayout = Instance.new("UIListLayout")
	rowsLayout.FillDirection = Enum.FillDirection.Vertical
	rowsLayout.Padding = UDim.new(0, 8)
	rowsLayout.Parent = rowsHolder

	local function refreshCanvas()
	local width = 90 + cycleCount * 72
	timelineContent.Size = UDim2.new(0, width, 0, 124)
	timelineScroll.CanvasSize = UDim2.new(0, width + 64, 0, 0)
end

	local function createTimelineRows()
		for _, child in ipairs(headerRow:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		for _, child in ipairs(rowsHolder:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for cycleIndex = 1, cycleCount do
			createCycleHeader(headerRow, cycleIndex)
		end

		for armIndex = 1, armCount do
			local row = Instance.new("Frame")
			row.Name = "Arm_" .. armIndex .. "_Row"
			row.Size = UDim2.new(1, 0, 0, 48)
			row.BackgroundTransparency = 1
			row.Parent = rowsHolder

			local rowLayout = Instance.new("UIListLayout")
			rowLayout.FillDirection = Enum.FillDirection.Horizontal
			rowLayout.Padding = UDim.new(0, 8)
			rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			rowLayout.Parent = row

			createArmRowLabel(row, armIndex)

			for cycleIndex = 1, cycleCount do
				local slot = createCycleSlot(row, cycleIndex)
				slotByArmAndCycle[armIndex][cycleIndex] = slot

				local savedInstruction = program[armIndex][cycleIndex]
				setSlotInstruction(slot, if savedInstruction then INSTRUCTION_BY_LABEL[savedInstruction] else nil)

				slot.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						program[armIndex][cycleIndex] = nil
						setSlotInstruction(slot, nil)
					end
				end)
			end
		end

		refreshCanvas()
	end

	local function beginDrag(instruction: InstructionDef)
		local mouseLocation = UserInputService:GetMouseLocation()

		local ghost = createInstructionVisual(screenGui, instruction, UDim2.new(0, 78, 0, 48))
		ghost.Name = "Dragging_" .. instruction.label
		ghost.Position = UDim2.new(0, mouseLocation.X - 39, 0, mouseLocation.Y - 24)
		ghost.ZIndex = 100

		for _, child in ipairs(ghost:GetDescendants()) do
			if child:IsA("GuiObject") then
				child.ZIndex = 101
			end
		end

		local moveConnection: RBXScriptConnection? = nil
		local endConnection: RBXScriptConnection? = nil

		moveConnection = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local pos = UserInputService:GetMouseLocation()
				ghost.Position = UDim2.new(0, pos.X - 39, 0, pos.Y - 24)
			end
		end)

		endConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local dropPosition = UserInputService:GetMouseLocation()

			local dropped = false

		for armIndex = 1, armCount do
			if dropped then
				break
			end

			for cycleIndex = 1, cycleCount do
				local slot = slotByArmAndCycle[armIndex][cycleIndex]

				if slot and pointInside(slot, dropPosition) then
					program[armIndex][cycleIndex] = instruction.label
					setSlotInstruction(slot, instruction)
					dropped = true
				break
			end
		end
	end

			if moveConnection then
				moveConnection:Disconnect()
			end

			if endConnection then
				endConnection:Disconnect()
			end

			ghost:Destroy()
		end)
	end

	for _, instruction in ipairs(INSTRUCTIONS) do
		local block = createInstructionVisual(commandRow, instruction, UDim2.new(0, 78, 0, 48))

		block.MouseButton1Down:Connect(function()
			beginDrag(instruction)
		end)
	end

	addCycleButton.MouseButton1Click:Connect(function()
		cycleCount += 1

		for armIndex = 1, armCount do
			program[armIndex][cycleCount] = nil
		end

		createTimelineRows()
	end)

	createTimelineRows()
end

local function createPiecePalette(parent: Instance)
	local panel = createPanel(parent, "PiecePalette", UDim2.new(0, 126, 0, 446), UDim2.new(0, 24, 0.5, -150))
	createPadding(panel, 12, 12, 12, 12)

	local title = Instance.new("TextLabel")
	title.Name = "PaletteTitle"
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.Text = "PIECES"
	title.TextColor3 = COLORS.goldSoft
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.Parent = panel

	local layoutHolder = Instance.new("Frame")
	layoutHolder.Name = "PieceButtons"
	layoutHolder.Size = UDim2.new(1, 0, 1, -34)
	layoutHolder.Position = UDim2.new(0, 0, 0, 34)
	layoutHolder.BackgroundTransparency = 1
	layoutHolder.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = layoutHolder

	for _, piece in ipairs(PIECES) do
		local button = Instance.new("TextButton")
		button.Name = piece.name .. "Button"
		button.Size = UDim2.new(0, 90, 0, 76)
		button.BackgroundColor3 = COLORS.woodDark
		button.BorderSizePixel = 0
		button.Text = ""
		button.Parent = layoutHolder

		createCorner(button, 8)
		createStroke(button, COLORS.brassDark, 1)

		local iconHolder = Instance.new("Frame")
		iconHolder.Name = "Icon"
		iconHolder.Size = UDim2.new(1, -18, 0, 42)
		iconHolder.Position = UDim2.new(0, 9, 0, 6)
		iconHolder.BackgroundTransparency = 1
		iconHolder.Parent = button

		PieceIcons.create(piece.name, iconHolder)

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 0, 18)
		label.Position = UDim2.new(0, 0, 1, -21)
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

function HUD.build(puzzle: PuzzleLike, onBack: (() -> ())?, onCenterCamera: (() -> ())?): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OpusFactoryHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	ResponsiveScaler.attach(screenGui)

	createTopInfo(screenGui, puzzle)
	createHintPanel(screenGui)
	createBackButton(screenGui, onBack)
	createControls(screenGui, onCenterCamera)
	createCycleTable(screenGui, screenGui)
	createPiecePalette(screenGui)

	return screenGui
end

return HUD