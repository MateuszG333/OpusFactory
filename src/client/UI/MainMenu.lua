--!strict
-- MainMenu.lua
-- Main game menu styled like an alchemical workshop: dark wood panels, brass frames, and gold accents.
-- This module only owns menu UI and reports player choices through callbacks.

local Players = game:GetService("Players")
local ResponsiveScaler = require(script.Parent.ResponsiveScaler)

local player = Players.LocalPlayer

local MainMenu = {}

export type MenuAction = "Tutorial" | "DailyChallenge" | "LevelSelect" | "GlobalLeaderboard"

export type MainMenuCallbacks = {
	onTutorial: (() -> ())?,
	onDailyChallenge: (() -> ())?,
	onLevelSelect: (() -> ())?,
	onGlobalLeaderboard: (() -> ())?,
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
	redWax = Color3.fromRGB(145, 56, 46),
	greenGlass = Color3.fromRGB(88, 145, 105),
	blueSteel = Color3.fromRGB(92, 133, 160),
}

local MENU_ITEMS: {
	{
		action: MenuAction,
		title: string,
		subtitle: string,
		info: string,
		icon: string,
		accentColor: Color3,
	}
} = {
	{
		action = "Tutorial",
		title = "Tutorial",
		subtitle = "Learn the machine.",
		info = "Learn the basics of arms, instructions, bonding, inputs, outputs, and the hex board.",
		icon = "?",
		accentColor = COLORS.greenGlass,
	},
	{
		action = "DailyChallenge",
		title = "Daily Challenge",
		subtitle = "One puzzle each day.",
		info = "A shared puzzle of the day. Everyone solves the same board under the same constraints.",
		icon = "!",
		accentColor = COLORS.gold,
	},
	{
		action = "LevelSelect",
		title = "Level Select",
		subtitle = "Begin the campaign.",
		info = "Choose campaign puzzles, view difficulty, unlock progress, and earned stars.",
		icon = "#",
		accentColor = COLORS.blueSteel,
	},
	{
		action = "GlobalLeaderboard",
		title = "Global Leaderboard",
		subtitle = "Compare solutions.",
		info = "Compare the best solutions by cycles, cost, and occupied area.",
		icon = "★",
		accentColor = COLORS.redWax,
	},
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

local function createWoodPanel(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = COLORS.woodDark
	panel.BorderSizePixel = 0
	panel.Parent = parent

	createCorner(panel, 16)
	createStroke(panel, COLORS.brassDark, 2)

	local inner = Instance.new("Frame")
	inner.Name = "InnerWood"
	inner.Size = UDim2.new(1, -14, 1, -14)
	inner.Position = UDim2.new(0, 7, 0, 7)
	inner.BackgroundColor3 = COLORS.wood
	inner.BorderSizePixel = 0
	inner.Parent = panel

	createCorner(inner, 12)
	createStroke(inner, COLORS.brass, 1)

	return inner
end

local function createTitle(parent: Instance)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 62)
	title.BackgroundTransparency = 1
	title.Text = "OPUS FACTORY"
	title.TextColor3 = COLORS.goldSoft
	title.Font = Enum.Font.Garamond
	title.TextSize = 48
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = parent

	local underline = Instance.new("Frame")
	underline.Name = "TitleUnderline"
	underline.Size = UDim2.new(0, 430, 0, 3)
	underline.Position = UDim2.new(0, 0, 0, 66)
	underline.BackgroundColor3 = COLORS.brass
	underline.BorderSizePixel = 0
	underline.Parent = parent

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 28)
	subtitle.Position = UDim2.new(0, 0, 0, 76)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Build elegant machines and solve alchemical factory puzzles."
	subtitle.TextColor3 = COLORS.textDim
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 16
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = parent
end

local function createHoverInfoPanel(parent: Instance): (Frame, TextLabel, TextLabel)
	local outer = Instance.new("Frame")
	outer.Name = "HoverInfoPanel"
	outer.Size = UDim2.new(0, 340, 0, 178)
	outer.Position = UDim2.new(1, -340, 0, 154)
	outer.BackgroundColor3 = COLORS.woodDark
	outer.BorderSizePixel = 0
	outer.Visible = false
	outer.Parent = parent

	createCorner(outer, 14)
	createStroke(outer, COLORS.brass, 2)

	local panel = Instance.new("Frame")
	panel.Name = "Inner"
	panel.Size = UDim2.new(1, -12, 1, -12)
	panel.Position = UDim2.new(0, 6, 0, 6)
	panel.BackgroundColor3 = COLORS.wood
	panel.BorderSizePixel = 0
	panel.Parent = outer

	createCorner(panel, 10)
	createPadding(panel, 16, 16, 16, 16)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Text = ""
	header.TextColor3 = COLORS.goldSoft
	header.Font = Enum.Font.Garamond
	header.TextSize = 25
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = panel

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, 0, 1, -42)
	body.Position = UDim2.new(0, 0, 0, 42)
	body.BackgroundTransparency = 1
	body.Text = ""
	body.TextColor3 = COLORS.textDim
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = panel

	return outer, header, body
end

local function runAction(action: MenuAction, callbacks: MainMenuCallbacks?)
	if not callbacks then
		return
	end

	if action == "Tutorial" and callbacks.onTutorial then
		callbacks.onTutorial()
	elseif action == "DailyChallenge" and callbacks.onDailyChallenge then
		callbacks.onDailyChallenge()
	elseif action == "LevelSelect" and callbacks.onLevelSelect then
		callbacks.onLevelSelect()
	elseif action == "GlobalLeaderboard" and callbacks.onGlobalLeaderboard then
		callbacks.onGlobalLeaderboard()
	end
