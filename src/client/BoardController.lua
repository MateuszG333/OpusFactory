--!strict
-- BoardController.lua
-- Client-side board renderer for the selected puzzle.
-- Renders wooden board base, hex tiles, input markers, and output markers.
-- It does not run simulation logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HexCoord = require(ReplicatedStorage.Shared.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local HexGrid = require(ReplicatedStorage.Shared.Hex.HexGrid)

local PuzzleDefinitions = require(ReplicatedStorage.Shared.Puzzles.PuzzleDefinitions)
type PuzzleDefinition = PuzzleDefinitions.PuzzleDefinition
type MoleculePattern = PuzzleDefinitions.MoleculePattern
type AtomPattern = PuzzleDefinitions.AtomPattern

local BoardController = {}

local BOARD_FOLDER_NAME = "OpusFactoryBoard"

local HEX_SIZE = 4
local HEX_HEIGHT = 0.35

-- Visual board is intentionally larger than the puzzle logic radius.
-- This gives the player enough building space while we are still prototyping placement.
local MIN_VISUAL_RADIUS = 30
local VISUAL_BOARD_MARGIN = 8

local COLORS = {
	woodBase = Color3.fromRGB(50, 32, 20),
	woodBaseLight = Color3.fromRGB(76, 50, 30),
	brass = Color3.fromRGB(178, 132, 58),
	hexDark = Color3.fromRGB(52, 39, 27),
	hexLight = Color3.fromRGB(72, 52, 34),
	hexBorder = Color3.fromRGB(158, 113, 50),
	input = Color3.fromRGB(88, 145, 105),
	output = Color3.fromRGB(178, 132, 58),
	text = Color3.fromRGB(238, 226, 202),

	salt = Color3.fromRGB(230, 230, 220),
	water = Color3.fromRGB(80, 150, 220),
	fire = Color3.fromRGB(220, 90, 65),
	earth = Color3.fromRGB(130, 92, 55),
	air = Color3.fromRGB(205, 220, 230),
	quicksilver = Color3.fromRGB(180, 180, 190),
	goldAtom = Color3.fromRGB(235, 190, 70),
	silver = Color3.fromRGB(190, 195, 205),
	copper = Color3.fromRGB(190, 110, 70),
	iron = Color3.fromRGB(120, 125, 130),
	tin = Color3.fromRGB(160, 165, 170),
	lead = Color3.fromRGB(95, 100, 112),
	vitae = Color3.fromRGB(130, 210, 145),
	mors = Color3.fromRGB(160, 80, 160),
}

local function getOrCreateBoardFolder(): Folder
	local existing = Workspace:FindFirstChild(BOARD_FOLDER_NAME)

	if existing and existing:IsA("Folder") then
		existing:ClearAllChildren()
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = BOARD_FOLDER_NAME
	folder.Parent = Workspace

	return folder
end

local function clearBoardFolder()
	local existing = Workspace:FindFirstChild(BOARD_FOLDER_NAME)

	if existing then
		existing:Destroy()
	end
end

local function createWoodBase(radius: number, parent: Instance)
	local size = radius * HEX_SIZE * 3.6 + 18

	local base = Instance.new("Part")
	base.Name = "WoodenBoardBase"
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Wood
	base.Color = COLORS.woodBase
	base.Size = Vector3.new(size, 0.45, size)
	base.Position = Vector3.new(0, -0.35, 0)
	base.Parent = parent

	local baseStroke = Instance.new("SelectionBox")
	baseStroke.Name = "BrassOuterFrame"
	baseStroke.Adornee = base
	baseStroke.LineThickness = 0.04
	baseStroke.Color3 = COLORS.brass
	baseStroke.SurfaceTransparency = 1
	baseStroke.Parent = base

	local inner = Instance.new("Part")
	inner.Name = "WoodenBoardInset"
	inner.Anchored = true
	inner.CanCollide = false
	inner.Material = Enum.Material.WoodPlanks
	inner.Color = COLORS.woodBaseLight
	inner.Size = Vector3.new(size - 5, 0.12, size - 5)
	inner.Position = Vector3.new(0, -0.05, 0)
	inner.Parent = parent

	local innerStroke = Instance.new("SelectionBox")
	innerStroke.Name = "BrassInnerFrame"
	innerStroke.Adornee = inner
	innerStroke.LineThickness = 0.025
	innerStroke.Color3 = COLORS.brass
	innerStroke.SurfaceTransparency = 1
	innerStroke.Parent = inner
end

local function createHexTile(coord: HexCoord, parent: Instance, index: number): Part
	local part = Instance.new("Part")
	part.Name = "Hex_" .. coord:toKey()
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.SmoothPlastic
	part.Color = if index % 2 == 0 then COLORS.hexDark else COLORS.hexLight
	part.Size = Vector3.new(HEX_HEIGHT, HEX_SIZE * 1.62, HEX_SIZE * 1.62)

	local worldPos = coord:toWorldPosition(HEX_SIZE)
	part.CFrame = CFrame.new(worldPos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = parent

	local selection = Instance.new("SelectionBox")
	selection.Name = "BrassEdge"
	selection.Adornee = part
	selection.LineThickness = 0.025
	selection.Color3 = COLORS.hexBorder
	selection.SurfaceTransparency = 1
	selection.Parent = part

	return part
end

local function getAtomColor(element: string): Color3
	if element == "Salt" then
		return COLORS.salt
	elseif element == "Water" then
		return COLORS.water
	elseif element == "Fire" then
		return COLORS.fire
	elseif element == "Earth" then
		return COLORS.earth
	elseif element == "Air" then
		return COLORS.air
	elseif element == "Quicksilver" then
		return COLORS.quicksilver
	elseif element == "Gold" then
		return COLORS.goldAtom
	elseif element == "Silver" then
		return COLORS.silver
	elseif element == "Copper" then
		return COLORS.copper
	elseif element == "Iron" then
		return COLORS.iron
	elseif element == "Tin" then
		return COLORS.tin
	elseif element == "Lead" then
		return COLORS.lead
	elseif element == "Vitae" then
		return COLORS.vitae
	elseif element == "Mors" then
		return COLORS.mors
	end

	return COLORS.text
end

local function createBillboard(parent: BasePart, labelText: string, color: Color3)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 120, 0, 36)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(30, 24, 18)
	label.BorderSizePixel = 0
	label.Text = labelText
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function createMarker(
	coord: HexCoord,
	parent: Instance,
	name: string,
	color: Color3,
	labelText: string
): Part
	local marker = Instance.new("Part")
	marker.Name = name
	marker.Anchored = true
	marker.CanCollide = false
	marker.Shape = Enum.PartType.Cylinder
	marker.Material = Enum.Material.Neon
	marker.Color = color
	marker.Size = Vector3.new(0.25, HEX_SIZE * 1.25, HEX_SIZE * 1.25)

	local worldPos = coord:toWorldPosition(HEX_SIZE)
	marker.CFrame = CFrame.new(worldPos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90))
	marker.Parent = parent

	createBillboard(marker, labelText, color)

	return marker
