--!strict
-- Glyph.lua
-- Uniwersalny kontener dla różnych typów glyphów (Calcification, Duplication, Unbonding, itd.)
-- Każdy typ ma swój własny footprint i swoją logikę w step() - rozgałęzione przez glyphType.

local HexCoord = require(script.Parent.Parent.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local PieceBase = require(script.Parent.PieceBase)

local Glyph = setmetatable({}, { __index = PieceBase })
Glyph.__index = Glyph

export type GlyphType = "Calcification" | "Duplication" | "Unbonding" | "Projection" | "Purification" | "Animismus"

-- Footprinty względem position, w zależności od typu (część glyphów zajmuje 1 hex, inne 2-3)
local FOOTPRINT_OFFSETS: { [GlyphType]: { HexCoord.HexCoord } } = {
	Calcification = { HexCoord.new(0, 0, 0) },
	Duplication = { HexCoord.new(0, 0, 0) },
	Unbonding = { HexCoord.new(0, 0, 0), HexCoord.new(1, -1, 0) },
	Projection = { HexCoord.new(0, 0, 0), HexCoord.new(1, -1, 0) },
	Purification = { HexCoord.new(0, 0, 0), HexCoord.new(1, -1, 0) },
	Animismus = {
		HexCoord.new(0, 0, 0),
		HexCoord.new(1, -1, 0),
		HexCoord.new(1, 0, -1),
		HexCoord.new(0, 1, -1),
	},
}

export type GlyphData = typeof(setmetatable(
	{} :: {
		glyphType: GlyphType,
	},
	Glyph
))

-- === Konstruktor ===

function Glyph.new(position: HexCoord, rotation: number, glyphType: GlyphType): GlyphData
	local base = PieceBase.new("Glyph", position, rotation)
	local self = setmetatable(base, Glyph) :: any

	self.glyphType = glyphType

	return self :: GlyphData
end

function Glyph.getFootprint(self: GlyphData): { HexCoord }
	local offsets = FOOTPRINT_OFFSETS[self.glyphType]
	local result = {}
	for _, offset in ipairs(offsets) do
		local rotated = HexCoord.rotate(offset, self.rotation)
		table.insert(result, HexCoord.add(self.position, rotated))
	end
	return result
end

-- === Reakcja co cykl - rozgałęzione po glyphType ===
-- ctx oczekiwany interfejs (rozszerzany w miarę potrzeb):
--   ctx.getMoleculeAt(coord): string?
--   ctx.transmuteAtom(moleculeId, hex, newElement): zmienia element atomu na danym hexie (Calcification)
--   ctx.duplicateAtom(sourceHex, targetHex, element): kopiuje element z jednego atomu na drugi (Duplication)
--   ctx.unbondAt(hexA, hexB): usuwa wiązanie między dwoma sąsiednimi hexami (Unbonding)

function Glyph.step(self: GlyphData, ctx: any)
	local footprint = self:getFootprint()

	if self.glyphType == "Calcification" then
		self:stepCalcification(footprint, ctx)
	elseif self.glyphType == "Duplication" then
		self:stepDuplication(footprint, ctx)
	elseif self.glyphType == "Unbonding" then
		self:stepUnbonding(footprint, ctx)
	else
		-- Projection, Purification, Animismus - do zaimplementowania później,
		-- na razie no-op żeby nie crashować symulacji na nieznanym typie
		warn(("Glyph.step: typ '%s' jeszcze nie zaimplementowany"):format(self.glyphType))
	end
end

function Glyph.stepCalcification(self: GlyphData, footprint: { HexCoord }, ctx: any)
	local moleculeId = ctx.getMoleculeAt(footprint[1])
	if not moleculeId then
		return
	end
	-- Calcification zamienia Quicksilver na dowolny metal - konkretny metal wybiera gracz w UI,
	-- na razie zakładam że ctx dostarcza docelowy element (np. z konfiguracji glyphu)
	ctx.transmuteAtom(moleculeId, footprint[1], self.targetElement or "Lead")
end

function Glyph.stepDuplication(self: GlyphData, footprint: { HexCoord }, ctx: any)
	-- footprint[1] = źródło (wzór), footprint[2] = cel (Quicksilver do zamiany)
	local sourceMoleculeId = ctx.getMoleculeAt(footprint[1])
	local targetMoleculeId = ctx.getMoleculeAt(footprint[2])
	if not sourceMoleculeId or not targetMoleculeId then
		return
	end
	ctx.duplicateAtom(footprint[1], footprint[2])
end

function Glyph.stepUnbonding(self: GlyphData, footprint: { HexCoord }, ctx: any)
	local moleculeIdA = ctx.getMoleculeAt(footprint[1])
	local moleculeIdB = ctx.getMoleculeAt(footprint[2])
	if not moleculeIdA or not moleculeIdB or moleculeIdA ~= moleculeIdB then
		return -- muszą być tym samym, połączonym ze sobą molekułem
	end
	ctx.unbondAt(footprint[1], footprint[2])
end

return Glyph