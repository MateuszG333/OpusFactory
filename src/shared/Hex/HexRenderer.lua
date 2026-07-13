--!strict
-- HexRenderer.lua
-- Generuje wizualną reprezentację siatki heksagonalnej w Workspace.
-- Czysty renderer - nie wie NIC o logice gry, tylko rysuje hexy i pozycjonuje modele pieców.

local HexCoord = require(script.Parent.HexCoord)
type HexCoord = HexCoord.HexCoord

local HexRenderer = {}

local HEX_SIZE = 4 -- musi się zgadzać z HexCoord.HEX_SIZE
local HEX_HEIGHT = 0.5 -- grubość płytki heksa

-- === Generowanie pojedynczego modelu heksa (płaska sześciokątna płytka) ===

local function createHexPart(coord: HexCoord, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = "Hex_" .. coord:toKey()
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(60, 60, 65)

	-- Roblox nie ma natywnego heksagonalnego Part, więc używamy CylinderMesh z 6 "bokami"
	-- najprościej: cienki cylinder obrócony tak by top/bottom był płaski, z SpecialMesh sześciokątnym
	-- (alternatywnie: docelowo zamienimy to na prawdziwy MeshPart z importowanego modelu heksa)
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(HEX_HEIGHT, HEX_SIZE * 1.6, HEX_SIZE * 1.6)

	local worldPos = coord:toWorldPosition(HEX_SIZE)
	part.CFrame = CFrame.new(worldPos) * CFrame.Angles(0, 0, math.rad(90))

	part.Parent = parent
	return part
end

-- === Generuje całą planszę (siatkę heksów) w danym promieniu ===

function HexRenderer.renderBoard(center: HexCoord, radius: number, parent: Instance): Folder
	local boardFolder = Instance.new("Folder")
	boardFolder.Name = "Board"
	boardFolder.Parent = parent

	local HexGrid = require(script.Parent.HexGrid)
	local hexes = HexGrid.hexesInRadius(center, radius)

	for _, coord in ipairs(hexes) do
		createHexPart(coord, boardFolder)
	end

	return boardFolder
end

-- === Renderowanie pojedynczego piece (na razie prosty placeholder - kolorowy blok) ===
-- Docelowo każdy typ piece (Arm, Track, Bonder...) będzie miał swój prawdziwy model,
-- na razie robimy uniwersalny "debug block" żeby zobaczyć POZYCJE i ROTACJE na scenie.

local PIECE_COLORS: { [string]: Color3 } = {
	Arm = Color3.fromRGB(220, 170, 60),
	Track = Color3.fromRGB(100, 100, 200),
	Bonder = Color3.fromRGB(200, 80, 80),
	Glyph = Color3.fromRGB(150, 200, 100),
}

function HexRenderer.renderPiece(piece: any, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = piece.pieceType .. "_" .. piece.id

	local block = Instance.new("Part")
	block.Name = "DebugBody"
	block.Anchored = true
	block.CanCollide = false
	block.Size = Vector3.new(2, 2, 2)
	block.Color = PIECE_COLORS[piece.pieceType] or Color3.fromRGB(255, 255, 255)
	block.Material = Enum.Material.Neon

	local worldPos = piece.position:toWorldPosition(HEX_SIZE)
	-- podnosimy nad planszę żeby było widać, plus rotacja w Y wg piece.rotation (60 stopni na krok)
	block.CFrame = CFrame.new(worldPos + Vector3.new(0, 1.5, 0))
		* CFrame.Angles(0, math.rad(piece.rotation * 60), 0)

	block.Parent = model
	model.PrimaryPart = block
	model.Parent = parent

	piece.model = model -- zapisujemy referencję z powrotem w piece, zgodnie z kontraktem z PieceBase

	return model
end

-- Aktualizuje pozycję/rotację JUŻ istniejącego modelu piece (wywoływane po każdym ruchu/rotacji)
function HexRenderer.updatePiecePosition(piece: any)
	if not piece.model or not piece.model.PrimaryPart then
		return
	end
	local worldPos = piece.position:toWorldPosition(HEX_SIZE)
	local newCFrame = CFrame.new(worldPos + Vector3.new(0, 1.5, 0))
		* CFrame.Angles(0, math.rad(piece.rotation * 60), 0)
	piece.model:SetPrimaryPartCFrame(newCFrame)
end

-- Renderuje molekułę jako kulki (atomy) - też placeholder, docelowo różne kolory per element
local ELEMENT_COLORS: { [string]: Color3 } = {
	Salt = Color3.fromRGB(230, 230, 230),
	Water = Color3.fromRGB(80, 150, 220),
	Fire = Color3.fromRGB(220, 80, 60),
	Earth = Color3.fromRGB(120, 90, 60),
	Air = Color3.fromRGB(200, 220, 230),
	Quicksilver = Color3.fromRGB(180, 180, 190),
}

function HexRenderer.renderMolecule(molecule: any, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Molecule_" .. molecule.id

	for i, atom in ipairs(molecule.atoms) do
		local ball = Instance.new("Part")
		ball.Name = "Atom_" .. i
		ball.Shape = Enum.PartType.Ball
		ball.Anchored = true
		ball.CanCollide = false
		ball.Size = Vector3.new(1.5, 1.5, 1.5)
		ball.Color = ELEMENT_COLORS[atom.element] or Color3.fromRGB(255, 0, 255)
		ball.Material = Enum.Material.Neon

		local rotatedOffset = HexCoord.rotate(atom.offset, molecule.rotation)
		local hexPos = HexCoord.add(molecule.position, rotatedOffset)
		local worldPos = hexPos:toWorldPosition(HEX_SIZE)
		ball.CFrame = CFrame.new(worldPos + Vector3.new(0, 1, 0))

		ball.Parent = model
	end

	model.Parent = parent
	molecule.model = model

	return model
end

function HexRenderer.updateMoleculePosition(molecule: any)
	if not molecule.model then
		return
	end
	for i, atom in ipairs(molecule.atoms) do
		local ball = molecule.model:FindFirstChild("Atom_" .. i)
		if ball then
			local rotatedOffset = HexCoord.rotate(atom.offset, molecule.rotation)
			local hexPos = HexCoord.add(molecule.position, rotatedOffset)
			local worldPos = hexPos:toWorldPosition(HEX_SIZE)
			ball.CFrame = CFrame.new(worldPos + Vector3.new(0, 1, 0))
		end
	end
end

return HexRenderer