end

local function createAtomPreview(atom: AtomPattern, parent: Instance, labelPrefix: string)
	local coord = HexCoord.new(atom.position.x, atom.position.y, atom.position.z)

	local atomPart = Instance.new("Part")
	atomPart.Name = labelPrefix .. "_" .. atom.element
	atomPart.Anchored = true
	atomPart.CanCollide = false
	atomPart.Shape = Enum.PartType.Ball
	atomPart.Material = Enum.Material.Neon
	atomPart.Color = getAtomColor(atom.element)
	atomPart.Size = Vector3.new(1.35, 1.35, 1.35)

	local worldPos = coord:toWorldPosition(HEX_SIZE)
	atomPart.CFrame = CFrame.new(worldPos + Vector3.new(0, 1.25, 0))
	atomPart.Parent = parent

	createBillboard(atomPart, labelPrefix .. ": " .. atom.element, COLORS.text)
end

local function renderMoleculeMarkers(
	molecules: { MoleculePattern },
	parent: Instance,
	markerName: string,
	markerColor: Color3,
	labelPrefix: string
)
	for moleculeIndex, molecule in ipairs(molecules) do
		for atomIndex, atom in ipairs(molecule.atoms) do
			local coord = HexCoord.new(atom.position.x, atom.position.y, atom.position.z)
			local markerLabel = string.format("%s %d.%d", labelPrefix, moleculeIndex, atomIndex)

			createMarker(coord, parent, markerName .. "_" .. moleculeIndex .. "_" .. atomIndex, markerColor, markerLabel)
			createAtomPreview(atom, parent, labelPrefix)
		end
	end
end

local function renderHexBoard(radius: number, parent: Instance)
	local center = HexCoord.new(0, 0, 0)
	local hexes = HexGrid.hexesInRadius(center, radius)

	for index, coord in ipairs(hexes) do
		createHexTile(coord, parent, index)
	end
end

function BoardController.loadPuzzle(puzzle: PuzzleDefinition)
	local folder = getOrCreateBoardFolder()

	local base = Instance.new("Folder")
	base.Name = "WoodenBase"
	base.Parent = folder

	local boardTiles = Instance.new("Folder")
	boardTiles.Name = "HexTiles"
	boardTiles.Parent = folder

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = folder

	local visualRadius = math.max(MIN_VISUAL_RADIUS, puzzle.gridRadius + VISUAL_BOARD_MARGIN)

    createWoodBase(visualRadius, base)
    renderHexBoard(visualRadius, boardTiles)
    renderMoleculeMarkers(puzzle.inputs, markers, "InputMarker", COLORS.input, "INPUT")
    renderMoleculeMarkers(puzzle.outputs, markers, "OutputMarker", COLORS.output, "OUTPUT")
end

function BoardController.clear()
	clearBoardFolder()
end

return BoardController