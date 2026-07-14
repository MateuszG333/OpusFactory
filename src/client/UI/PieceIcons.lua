--!strict
-- PieceIcons.lua
-- Ikony stylizowane na klucz płasko-oczkowy: rękojeść (bar) zakończona pierścieniem (oczkiem),
-- który symbolicznie reprezentuje "chwytanie" (atomu, wiązania, itd.). Własna, oryginalna
-- grafika wektorowa - nie kopia jakiegokolwiek zewnętrznego assetu.

local PieceIcons = {}

local METAL_LIGHT = Color3.fromRGB(196, 199, 205)
local METAL_MID = Color3.fromRGB(150, 154, 162)
local METAL_DARK = Color3.fromRGB(96, 100, 108)

local function makeBar(parent: Instance, size: UDim2, position: UDim2, rotation: number?, color: Color3?)
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Size = size
	bar.Position = position
	bar.Rotation = rotation or 0
	bar.BackgroundColor3 = color or METAL_MID
	bar.BorderSizePixel = 0
	bar.ZIndex = 2

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = bar

	bar.Parent = parent
	return bar
end

-- Pierścień ("oczko") - koło z otworem w środku, imitujące oczko klucza.
-- ringColor = kolor metalu, holeColor = kolor "dziury" (musi pasować do tła ikonki)
local function makeRing(
	parent: Instance,
	outerSize: UDim2,
	position: UDim2,
	ringColor: Color3?,
	holeColor: Color3?,
	holeFraction: number?
): Frame
	local outer = Instance.new("Frame")
	outer.AnchorPoint = Vector2.new(0.5, 0.5)
	outer.Size = outerSize
	outer.Position = position
	outer.BackgroundColor3 = ringColor or METAL_MID
	outer.BorderSizePixel = 0
	outer.ZIndex = 2

	local outerCorner = Instance.new("UICorner")
	outerCorner.CornerRadius = UDim.new(1, 0)
	outerCorner.Parent = outer

	outer.Parent = parent

	local hole = Instance.new("Frame")
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	hole.Size = UDim2.new(holeFraction or 0.5, 0, holeFraction or 0.5, 0)
	hole.Position = UDim2.new(0.5, 0, 0.5, 0)
	hole.BackgroundColor3 = holeColor or Color3.fromRGB(38, 38, 41)
	hole.BorderSizePixel = 0
	hole.ZIndex = 3

	local holeCorner = Instance.new("UICorner")
	holeCorner.CornerRadius = UDim.new(1, 0)
	holeCorner.Parent = hole

	hole.Parent = outer

	return outer
end

local function makeHex(parent: Instance, size: UDim2, position: UDim2, color: Color3?)
	local hex = Instance.new("Frame")
	hex.AnchorPoint = Vector2.new(0.5, 0.5)
	hex.Size = size
	hex.Position = position
	hex.Rotation = 30
	hex.BackgroundColor3 = color or METAL_MID
	hex.BorderSizePixel = 0
	hex.ZIndex = 2

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = hex

	hex.Parent = parent
	return hex
end

-- === Arm: klucz płasko-oczkowy - rękojeść z pierścieniem (chwytakiem) na jednym końcu
-- i płaskim, otwartym zakończeniem na drugim ===
local ARM_VARIANT_REACH = {
	Arm = 1,
	DoubleArm = 2,
	TripleArm = 3,
	HexArm = 6,
	PistonArm = 1,
}

local HUB_COLOR = Color3.fromRGB(90, 40, 110)
local HUB_RING_COLOR = Color3.fromRGB(200, 170, 90)

local function makeNut(parent: Instance, size: UDim2, position: UDim2, rotation: number?, color: Color3?)
	local nut = Instance.new("Frame")
	nut.AnchorPoint = Vector2.new(0.5, 0.5)
	nut.Size = size
	nut.Position = position
	nut.Rotation = rotation or 0
	nut.BackgroundColor3 = color or METAL_LIGHT
	nut.BorderSizePixel = 0
	nut.ZIndex = 2

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = nut

	nut.Parent = parent
	return nut
end

