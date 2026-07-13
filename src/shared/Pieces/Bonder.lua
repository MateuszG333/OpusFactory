--!strict
-- Bonder.lua
-- Tworzy wiązanie między dwoma atomami, gdy oba leżą na jego dwóch polach naraz.
-- Zajmuje 2 sąsiadujące hexy (footprint). Nie ma instrukcji - reaguje pasywnie co cykl.

local HexCoord = require(script.Parent.Parent.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local PieceBase = require(script.Parent.PieceBase)

local Bonder = setmetatable({}, { __index = PieceBase })
Bonder.__index = Bonder

export type BonderData = typeof(setmetatable(
	{} :: {
		secondHex: HexCoord, -- drugie pole Bondera (position z PieceBase to pierwsze pole)
	},
	Bonder
))

-- === Konstruktor ===
-- position: pierwsze pole, direction: kierunek (1-6) w którym leży drugie pole

function Bonder.new(position: HexCoord, direction: number): BonderData
	local base = PieceBase.new("Bonder", position, 0)
	local self = setmetatable(base, Bonder) :: any

	self.secondHex = HexCoord.neighbor(position, direction)

	return self :: BonderData
end

function Bonder.getFootprint(self: BonderData): { HexCoord }
	return { self.position, self.secondHex }
end

-- === Reakcja co cykl ===
-- ctx oczekiwany interfejs (dodatkowo do tego co miał Arm):
--   ctx.getMoleculeAt(coord): string?
--   ctx.bondMolecules(moleculeIdA, moleculeIdB, hexA, hexB): scala dwie molekuły w jedną (albo dodaje wiązanie jeśli to ta sama molekuła)

function Bonder.step(self: BonderData, ctx: any)
	local moleculeIdA = ctx.getMoleculeAt(self.position)
	local moleculeIdB = ctx.getMoleculeAt(self.secondHex)

	if not moleculeIdA or not moleculeIdB then
		return -- brak atomu na jednym z pól - nic do zbondowania
	end

	if moleculeIdA == moleculeIdB then
		return -- to już ta sama molekuła (np. już wcześniej zbondowana) - nic nie rób
	end

	ctx.bondMolecules(moleculeIdA, moleculeIdB, self.position, self.secondHex)
end

return Bonder