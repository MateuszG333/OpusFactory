--!strict
-- PieceIcons.lua
-- Generuje proste, oryginalne ikony wektorowe dla elementów (Arm, Track, Bonder, Glyph).
-- Rysowane programowo z Frame/UICorner - stylistycznie nawiązują do mechanicznego klimatu,
-- ale to własna, oryginalna grafika, nie kopia jakichkolwiek zewnętrznych assetów.

local PieceIcons = {}

local ICON_LINE_COLOR = Color3.fromRGB(200, 202, 208)

local function makeBar(parent: Instance, size: UDim2, position: UDim2, rotation: number?, color: Color3?)
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Size = size
	bar.Position = position
	bar.Rotation = rotation or 0
	bar.BackgroundColor3 = color or ICON_LINE_COLOR
	bar.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = bar

	bar.Parent = parent
	return bar
end

local function makeHex(parent: Instance, size: UDim2, position: UDim2, color: Color3?)
	-- uproszczony "hex" jako zaokrąglony kwadrat obrócony o 30 stopni - czytelny w małej skali
	local hex = Instance.new("Frame")
	hex.AnchorPoint = Vector2.new(0.5, 0.5)
	hex.Size = size
	hex.Position = position
	hex.Rotation = 30
	hex.BackgroundColor3 = color or ICON_LINE_COLOR
	hex.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = hex

	hex.Parent = parent
	return hex
end

-- === Arm: linia od centrum + "dłoń" (mały hex) na końcu ===
function PieceIcons.createArmIcon(parent: Instance): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	makeBar(container, UDim2.new(0.6, 0, 0.12, 0), UDim2.new(0.5, 0, 0.5, 0), -30)
	makeHex(container, UDim2.new(0.28, 0, 0.28, 0), UDim2.new(0.78, 0, 0.28, 0))
	makeHex(container, UDim2.new(0.2, 0, 0.2, 0), UDim2.new(0.22, 0, 0.72, 0), Color3.fromRGB(120, 122, 130))

	return container
end

-- === Track: kropkowana/segmentowa linia ===
function PieceIcons.createTrackIcon(parent: Instance): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	for i = 0, 3 do
		local t = i / 3
		makeHex(
			container,
			UDim2.new(0.16, 0, 0.16, 0),
			UDim2.new(0.15 + t * 0.7, 0, 0.5, 0),
			Color3.fromRGB(120, 122, 130)
		)
	end

	return container
end

-- === Bonder: dwa hexy połączone krótką belką (wiązanie) ===
function PieceIcons.createBonderIcon(parent: Instance): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	makeHex(container, UDim2.new(0.32, 0, 0.32, 0), UDim2.new(0.32, 0, 0.5, 0))
	makeHex(container, UDim2.new(0.32, 0, 0.32, 0), UDim2.new(0.68, 0, 0.5, 0))
	makeBar(container, UDim2.new(0.3, 0, 0.08, 0), UDim2.new(0.5, 0, 0.5, 0), 0, Color3.fromRGB(150, 170, 190))

	return container
end

-- === Glyph: hex z symbolem w środku (prosty diament jako placeholder na "runę") ===
function PieceIcons.createGlyphIcon(parent: Instance): Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	makeHex(container, UDim2.new(0.6, 0, 0.6, 0), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(60, 63, 71))
	makeHex(container, UDim2.new(0.24, 0, 0.24, 0), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(150, 170, 190))

	return container
end

local FACTORY_BY_TYPE = {
	Arm = PieceIcons.createArmIcon,
	Track = PieceIcons.createTrackIcon,
	Bonder = PieceIcons.createBonderIcon,
	Glyph = PieceIcons.createGlyphIcon,
}

function PieceIcons.create(pieceType: string, parent: Instance): Frame?
	local factory = FACTORY_BY_TYPE[pieceType]
	if not factory then
		return nil
	end
	return factory(parent)
end

return PieceIcons