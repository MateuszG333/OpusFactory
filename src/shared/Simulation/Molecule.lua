--!strict
-- Molecule.lua
-- Molekuła: grupa atomów połączonych wiązaniami, poruszająca się jako jedna sztywna bryła.
-- Odpowiada za: przechowywanie atomów+wiązań, ruch/rotację całej grupy, sprawdzanie kolizji przy ruchu.

local HexCoord = require(script.Parent.Parent.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local Molecule = {}
Molecule.__index = Molecule

export type Element = "Salt" | "Water" | "Fire" | "Earth" | "Air" | "Vitae" | "Mors"
	| "Quicksilver" | "Gold" | "Silver" | "Copper" | "Iron" | "Tin" | "Lead"

export type Atom = {
	element: Element,
	offset: HexCoord, -- pozycja atomu WZGLĘDEM centrum molekuły (nie świata)
}

export type Bond = {
	fromIndex: number, -- indeks atomu w tabeli atoms
	toIndex: number,
}

export type MoleculeData = typeof(setmetatable(
	{} :: {
		id: string,
		atoms: { Atom },
		bonds: { Bond },
		position: HexCoord, -- pozycja centrum (świat hex-grid)
		rotation: number, -- 0-5, orientacja bryły
	},
	Molecule
))

local nextId = 0
local function generateId(): string
	nextId += 1
	return string.format("mol_%d", nextId)
end

-- === Konstruktor ===
-- atoms: lista {element, offset} WZGLĘDEM centrum (0,0,0), np. pojedynczy atom to offset (0,0,0)

function Molecule.new(position: HexCoord, atoms: { Atom }, bonds: { Bond }?): MoleculeData
	assert(#atoms >= 1, "Molecule: potrzeba minimum 1 atomu")

	local self = setmetatable({
		id = generateId(),
		atoms = atoms,
		bonds = bonds or {},
		position = position,
		rotation = 0,
	}, Molecule)

	return self :: MoleculeData
end

-- Fabryka pomocnicza: pojedynczy atom jako "molekuła" jednoatomowa (najczęstszy przypadek)
function Molecule.single(position: HexCoord, element: Element): MoleculeData
	return Molecule.new(position, { { element = element, offset = HexCoord.new(0, 0, 0) } })
end

-- === Zapytania o zajmowane hexy w świecie ===

-- Zwraca listę hexów w świecie zajmowanych przez wszystkie atomy (uwzględnia rotację + pozycję)
function Molecule.getWorldHexes(self: MoleculeData): { HexCoord }
	local result = {}
	for _, atom in ipairs(self.atoms) do
		local rotatedOffset = HexCoord.rotate(atom.offset, self.rotation)
		table.insert(result, HexCoord.add(self.position, rotatedOffset))
	end
	return result
end

-- Sprawdza czy dany hex świata jest zajęty przez którykolwiek atom tej molekuły
function Molecule.occupiesHex(self: MoleculeData, coord: HexCoord): boolean
	for _, hex in ipairs(self:getWorldHexes()) do
		if HexCoord.equals(hex, coord) then
			return true
		end
	end
	return false
end

-- === Operacje ruchu - zwracają NOWY stan bez mutacji, żeby SimulationEngine mógł sprawdzić kolizję PRZED zatwierdzeniem ===

export type MoleculeMove =
	{ kind: "translate", delta: HexCoord }
	| { kind: "rotate", center: HexCoord, steps: number }

-- Zwraca hipotetyczną pozycję+rotację PO wykonaniu ruchu, bez mutowania oryginału
function Molecule.previewMove(self: MoleculeData, move: MoleculeMove): { position: HexCoord, rotation: number }
	if move.kind == "translate" then
		return {
			position = HexCoord.add(self.position, move.delta),
			rotation = self.rotation,
		}
	elseif move.kind == "rotate" then
		local newPosition = HexCoord.rotateAround(self.position, move.center, move.steps)
		local newRotation = (self.rotation + move.steps) % 6
		return { position = newPosition, rotation = newRotation }
	end
	error("Molecule.previewMove: nieznany typ ruchu")
end

-- Zwraca hexy jakie molekuła zajmowałaby PO wykonaniu ruchu (do sprawdzenia kolizji z resztą planszy)
function Molecule.getWorldHexesAfterMove(self: MoleculeData, move: MoleculeMove): { HexCoord }
	local preview = self:previewMove(move)
	local result = {}
	for _, atom in ipairs(self.atoms) do
		local rotation = preview.rotation
		local rotatedOffset = HexCoord.rotate(atom.offset, rotation)
		table.insert(result, HexCoord.add(preview.position, rotatedOffset))
	end
	return result
end

-- Faktycznie zatwierdza ruch (wywoływane PO sprawdzeniu kolizji przez SimulationEngine)
function Molecule.applyMove(self: MoleculeData, move: MoleculeMove)
	local preview = self:previewMove(move)
	self.position = preview.position
	self.rotation = preview.rotation
end

-- === Łączenie molekuł (Bonder) i rozdzielanie (Debonder) ===

-- Scala dwie molekuły w jedną (np. gdy Bonder tworzy wiązanie między dwoma osobnymi atomami/grupami)
-- UWAGA: zakłada że obie molekuły już sąsiadują ze sobą - walidację robi PuzzleValidator/SimulationEngine
function Molecule.merge(a: MoleculeData, b: MoleculeData): MoleculeData
	local combinedAtoms = table.clone(a.atoms)
	local indexOffset = #a.atoms

	for _, atom in ipairs(b.atoms) do
		-- offset atomów z 'b' trzeba przeliczyć względem centrum 'a'
		local worldOffset = HexCoord.add(
			HexCoord.sub(b.position, a.position),
			HexCoord.rotate(atom.offset, b.rotation - a.rotation)
		)
		table.insert(combinedAtoms, { element = atom.element, offset = worldOffset })
	end

	local combinedBonds = table.clone(a.bonds)
	for _, bond in ipairs(b.bonds) do
		table.insert(combinedBonds, {
			fromIndex = bond.fromIndex + indexOffset,
			toIndex = bond.toIndex + indexOffset,
		})
	end

	return Molecule.new(a.position, combinedAtoms, combinedBonds)
end

return Molecule