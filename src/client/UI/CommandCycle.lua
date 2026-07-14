--!strict
-- CommandCycle.lua
-- Instruction sequencer panel: pick an instruction, then click a slot to place it.
-- Click-to-select + click-to-place instead of drag&drop - much easier to target,
-- especially with UIScale from ResponsiveScaler affecting on-screen pixel sizes.

local COLORS = {
	woodDark = Color3.fromRGB(45, 30, 20),
	wood = Color3.fromRGB(72, 47, 30),
	woodLight = Color3.fromRGB(94, 64, 39),
	brassDark = Color3.fromRGB(116, 82, 35),
	brass = Color3.fromRGB(178, 132, 58),
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
	selectedGlow = Color3.fromRGB(255, 235, 180),
}

export type InstructionDef = {
	label: string,
	short: string,
	color: Color3,
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

local CommandCycle = {}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function createStroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = parent
	return stroke
end

local function createPadding(parent: Instance, top: number, bottom: number, left: number, right: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingBottom = UDim.new(0, bottom)
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right)
	padding.Parent = parent
end

-- Builds the panel. Returns a controller: addArm(), getProgram(), getArmCount().
function CommandCycle.build(parent: Instance): any
	local MARGIN = 16
	local GAP = 12
	local PARTS_WIDTH = 240
	local COMMAND_HEIGHT = 230

	local panel = Instance.new("Frame")
	panel.Name = "CommandCyclePanel"
	panel.Size = UDim2.new(1, -(MARGIN + PARTS_WIDTH + GAP + MARGIN), 0, COMMAND_HEIGHT)
	panel.Position = UDim2.new(0, MARGIN + PARTS_WIDTH + GAP, 1, -(COMMAND_HEIGHT + MARGIN))
	panel.BackgroundColor3 = COLORS.woodDark
	panel.BorderSizePixel = 0
	panel.Parent = parent

	createCorner(panel, 8)
	createStroke(panel, COLORS.brassDark, 1)

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.new(1, -12, 1, -12)
	inner.Position = UDim2.new(0, 6, 0, 6)
	inner.BackgroundColor3 = COLORS.wood
	inner.BorderSizePixel = 0
	inner.Parent = panel

	createCorner(inner, 6)
	createPadding(inner, 8, 8, 12, 12)

	-- === Selection state ===
	local selectedInstruction: InstructionDef? = nil
	local instructionButtons: { [string]: TextButton } = {}
	local instructionStrokes: { [string]: UIStroke } = {}

	local function clearSelectionVisuals()
		for label, stroke in pairs(instructionStrokes) do
			stroke.Color = COLORS.goldSoft
			stroke.Thickness = 1
		end
	end

	local function selectInstruction(instruction: InstructionDef?)
		selectedInstruction = instruction
		clearSelectionVisuals()
		if instruction then
			local stroke = instructionStrokes[instruction.label]
			if stroke then
				stroke.Color = COLORS.selectedGlow
				stroke.Thickness = 3
			end
		end
	end

	-- === Top row: source instructions to pick from ===
	local commandRow = Instance.new("Frame")
	commandRow.Name = "CommandSourceRow"
	commandRow.Size = UDim2.new(1, 0, 0, 44)
	commandRow.Position = UDim2.new(0, 0, 0, 0)
	commandRow.BackgroundTransparency = 1
	commandRow.Parent = inner

	local commandLayout = Instance.new("UIListLayout")
	commandLayout.FillDirection = Enum.FillDirection.Horizontal
	commandLayout.Padding = UDim.new(0, 8)
	commandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	commandLayout.Parent = commandRow

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "SelectionHint"
	hintLabel.Size = UDim2.new(0, 260, 1, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Pick a command, then click a slot below"
	hintLabel.TextColor3 = COLORS.textDim
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextSize = 12
	hintLabel.TextXAlignment = Enum.TextXAlignment.Left
	hintLabel.LayoutOrder = 100
	hintLabel.Parent = commandRow

	for i, instruction in ipairs(INSTRUCTIONS) do
		local block = Instance.new("TextButton")
		block.Name = instruction.label .. "Source"
		block.LayoutOrder = i
		block.Size = UDim2.new(0, 56, 0, 40)
		block.BackgroundColor3 = instruction.color
		block.BorderSizePixel = 0
		block.Text = instruction.short
		block.TextColor3 = COLORS.ink
		block.Font = Enum.Font.GothamBold
		block.TextSize = 15
		block.Parent = commandRow

		createCorner(block, 8)
		local stroke = createStroke(block, COLORS.goldSoft, 1)
		instructionButtons[instruction.label] = block
		instructionStrokes[instruction.label] = stroke

		local fullLabel = Instance.new("TextLabel")
		fullLabel.Size = UDim2.new(1, 0, 0, 14)
		fullLabel.Position = UDim2.new(0, 0, 1, 2)
		fullLabel.BackgroundTransparency = 1
		fullLabel.Text = instruction.label
		fullLabel.TextColor3 = COLORS.textDim
		fullLabel.Font = Enum.Font.Gotham
		fullLabel.TextSize = 9
		fullLabel.Parent = block

		block.MouseButton1Click:Connect(function()
			if selectedInstruction and selectedInstruction.label == instruction.label then
				selectInstruction(nil) -- click again to deselect
			else
				selectInstruction(instruction)
			end
		end)
	end

	-- === Scrollable grid: arm rows x cycle columns ===
	local scrollArea = Instance.new("ScrollingFrame")
	scrollArea.Name = "ScrollArea"
	scrollArea.Size = UDim2.new(1, 0, 1, -52)
	scrollArea.Position = UDim2.new(0, 0, 0, 52)
	scrollArea.BackgroundTransparency = 1
	scrollArea.BorderSizePixel = 0
	scrollArea.ScrollBarThickness = 8
	scrollArea.ScrollBarImageColor3 = COLORS.brass
	scrollArea.ScrollingDirection = Enum.ScrollingDirection.XY
	scrollArea.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollArea.AutomaticCanvasSize = Enum.AutomaticSize.None
	scrollArea.Parent = inner

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(0, 0, 0, 0)
	content.BackgroundTransparency = 1
	content.Parent = scrollArea

	local ROW_HEIGHT = 44
	local SLOT_WIDTH = 54
	local LABEL_WIDTH = 70
	local ROW_SPACING = 6
	local SLOT_SPACING = 6

	local armCount = 0
	local cycleCount = 10
	local program: { [number]: { [number]: string? } } = {}
	local slotFrames: { [number]: { [number]: Frame } } = {}
	local rowFrames: { [number]: Frame } = {}

	local function refreshCanvas()
		local width = LABEL_WIDTH + cycleCount * (SLOT_WIDTH + SLOT_SPACING) + 20
		local height = math.max(armCount * (ROW_HEIGHT + ROW_SPACING), ROW_HEIGHT)
		content.Size = UDim2.new(0, width, 0, height)
		scrollArea.CanvasSize = UDim2.new(0, width, 0, height)
	end

	local function fillSlotVisual(slot: Frame, instruction: InstructionDef?)
		local existing = slot:FindFirstChild("Content")
		if existing then
			existing:Destroy()
		end

		if not instruction then
			slot.BackgroundColor3 = COLORS.slotEmpty
			return
		end

		slot.BackgroundColor3 = instruction.color

		local label = Instance.new("TextLabel")
		label.Name = "Content"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = instruction.short
		label.TextColor3 = COLORS.ink
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Parent = slot
	end

	local function createSlot(armIndex: number, cycleIndex: number, parentRow: Frame): Frame
		local slot = Instance.new("TextButton")
		slot.Name = "Slot_" .. cycleIndex
		slot.Size = UDim2.new(0, SLOT_WIDTH, 0, ROW_HEIGHT - 6)
		slot.Position = UDim2.new(
			0,
			LABEL_WIDTH + (cycleIndex - 1) * (SLOT_WIDTH + SLOT_SPACING),
			0,
			3
		)
		slot.BackgroundColor3 = COLORS.slotEmpty
		slot.BorderSizePixel = 0
		slot.Text = ""
		slot.AutoButtonColor = false
		slot.Parent = parentRow

		createCorner(slot, 6)
		createStroke(slot, COLORS.brassDark, 1)

		slot.MouseButton1Click:Connect(function()
			if selectedInstruction then
				program[armIndex][cycleIndex] = selectedInstruction.label
				fillSlotVisual(slot, selectedInstruction)
			end
		end)

		slot.MouseButton2Click:Connect(function()
			program[armIndex][cycleIndex] = nil
			fillSlotVisual(slot, nil)
		end)

		return slot
	end

	local function createRow(armIndex: number)
		local row = Instance.new("Frame")
		row.Name = "ArmRow_" .. armIndex
		row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
		row.Position = UDim2.new(0, 0, 0, (armIndex - 1) * (ROW_HEIGHT + ROW_SPACING))
		row.BackgroundTransparency = 1
		row.Parent = content

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(0, LABEL_WIDTH - 8, 0, ROW_HEIGHT - 6)
		label.Position = UDim2.new(0, 0, 0, 3)
		label.BackgroundColor3 = COLORS.rowLabel
		label.BorderSizePixel = 0
		label.Text = "Arm " .. armIndex
		label.TextColor3 = COLORS.goldSoft
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.Parent = row

		createCorner(label, 6)
		createStroke(label, COLORS.brassDark, 1)

		local slots: { [number]: Frame } = {}
		for cycleIndex = 1, cycleCount do
			slots[cycleIndex] = createSlot(armIndex, cycleIndex, row)
		end

		rowFrames[armIndex] = row
		slotFrames[armIndex] = slots
	end

	local controller = {}

	function controller.addArm(): number
		armCount += 1
		program[armCount] = {}
		createRow(armCount)
		refreshCanvas()
		return armCount
	end

	function controller.getProgram(): { [number]: { [number]: string? } }
		return program
	end

	function controller.getArmCount(): number
		return armCount
	end

	refreshCanvas()

	return controller
end

return CommandCycle