--!strict
-- HUD.lua
-- Statyczny szkielet UI: pasek instrukcji na dole, panel elementów po lewej, panel info po prawej.
-- Na razie BEZ logiki - tylko layout, żeby ustalić wygląd zanim podłączymy dane.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local HUD = {}

local PieceIcons = require(script.Parent.PieceIcons)
-- Spokojna, stonowana paleta (zgodnie z ustaleniami - bez neonów w finalnym UI)
local COLORS = {
	background = Color3.fromRGB(38, 40, 46),
	panel = Color3.fromRGB(50, 53, 61),
	panelBorder = Color3.fromRGB(70, 74, 84),
	accent = Color3.fromRGB(150, 170, 190),
	text = Color3.fromRGB(220, 222, 228),
	textDim = Color3.fromRGB(150, 153, 160),
}

local function applyPanelStyle(frame: Frame)
	frame.BackgroundColor3 = COLORS.panel
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.panelBorder
	stroke.Thickness = 1
	stroke.Parent = frame
end

function HUD.build(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OpusMagnumHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- === PASEK DOLNY: kontrolki symulacji + oś czasu instrukcji ===
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, -32, 0, 140)
	bottomBar.Position = UDim2.new(0, 16, 1, -156)
	applyPanelStyle(bottomBar)
	bottomBar.Parent = screenGui

	-- Rząd przycisków kontrolnych (Play/Pause/Step/Reset) - placeholder
	local controlsRow = Instance.new("Frame")
	controlsRow.Name = "Controls"
	controlsRow.Size = UDim2.new(1, -24, 0, 44)
	controlsRow.Position = UDim2.new(0, 12, 0, 8)
	controlsRow.BackgroundTransparency = 1
	controlsRow.Parent = bottomBar

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.Padding = UDim.new(0, 8)
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.Parent = controlsRow

	local buttonLabels = { "▶ Run", "⏸ Pause", "⏭ Step", "⟲ Reset" }
	for _, label in ipairs(buttonLabels) do
		local btn = Instance.new("TextButton")
		btn.Name = label
		btn.Size = UDim2.new(0, 90, 1, 0)
		btn.BackgroundColor3 = COLORS.accent
		btn.Text = label
		btn.TextColor3 = COLORS.background
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 16

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		btn.Parent = controlsRow
	end

	-- Licznik cykli (obok przycisków)
	local cycleLabel = Instance.new("TextLabel")
	cycleLabel.Name = "CycleCounter"
	cycleLabel.Size = UDim2.new(0, 140, 1, 0)
	cycleLabel.BackgroundTransparency = 1
	cycleLabel.Text = "Cykl: 0"
	cycleLabel.TextColor3 = COLORS.text
	cycleLabel.Font = Enum.Font.GothamMedium
	cycleLabel.TextSize = 16
	cycleLabel.Parent = controlsRow

	-- Obszar osi czasu instrukcji (pod rzędem przycisków) - placeholder na przyszłość
	local timeline = Instance.new("Frame")
	timeline.Name = "Timeline"
	timeline.Size = UDim2.new(1, -24, 0, 68)
	timeline.Position = UDim2.new(0, 12, 0, 60)
	timeline.BackgroundColor3 = COLORS.background
	timeline.BorderSizePixel = 0

	local timelineCorner = Instance.new("UICorner")
	timelineCorner.CornerRadius = UDim.new(0, 6)
	timelineCorner.Parent = timeline

	timeline.Parent = bottomBar

	local timelinePlaceholder = Instance.new("TextLabel")
	timelinePlaceholder.Size = UDim2.new(1, 0, 1, 0)
	timelinePlaceholder.BackgroundTransparency = 1
	timelinePlaceholder.Text = "(oś czasu instrukcji - do zrobienia)"
	timelinePlaceholder.TextColor3 = COLORS.textDim
	timelinePlaceholder.Font = Enum.Font.Gotham
	timelinePlaceholder.TextSize = 14
	timelinePlaceholder.Parent = timeline

	-- === PANEL LEWY: paleta elementów (Arm, Track, Bonder, Glyph...) ===
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "PiecePalette"
	leftPanel.Size = UDim2.new(0, 90, 0, 420)
	leftPanel.Position = UDim2.new(0, 16, 0.5, -210)
	applyPanelStyle(leftPanel)
	leftPanel.Parent = screenGui

	local paletteLayout = Instance.new("UIListLayout")
	paletteLayout.Padding = UDim.new(0, 8)
	paletteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	paletteLayout.Parent = leftPanel

	local paletteHeader = Instance.new("TextLabel")
	paletteHeader.Size = UDim2.new(1, -16, 0, 24)
	paletteHeader.BackgroundTransparency = 1
	paletteHeader.Text = "ELEMENTY"
	paletteHeader.TextColor3 = COLORS.textDim
	paletteHeader.Font = Enum.Font.GothamBold
	paletteHeader.TextSize = 12
	paletteHeader.LayoutOrder = 0
	paletteHeader.Parent = leftPanel

	

	local pieceTypes = { "Arm", "Track", "Bonder", "Glyph" }
	for i, pieceName in ipairs(pieceTypes) do
	local slot = Instance.new("TextButton")
	slot.Name = "Slot_" .. pieceName
	slot.Size = UDim2.new(0, 70, 0, 70)
	slot.BackgroundColor3 = COLORS.background
	slot.Text = ""
	slot.LayoutOrder = i

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slot

	local iconArea = Instance.new("Frame")
	iconArea.Size = UDim2.new(1, -16, 1, -24)
	iconArea.Position = UDim2.new(0, 8, 0, 4)
	iconArea.BackgroundTransparency = 1
	iconArea.Parent = slot

	PieceIcons.create(pieceName, iconArea)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 16)
	label.Position = UDim2.new(0, 0, 1, -18)
	label.BackgroundTransparency = 1
	label.Text = pieceName
	label.TextColor3 = COLORS.textDim
	label.Font = Enum.Font.Gotham
	label.TextSize = 10
	label.Parent = slot

	slot.Parent = leftPanel