-- === Arm: fioletowy hub centralny (oś obrotu) + N metalowych prętów zakończonych
-- małą sześciokątną nakrętką (chwytak). N zależy od wariantu ramienia. ===
function PieceIcons.createArmIcon(parent: Instance, variant: string?): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local reachCount = ARM_VARIANT_REACH[variant or "Arm"] or 1
	local grabDistance = 0.38

	for i = 0, reachCount - 1 do
		local angle = (360 / reachCount) * i - 90
		local dx = math.cos(math.rad(angle))
		local dy = math.sin(math.rad(angle))

		local barCenterDist = grabDistance / 2
		local barPos = UDim2.new(0.5 + dx * barCenterDist, 0, 0.5 + dy * barCenterDist, 0)
		makeBar(container, UDim2.new(grabDistance, 0, 0.075, 0), barPos, angle, METAL_MID)

		local grabPos = UDim2.new(0.5 + dx * grabDistance, 0, 0.5 + dy * grabDistance, 0)
		makeNut(container, UDim2.new(0.22, 0, 0.22, 0), grabPos, 30, METAL_LIGHT)
		makeNut(container, UDim2.new(0.13, 0, 0.13, 0), grabPos, 0, METAL_DARK)
	end

	-- hub na samym końcu (rysowany na wierzchu, żeby zakrywał zbiegające się w centrum pręty)
	local hub = Instance.new("Frame")
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Size = UDim2.new(0.3, 0, 0.3, 0)
	hub.Position = UDim2.new(0.5, 0, 0.5, 0)
	hub.BackgroundColor3 = HUB_RING_COLOR
	hub.BorderSizePixel = 0
	hub.ZIndex = 3
	local hubCorner = Instance.new("UICorner")
	hubCorner.CornerRadius = UDim.new(1, 0)
	hubCorner.Parent = hub
	hub.Parent = container

	local hubCenter = Instance.new("Frame")
	hubCenter.AnchorPoint = Vector2.new(0.5, 0.5)
	hubCenter.Size = UDim2.new(0.78, 0, 0.78, 0)
	hubCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
	hubCenter.BackgroundColor3 = HUB_COLOR
	hubCenter.BorderSizePixel = 0
	hubCenter.ZIndex = 4
	local hubCenterCorner = Instance.new("UICorner")
	hubCenterCorner.CornerRadius = UDim.new(1, 0)
	hubCenterCorner.Parent = hubCenter
	hubCenter.Parent = hub

	return container
end
-- === Track: linia szyn z powtarzającymi się małymi oczkami (nity mocujące tor) ===
function PieceIcons.createTrackIcon(parent: Instance): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	makeBar(container, UDim2.new(0.82, 0, 0.1, 0), UDim2.new(0.5, 0, 0.5, 0), 0, METAL_DARK)

	for i = 0, 3 do
		local t = i / 3
		makeRing(
			container,
			UDim2.new(0.2, 0, 0.2, 0),
			UDim2.new(0.12 + t * 0.76, 0, 0.5, 0),
			METAL_LIGHT,
			nil,
			0.4
		)
	end

	return container
end

-- === Bonder: dwa oczka kluczy złączone wspólną rękojeścią - symbol tworzenia wiązania ===
function PieceIcons.createBonderIcon(parent: Instance): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	makeBar(container, UDim2.new(0.34, 0, 0.14, 0), UDim2.new(0.5, 0, 0.5, 0), 0, METAL_DARK)

	makeRing(container, UDim2.new(0.4, 0, 0.4, 0), UDim2.new(0.3, 0, 0.5, 0), METAL_LIGHT)
	makeRing(container, UDim2.new(0.4, 0, 0.4, 0), UDim2.new(0.7, 0, 0.5, 0), METAL_MID)

	return container
end

-- === Glyph: oczko klucza z wygrawerowanym symbolem (hex) w środku - "narzędzie transformacji" ===
function PieceIcons.createGlyphIcon(parent: Instance): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	makeRing(container, UDim2.new(0.7, 0, 0.7, 0), UDim2.new(0.5, 0, 0.5, 0), METAL_MID, nil, 0.62)
	makeHex(container, UDim2.new(0.3, 0, 0.3, 0), UDim2.new(0.5, 0, 0.5, 0), METAL_LIGHT)

	return container
end

local FACTORY_BY_TYPE = {
	Arm = PieceIcons.createArmIcon,
	Track = PieceIcons.createTrackIcon,
	Bonder = PieceIcons.createBonderIcon,
	Glyph = PieceIcons.createGlyphIcon,
}

function PieceIcons.create(pieceType: string, parent: Instance, variant: string?): Frame?
	local factory = FACTORY_BY_TYPE[pieceType]
	if not factory then
		return nil
	end
	if pieceType == "Arm" then
		return PieceIcons.createArmIcon(parent, variant)
	end
	return factory(parent)
end

return PieceIcons