end

local function createMenuButton(
	parent: Instance,
	item: {
		action: MenuAction,
		title: string,
		subtitle: string,
		info: string,
		icon: string,
		accentColor: Color3,
	},
	hoverPanel: Frame,
	hoverHeader: TextLabel,
	hoverBody: TextLabel,
	callbacks: MainMenuCallbacks?
)
	local button = Instance.new("TextButton")
	button.Name = item.action .. "Button"
	button.Size = UDim2.new(1, 0, 0, 88)
	button.BackgroundColor3 = COLORS.woodDark
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ""
	button.Parent = parent

	createCorner(button, 12)
	createStroke(button, COLORS.brassDark, 2)

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.new(1, -10, 1, -10)
	inner.Position = UDim2.new(0, 5, 0, 5)
	inner.BackgroundColor3 = COLORS.wood
	inner.BorderSizePixel = 0
	inner.Parent = button

	createCorner(inner, 9)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 6, 1, -16)
	accent.Position = UDim2.new(0, 12, 0, 8)
	accent.BackgroundColor3 = item.accentColor
	accent.BorderSizePixel = 0
	accent.Parent = inner

	createCorner(accent, 999)

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 42, 0, 42)
	icon.Position = UDim2.new(0, 30, 0.5, -21)
	icon.BackgroundColor3 = COLORS.ink
	icon.BorderSizePixel = 0
	icon.Text = item.icon
	icon.TextColor3 = COLORS.goldSoft
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 21
	icon.Parent = inner

	createCorner(icon, 10)
	createStroke(icon, item.accentColor, 1)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 0, 30)
	title.Position = UDim2.new(0, 86, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = item.title
	title.TextColor3 = COLORS.text
	title.Font = Enum.Font.Garamond
	title.TextSize = 25
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = inner

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -100, 0, 28)
	subtitle.Position = UDim2.new(0, 86, 0, 48)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = item.subtitle
	subtitle.TextColor3 = COLORS.textDim
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 13
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextYAlignment = Enum.TextYAlignment.Top
	subtitle.Parent = inner

	button.MouseEnter:Connect(function()
		inner.BackgroundColor3 = COLORS.woodLight
		hoverHeader.Text = item.title
		hoverBody.Text = item.info
		hoverPanel.Visible = true
	end)

	button.MouseLeave:Connect(function()
		inner.BackgroundColor3 = COLORS.wood
		hoverPanel.Visible = false
	end)

	button.MouseButton1Click:Connect(function()
		runAction(item.action, callbacks)
	end)
end

local function createPlaceholderOverlay(screenGui: ScreenGui, titleText: string, bodyText: string)
	local overlay = Instance.new("Frame")
	overlay.Name = "PlaceholderOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.32
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	local panel = createWoodPanel(overlay, "Panel", UDim2.new(0, 460, 0, 245), UDim2.new(0.5, -230, 0.5, -122))
	createPadding(panel, 20, 20, 20, 20)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 38)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = COLORS.goldSoft
	title.Font = Enum.Font.Garamond
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, 0, 0, 86)
	body.Position = UDim2.new(0, 0, 0, 54)
	body.BackgroundTransparency = 1
	body.Text = bodyText
	body.TextColor3 = COLORS.textDim
	body.Font = Enum.Font.Gotham
	body.TextSize = 15
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = panel

	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0, 132, 0, 40)
	backButton.Position = UDim2.new(1, -132, 1, -40)
	backButton.BackgroundColor3 = COLORS.brass
	backButton.BorderSizePixel = 0
	backButton.Text = "Back"
	backButton.TextColor3 = COLORS.ink
	backButton.Font = Enum.Font.GothamBold
	backButton.TextSize = 15
	backButton.Parent = panel

	createCorner(backButton, 8)
	createStroke(backButton, COLORS.goldSoft, 1)

	backButton.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)
end

function MainMenu.build(callbacks: MainMenuCallbacks?): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainMenuScreen"
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

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(0, 920, 0, 520)
	content.Position = UDim2.new(0.5, -460, 0.5, -260)
	content.BackgroundTransparency = 1
	content.Parent = backdrop

	createTitle(content)

	local menuOuter = Instance.new("Frame")
	menuOuter.Name = "MenuFrame"
	menuOuter.Size = UDim2.new(0, 540, 0, 398)
	menuOuter.Position = UDim2.new(0, 0, 0, 122)
	menuOuter.BackgroundColor3 = COLORS.woodDark
	menuOuter.BorderSizePixel = 0
	menuOuter.Parent = content

	createCorner(menuOuter, 16)
	createStroke(menuOuter, COLORS.brass, 2)
	createPadding(menuOuter, 12, 12, 12, 12)

	local menuLayout = Instance.new("UIListLayout")
	menuLayout.FillDirection = Enum.FillDirection.Vertical
	menuLayout.Padding = UDim.new(0, 12)
	menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
	menuLayout.Parent = menuOuter

	local hoverPanel, hoverHeader, hoverBody = createHoverInfoPanel(content)

	for _, item in ipairs(MENU_ITEMS) do
		createMenuButton(menuOuter, item, hoverPanel, hoverHeader, hoverBody, callbacks)
	end

	return screenGui
end

function MainMenu.showPlaceholder(screenGui: ScreenGui, titleText: string, bodyText: string)
	createPlaceholderOverlay(screenGui, titleText, bodyText)
end

return MainMenu