end

	-- === PANEL PRAWY: info o poziomie (cel, postęp, gwiazdki) ===
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "LevelInfo"
	rightPanel.Size = UDim2.new(0, 220, 0, 200)
	rightPanel.Position = UDim2.new(1, -236, 0, 16)
	applyPanelStyle(rightPanel)
	rightPanel.Parent = screenGui

	local infoLayout = Instance.new("UIListLayout")
	infoLayout.Padding = UDim.new(0, 6)
	infoLayout.Parent = rightPanel

	local infoPadding = Instance.new("UIPadding")
	infoPadding.PaddingTop = UDim.new(0, 12)
	infoPadding.PaddingLeft = UDim.new(0, 12)
	infoPadding.PaddingRight = UDim.new(0, 12)
	infoPadding.Parent = rightPanel

	local levelTitle = Instance.new("TextLabel")
	levelTitle.Size = UDim2.new(1, 0, 0, 24)
	levelTitle.BackgroundTransparency = 1
	levelTitle.Text = "Poziom 1: Nazwa"
	levelTitle.TextColor3 = COLORS.text
	levelTitle.Font = Enum.Font.GothamBold
	levelTitle.TextSize = 18
	levelTitle.TextXAlignment = Enum.TextXAlignment.Left
	levelTitle.LayoutOrder = 1
	levelTitle.Parent = rightPanel

	local starsLabel = Instance.new("TextLabel")
	starsLabel.Size = UDim2.new(1, 0, 0, 24)
	starsLabel.BackgroundTransparency = 1
	starsLabel.Text = "☆ ☆ ☆"
	starsLabel.TextColor3 = COLORS.accent
	starsLabel.Font = Enum.Font.GothamMedium
	starsLabel.TextSize = 18
	starsLabel.TextXAlignment = Enum.TextXAlignment.Left
	starsLabel.LayoutOrder = 2
	starsLabel.Parent = rightPanel

	return screenGui
end

return HUD