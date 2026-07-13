--!strict
-- PieceBase.lua
-- Wspólny interfejs dla wszystkich elementów planszy.
-- Konkretne piece (Arm, Track, Bonder, Glyph...) dziedziczą z tego przez setmetatable(instance, ConcreteClass)
-- gdzie ConcreteClass.__index ma __index = PieceBase (łańcuch metatabel).

local HexCoord = require(script.Parent.Parent.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local PieceBase = {}
PieceBase.__index = PieceBase

export type PieceType = "Arm" | "Track" | "Bonder" | "Debonder" | "Glyph" | "Input" | "Output"

export type Piece = typeof(setmetatable(
	{} :: {
		id: string, -- unikalne id instancji (do referencji z zewnątrz - UI, remoty)
		pieceType: PieceType,
		position: HexCoord, -- hex bazowy (dla Arm to punkt obrotu)
		rotation: number, -- 0-5, orientacja w krokach 60 stopni
		model: Model?, -- powiązany model 3D w Workspace (przypisywany przez renderer, nie przez logikę)
	},
	PieceBase
))

local nextId = 0
local function generateId(): string
	nextId += 1
	return string.format("piece_%d", nextId)
end

-- === Konstruktor bazowy - konkretne klasy wołają to jako super.new() ===

function PieceBase.new(pieceType: PieceType, position: HexCoord, rotation: number?): Piece
	local self = setmetatable({
		id = generateId(),
		pieceType = pieceType,
		position = position,
		rotation = rotation or 0,
		model = nil,
	}, PieceBase)
	return self
end

-- === Metody, które KAŻDY konkretny piece MUSI nadpisać ===
-- (tu tylko error żeby złapać brakującą implementację od razu, a nie ciche zachowanie)

-- Zwraca listę hexów zajmowanych przez ten piece (względem aktualnej pozycji/rotacji)
function PieceBase.getFootprint(self: Piece): { HexCoord }
	error(("getFootprint() nie zaimplementowane dla %s"):format(self.pieceType))
end

-- Wykonuje pojedynczy krok symulacji dla danej instrukcji na tym cyklu (jeśli piece taką ma)
-- ctx = SimulationContext (grid, molecules, itd.) - przekazywany przez SimulationEngine
function PieceBase.step(self: Piece, ctx: any)
	-- domyślnie: piece nic nie robi w danym cyklu (np. Track sam z siebie nic nie inicjuje)
end

-- === Metody wspólne, gotowe do użycia od razu ===

function PieceBase.rotate(self: Piece, steps: number)
	self.rotation = (self.rotation + steps) % 6
end

function PieceBase.serialize(self: Piece): { [string]: any }
	return {
		id = self.id,
		pieceType = self.pieceType,
		position = { x = self.position.x, y = self.position.y, z = self.position.z },
		rotation = self.rotation,
	}
end

function PieceBase.deserialize(data: { [string]: any }): Piece
	local pos = HexCoord.new(data.position.x, data.position.y, data.position.z)
	local self = PieceBase.new(data.pieceType, pos, data.rotation)
	self.id = data.id -- zachowaj oryginalne id przy wczytywaniu zapisu
	return self
end

return PieceBase