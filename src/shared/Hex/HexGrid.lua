--!strict
-- HexGrid.lua
-- Kontener planszy: mapowanie HexCoord -> piece (dowolny obiekt zajmujący dany hex)
-- Nie wie NIC o typach pieców (Arm, Track, itd.) - to czysto przestrzenna struktura danych

local HexCoord = require(script.Parent.HexCoord)
type HexCoord = HexCoord.HexCoord

local HexGrid = {}
HexGrid.__index = HexGrid

export type HexGrid = typeof(setmetatable(
	{} :: {
		cells: { [string]: any }, -- key (z HexCoord.toKey) -> piece
		bounds: { radius: number }, -- opcjonalny limit planszy (np. Opus Magnum ma różne rozmiary plansz per puzzle)
	},
	HexGrid
))

-- === Konstruktor ===

function HexGrid.new(radius: number?): HexGrid
	local self = setmetatable({
		cells = {},
		bounds = { radius = radius or 5 },
	}, HexGrid)
	return self
end

-- === Podstawowe operacje ===

function HexGrid.isInBounds(self: HexGrid, coord: HexCoord): boolean
	local origin = HexCoord.new(0, 0, 0)
	return HexCoord.distance(coord, origin) <= self.bounds.radius
end

function HexGrid.isOccupied(self: HexGrid, coord: HexCoord): boolean
	return self.cells[HexCoord.toKey(coord)] ~= nil
end

function HexGrid.get(self: HexGrid, coord: HexCoord): any
	return self.cells[HexCoord.toKey(coord)]
end

-- Zwraca false + powód jeśli nie można postawić (zajęte / poza planszą)
function HexGrid.canPlace(self: HexGrid, coord: HexCoord): (boolean, string?)
	if not self:isInBounds(coord) then
		return false, "OutOfBounds"
	end
	if self:isOccupied(coord) then
		return false, "Occupied"
	end
	return true
end

function HexGrid.place(self: HexGrid, coord: HexCoord, piece: any): (boolean, string?)
	local ok, reason = self:canPlace(coord)
	if not ok then
		return false, reason
	end
	self.cells[HexCoord.toKey(coord)] = piece
	return true
end

function HexGrid.remove(self: HexGrid, coord: HexCoord): any
	local key = HexCoord.toKey(coord)
	local piece = self.cells[key]
	self.cells[key] = nil
	return piece
end

-- Przenosi piece z jednego hexa na drugi (przydatne dla Track - piece ślizga się po torze)
function HexGrid.move(self: HexGrid, fromCoord: HexCoord, toCoord: HexCoord): (boolean, string?)
	local piece = self:get(fromCoord)
	if not piece then
		return false, "NothingToMove"
	end
	local ok, reason = self:canPlace(toCoord)
	if not ok then
		return false, reason
	end
	self:remove(fromCoord)
	self.cells[HexCoord.toKey(toCoord)] = piece
	return true
end

-- === Wielohexowe piece (np. Arm zajmuje kilka pól, Bonder zajmuje 2) ===
-- footprint = lista HexCoord które piece zajmuje względem swojej pozycji bazowej

function HexGrid.canPlaceFootprint(self: HexGrid, footprint: { HexCoord }): (boolean, string?)
	for _, coord in ipairs(footprint) do
		local ok, reason = self:canPlace(coord)
		if not ok then
			return false, reason
		end
	end
	return true
end

function HexGrid.placeFootprint(self: HexGrid, footprint: { HexCoord }, piece: any): (boolean, string?)
	local ok, reason = self:canPlaceFootprint(footprint)
	if not ok then
		return false, reason
	end
	for _, coord in ipairs(footprint) do
		self.cells[HexCoord.toKey(coord)] = piece
	end
	return true
end

function HexGrid.removeFootprint(self: HexGrid, footprint: { HexCoord })
	for _, coord in ipairs(footprint) do
		self.cells[HexCoord.toKey(coord)] = nil
	end
end

-- === Iteracja po całej planszy ===

function HexGrid.forEach(self: HexGrid, callback: (HexCoord, any) -> ())
	for key, piece in pairs(self.cells) do
		local x, y, z = string.match(key, "(-?%d+),(-?%d+),(-?%d+)")
		local coord = HexCoord.new(tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number)
		callback(coord, piece)
	end
end

-- Zwraca wszystkie hexy w promieniu R od danego centrum - przydatne do generowania planszy do renderu
function HexGrid.hexesInRadius(center: HexCoord, radius: number): { HexCoord }
	local results = {}
	for x = -radius, radius do
		for y = math.max(-radius, -x - radius), math.min(radius, -x + radius) do
			local z = -x - y
			table.insert(results, HexCoord.add(center, HexCoord.new(x, y, z)))
		end
	end
	return results
end

-- === Czyszczenie ===

function HexGrid.clear(self: HexGrid)
	self.cells = {}
end

return HexGrid