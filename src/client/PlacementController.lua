--!strict
-- PlacementController.lua
-- Handles picking a piece type/variant from the palette and placing it on the hex board
-- via mouse click in the 3D viewport. Client-side only for now (visual + local collision
-- tracking) - wiring to the server SimulationEngine happens in a later step via Remotes.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HexCoord = require(ReplicatedStorage.Shared.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local HexGrid = require(ReplicatedStorage.Shared.Hex.HexGrid)

local PuzzleDefinitions = require(ReplicatedStorage.Shared.Puzzles.PuzzleDefinitions)
type PuzzleDefinition = PuzzleDefinitions.PuzzleDefinition

local PlacementController = {}

local HEX_SIZE = 4
local FOLDER_NAME = "OpusFactoryPlacedPieces"
local BOARD_FOLDER_NAME = "OpusFactoryBoard"

local PIECE_COLORS = {
	Arm = Color3.fromRGB(178, 132, 58),
	Track = Color3.fromRGB(92, 133, 160),
	Bonder = Color3.fromRGB(88, 145, 105),
	Glyph = Color3.fromRGB(145, 56, 46),
}

local ARM_VARIANT_REACH = {
	Arm = 1,
	DoubleArm = 2,
	TripleArm = 3,
	HexArm = 6,
	PistonArm = 1,
}

type PlacedPiece = {
	pieceType: string,
	variant: string?,
	coord: HexCoord,
	armIndex: number?,
	model: Model,
}

local grid: any = nil
local placedPieces: { [string]: PlacedPiece } = {}
local cycleController: any = nil
local selectedType: string? = nil
local selectedVariant: string? = nil
local inputConnection: RBXScriptConnection? = nil

local function getOrCreateFolder(): Folder
	local existing = Workspace:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace
	return folder
end

local function isPointerOverUI(position: Vector2): boolean
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return false
	end
	local hits = playerGui:GetGuiObjectsAtPosition(position.X, position.Y)
	return #hits > 0
end

local function screenPointToHex(screenPos: Vector2): HexCoord?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local boardFolder = Workspace:FindFirstChild(BOARD_FOLDER_NAME)
	if not boardFolder then
		return nil
	end

	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { boardFolder }

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
	if not result then
		return nil
	end

	return HexCoord.fromWorldPosition(result.Position, HEX_SIZE)
end

local function createArmVisual(coord: HexCoord, variant: string?, parent: Instance, armIndex: number): Model
	local model = Instance.new("Model")
	model.Name = "Arm_" .. armIndex

	local reachCount = ARM_VARIANT_REACH[variant or "Arm"] or 1
	local worldPos = coord:toWorldPosition(HEX_SIZE)

	-- Odległość między środkami sąsiednich hexów w naszej siatce to HEX_SIZE * sqrt(3),
	-- nie HEX_SIZE * 0.45 jak było wcześniej - stąd ramiona wyglądały jakby się urywały.
	local REACH_DISTANCE = HEX_SIZE * math.sqrt(3)

	local hub = Instance.new("Part")
	hub.Name = "Hub"
	hub.Anchored = true
	hub.CanCollide = false
	hub.Shape = Enum.PartType.Cylinder
	hub.Material = Enum.Material.Neon
	hub.Color = Color3.fromRGB(120, 60, 150)
	hub.Size = Vector3.new(1, 2.4, 2.4)
	hub.CFrame = CFrame.new(worldPos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	hub.Parent = model

	for i = 0, reachCount - 1 do
		local angle = (360 / reachCount) * i
		local direction = Vector3.new(math.cos(math.rad(angle)), 0, math.sin(math.rad(angle)))

		local bar = Instance.new("Part")
		bar.Name = "Bar_" .. i
		bar.Anchored = true
		bar.CanCollide = false
		bar.Material = Enum.Material.Metal
		bar.Color = PIECE_COLORS.Arm
		bar.Size = Vector3.new(0.5, 0.5, REACH_DISTANCE)

		local barCenter = worldPos + Vector3.new(0, 1, 0) + direction * (REACH_DISTANCE / 2)
		bar.CFrame = CFrame.lookAt(barCenter, barCenter + direction)
		bar.Parent = model

		local grabNut = Instance.new("Part")
		grabNut.Name = "GrabNut_" .. i
		grabNut.Anchored = true
		grabNut.CanCollide = false
		grabNut.Shape = Enum.PartType.Cylinder
		grabNut.Material = Enum.Material.Metal
		grabNut.Color = Color3.fromRGB(200, 200, 210)
		grabNut.Size = Vector3.new(0.6, 1.3, 1.3)
		local grabPos = worldPos + Vector3.new(0, 1, 0) + direction * REACH_DISTANCE
		grabNut.CFrame = CFrame.new(grabPos) * CFrame.Angles(0, 0, math.rad(90))
		grabNut.Parent = model
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NumberLabel"
	billboard.Size = UDim2.new(0, 40, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = hub

	local numberLabel = Instance.new("TextLabel")
	numberLabel.Size = UDim2.new(1, 0, 1, 0)
	numberLabel.BackgroundTransparency = 0.2
	numberLabel.BackgroundColor3 = Color3.fromRGB(20, 17, 14)
	numberLabel.Text = tostring(armIndex)
	numberLabel.TextColor3 = Color3.fromRGB(238, 204, 130)
	numberLabel.Font = Enum.Font.GothamBold
	numberLabel.TextSize = 20
	numberLabel.Parent = billboard

	local labelCorner = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(1, 0)
	labelCorner.Parent = numberLabel

	model.PrimaryPart = hub
	model.Parent = parent
	return model
end

local function createSimpleVisual(coord: HexCoord, pieceType: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = pieceType .. "_" .. coord:toKey()

	local part = Instance.new("Part")
	part.Name = "Body"
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Metal
	part.Color = PIECE_COLORS[pieceType] or Color3.fromRGB(200, 200, 200)
	part.Size = Vector3.new(2.2, 1.2, 2.2)
	part.CFrame = CFrame.new(coord:toWorldPosition(HEX_SIZE) + Vector3.new(0, 0.6, 0))
	part.Parent = model

	model.PrimaryPart = part
	model.Parent = parent
	return model
end

local function tryPlaceAt(coord: HexCoord)
	if not selectedType or not grid then
		return
	end

	local ok = grid:place(coord, true)
	if not ok then
		return
	end

	local folder = getOrCreateFolder()
	local model: Model
	local armIndex: number? = nil

	if selectedType == "Arm" then
		if cycleController then
			armIndex = cycleController.addArm()
		end
		model = createArmVisual(coord, selectedVariant, folder, armIndex or 1)
	else
		model = createSimpleVisual(coord, selectedType, folder)
	end

	local placed: PlacedPiece = {
		pieceType = selectedType,
		variant = selectedVariant,
		coord = coord,
		armIndex = armIndex,
		model = model,
	}

	placedPieces[coord:toKey()] = placed
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		selectedType = nil
		selectedVariant = nil
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local mousePos = UserInputService:GetMouseLocation()
	if isPointerOverUI(mousePos) then
		return
	end

	if not selectedType then
		return
	end

	local coord = screenPointToHex(mousePos)
	if not coord then
		return
	end

	tryPlaceAt(coord)
end

function PlacementController.begin(puzzle: PuzzleDefinition)
	grid = HexGrid.new(puzzle.gridRadius)
	placedPieces = {}
	selectedType = nil
	selectedVariant = nil

	if inputConnection then
		inputConnection:Disconnect()
	end
	inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
end

function PlacementController.setCycleController(controller: any)
	cycleController = controller
end

function PlacementController.selectPieceType(pieceType: string, variant: string?)
	selectedType = pieceType
	selectedVariant = variant
end

function PlacementController.stop()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	local folder = Workspace:FindFirstChild(FOLDER_NAME)
	if folder then
		folder:Destroy()
	end

	grid = nil
	placedPieces = {}
	cycleController = nil
	selectedType = nil
	selectedVariant = nil
end

return PlacementController