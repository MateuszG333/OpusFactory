--!strict
-- HexCoord.lua
-- Matematyka siatki heksagonalnej oparta o cube coordinates (x + y + z = 0)
-- Konwencja: "pointy-top" hexy, tak jak w Opus Magnum

local HexCoord = {}
HexCoord.__index = HexCoord

export type HexCoord = typeof(setmetatable(
	{} :: { x: number, y: number, z: number },
	HexCoord
))

-- Rozmiar heksa w studach (world units) — dostosuj pod swój model
local HEX_SIZE = 4

-- === Konstruktor ===

function HexCoord.new(x: number, y: number, z: number?): HexCoord
	local zz = z or (-x - y)
	assert(math.abs(x + y + zz) < 1e-6, "HexCoord: x + y + z musi równać się 0")
	local self = setmetatable({ x = x, y = y, z = zz }, HexCoord)
	return self
end

-- Skrót do tworzenia z axial coords (x, z) — y wyliczane automatycznie
function HexCoord.fromAxial(q: number, r: number): HexCoord
	return HexCoord.new(q, -q - r, r)
end

-- === Operacje podstawowe ===

function HexCoord.add(a: HexCoord, b: HexCoord): HexCoord
	return HexCoord.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

function HexCoord.sub(a: HexCoord, b: HexCoord): HexCoord
	return HexCoord.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

function HexCoord.equals(a: HexCoord, b: HexCoord): boolean
	return a.x == b.x and a.y == b.y and a.z == b.z
end

-- Unikalny klucz do używania jako indeks w tabelach/słownikach (np. HexGrid)
function HexCoord.toKey(self: HexCoord): string
	return string.format("%d,%d,%d", self.x, self.y, self.z)
end

-- === Sąsiedzi i kierunki ===

-- 6 kierunków w cube coords, w kolejności zgodnej z ruchem wskazówek zegara
local DIRECTIONS = {
	HexCoord.new(1, -1, 0),
	HexCoord.new(1, 0, -1),
	HexCoord.new(0, 1, -1),
	HexCoord.new(-1, 1, 0),
	HexCoord.new(-1, 0, 1),
	HexCoord.new(0, -1, 1),
}

function HexCoord.direction(index: number): HexCoord
	-- index 1-6
	local i = ((index - 1) % 6) + 1
	return DIRECTIONS[i]
end

function HexCoord.neighbor(self: HexCoord, direction: number): HexCoord
	return HexCoord.add(self, HexCoord.direction(direction))
end

function HexCoord.allNeighbors(self: HexCoord): { HexCoord }
	local result = {}
	for i = 1, 6 do
		table.insert(result, HexCoord.neighbor(self, i))
	end
	return result
end

-- === Rotacje ===
-- Rotacja o 60 stopni wokół (0,0,0) — kluczowe dla obracania ramion (Arm)
-- steps > 0 = zgodnie z ruchem wskazówek zegara, steps < 0 = przeciwnie

function HexCoord.rotate(self: HexCoord, steps: number): HexCoord
	local s = steps % 6
	local x, y, z = self.x, self.y, self.z
	for _ = 1, s do
		x, y, z = -z, -x, -y
	end
	return HexCoord.new(x, y, z)
end

-- Rotacja wokół dowolnego centrum (np. obrót ramienia wokół jego podstawy)
function HexCoord.rotateAround(self: HexCoord, center: HexCoord, steps: number): HexCoord
	local relative = HexCoord.sub(self, center)
	local rotated = HexCoord.rotate(relative, steps)
	return HexCoord.add(rotated, center)
end

-- === Odległości ===

function HexCoord.distance(a: HexCoord, b: HexCoord): number
	local diff = HexCoord.sub(a, b)
	return (math.abs(diff.x) + math.abs(diff.y) + math.abs(diff.z)) / 2
end

-- === Konwersja do świata 3D (do renderowania w Workspace) ===

function HexCoord.toWorldPosition(self: HexCoord, size: number?): Vector3
	local s = size or HEX_SIZE
	local worldX = s * (3 / 2 * self.x)
	local worldZ = s * (math.sqrt(3) / 2 * self.x + math.sqrt(3) * self.z)
	return Vector3.new(worldX, 0, worldZ)
end

-- Odwrotność — z pozycji w świecie do najbliższego heksa (przydatne przy klikaniu myszką)
function HexCoord.fromWorldPosition(pos: Vector3, size: number?): HexCoord
	local s = size or HEX_SIZE
	local q = (2 / 3 * pos.X) / s
	local r = (-1 / 3 * pos.X + math.sqrt(3) / 3 * pos.Z) / s
	return HexCoord.roundAxial(q, r)
end

-- Zaokrąglanie axial coords do najbliższego pełnego heksa
function HexCoord.roundAxial(q: number, r: number): HexCoord
	local x = q
	local z = r
	local y = -x - z

	local rx = math.round(x)
	local ry = math.round(y)
	local rz = math.round(z)

	local xDiff = math.abs(rx - x)
	local yDiff = math.abs(ry - y)
	local zDiff = math.abs(rz - z)

	if xDiff > yDiff and xDiff > zDiff then
		rx = -ry - rz
	elseif yDiff > zDiff then
		ry = -rx - rz
	else
		rz = -rx - ry
	end

	return HexCoord.new(rx, ry, rz)
end

return HexCoord