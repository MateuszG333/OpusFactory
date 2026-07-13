--!strict
-- Track.lua
-- Tor - linia hexów, po której Arm może się przesuwać (instrukcje Forward/Backward).
-- Sam z siebie nic nie robi w symulacji - to czysto pasywna struktura, którą odpytuje Arm.

local HexCoord = require(script.Parent.Parent.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local PieceBase = require(script.Parent.PieceBase)
type Piece = PieceBase.Piece

local Track = setmetatable({}, { __index = PieceBase })
Track.__index = Track

export type TrackData = typeof(setmetatable(
	{} :: {
		waypoints: { HexCoord }, -- uporządkowana lista hexów tworzących tor
		looped: boolean, -- czy tor zapętla się (koniec łączy się z początkiem)
	},
	Track
))

-- === Konstruktor ===
-- waypoints: lista hexów w kolejności - Arm porusza się po nich indeksami

function Track.new(waypoints: { HexCoord }, looped: boolean?): TrackData
	assert(#waypoints >= 2, "Track: potrzeba minimum 2 punktów")

	local base = PieceBase.new("Track", waypoints[1], 0)
	local self = setmetatable(base, Track) :: any

	self.waypoints = waypoints
	self.looped = looped or false

	return self :: TrackData
end

-- === Nadpisanie getFootprint - Track zajmuje WSZYSTKIE swoje hexy, nie tylko bazowy ===

function Track.getFootprint(self: TrackData): { HexCoord }
	return self.waypoints
end

-- Track nic nie robi samo z siebie w symulacji (nie ma instrukcji na cykl)
-- step() zostaje odziedziczone jako no-op z PieceBase

-- === Metody specyficzne dla Track ===

-- Zwraca indeks danego hexa na torze (albo nil jeśli hex nie należy do toru)
function Track.indexOf(self: TrackData, coord: HexCoord): number?
	for i, wp in ipairs(self.waypoints) do
		if HexCoord.equals(wp, coord) then
			return i
		end
	end
	return nil
end

-- Zwraca następny hex na torze względem aktualnego indeksu, w danym kierunku
-- direction: 1 = do przodu, -1 = do tyłu
-- Zwraca nil jeśli koniec toru osiągnięty i tor nie jest looped
function Track.nextPosition(self: TrackData, currentCoord: HexCoord, direction: number): HexCoord?
	local idx = self:indexOf(currentCoord)
	if not idx then
		return nil -- currentCoord nie leży na tym torze
	end

	local nextIdx = idx + direction

	if self.looped then
		local count = #self.waypoints
		nextIdx = ((nextIdx - 1) % count) + 1
		return self.waypoints[nextIdx]
	end

	if nextIdx < 1 or nextIdx > #self.waypoints then
		return nil -- koniec toru, nie ma dokąd jechać
	end

	return self.waypoints[nextIdx]
end

-- === Fabryka pomocnicza: prosty odcinek toru w jedną stronę o zadanej długości ===
-- start: hex startowy, direction: kierunek (1-6 wg HexCoord.direction), length: ile hexów

function Track.straight(start: HexCoord, direction: number, length: number): TrackData
	local waypoints = { start }
	local current = start
	for _ = 1, length - 1 do
		current = HexCoord.neighbor(current, direction)
		table.insert(waypoints, current)
	end
	return Track.new(waypoints)
end

return Track