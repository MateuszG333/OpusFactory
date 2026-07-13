--!strict
-- SimulationEngine.lua
-- Silnik spinający całość: HexGrid + wszystkie piece (Arm, Bonder, Glyph...) + Molecule.
-- Odpala pełne cykle symulacji, dostarcza "ctx" dla piece'ów, wykrywa kolizje.

local HexCoord = require(script.Parent.Parent.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local HexGrid = require(script.Parent.Parent.Hex.HexGrid)
type HexGrid = HexGrid.HexGrid

local Molecule = require(script.Parent.Molecule)
type MoleculeData = Molecule.MoleculeData

local SimulationEngine = {}
SimulationEngine.__index = SimulationEngine

-- Program gracza: dla każdego arma, mapa cycleNumber -> instrukcja
export type InstructionProgram = { [string]: { [number]: string } } -- [armId][cycle] = instruction

export type SimulationResult = {
	success: boolean,
	failReason: string?, -- np. "Collision", "OutOfBounds"
	failCycle: number?,
	cyclesRun: number,
	log: { string }, -- historia zdarzeń, do debugowania i do replaya po stronie klienta
}

export type SimulationEngineData = typeof(setmetatable(
	{} :: {
		grid: HexGrid,
		arms: { any }, -- lista pieców typu Arm, w kolejności wykonania
		reactivePieces: { any }, -- Bonder/Glyph - te co reagują pasywnie co cykl (bez instrukcji gracza)
		molecules: { [string]: MoleculeData },
		program: InstructionProgram,
	},
	SimulationEngine
))

-- === Konstruktor ===

function SimulationEngine.new(grid: HexGrid): SimulationEngineData
	local self = setmetatable({
		grid = grid,
		arms = {},
		reactivePieces = {},
		molecules = {},
		program = {},
	}, SimulationEngine)
	return self :: SimulationEngineData
end

-- === Rejestracja elementów przed startem symulacji ===

function SimulationEngine.addArm(self: SimulationEngineData, arm: any)
	table.insert(self.arms, arm)
end

function SimulationEngine.addReactivePiece(self: SimulationEngineData, piece: any)
	table.insert(self.reactivePieces, piece)
end

function SimulationEngine.addMolecule(self: SimulationEngineData, molecule: MoleculeData)
	self.molecules[molecule.id] = molecule
end

function SimulationEngine.setProgram(self: SimulationEngineData, program: InstructionProgram)
	self.program = program
end

-- === Budowa "ctx" przekazywanego do piece:step() ===
-- To jest miejsce gdzie SimulationEngine faktycznie IMPLEMENTUJE kontrakt,
-- który Arm/Bonder/Glyph zakładały że ktoś dostarczy.

function SimulationEngine.buildContext(self: SimulationEngineData): any
	local engine = self

	return {
		getMoleculeAt = function(coord: HexCoord): string?
			for id, mol in pairs(engine.molecules) do
				if mol:occupiesHex(coord) then
					return id
				end
			end
			return nil
		end,

		-- Uwaga: tu NIE sprawdzamy kolizji - to robi runCycle PRZED wywołaniem step(),
		-- więc gdy dotrzemy tutaj, ruch już wiadomo że jest bezpieczny do zatwierdzenia.
		moveMolecule = function(moleculeId: string, move: any)
			local mol = engine.molecules[moleculeId]
			if not mol then
				warn("SimulationEngine: moveMolecule - nieznana molekuła", moleculeId)
				return
			end
			mol:applyMove(move)
		end,

		bondMolecules = function(idA: string, idB: string, hexA: HexCoord, hexB: HexCoord)
			local molA = engine.molecules[idA]
			local molB = engine.molecules[idB]
			if not molA or not molB then
				return
			end
			local merged = Molecule.merge(molA, molB)
			engine.molecules[idA] = nil
			engine.molecules[idB] = nil
			engine.molecules[merged.id] = merged
		end,

		transmuteAtom = function(moleculeId: string, hex: HexCoord, newElement: string)
			local mol = engine.molecules[moleculeId]
			if not mol then
				return
			end
			for _, atom in ipairs(mol.atoms) do
				local rotatedOffset = HexCoord.rotate(atom.offset, mol.rotation)
				local atomHex = HexCoord.add(mol.position, rotatedOffset)
				if HexCoord.equals(atomHex, hex) then
					atom.element = newElement :: any
					break
				end
			end
		end,

		duplicateAtom = function(sourceHex: HexCoord, targetHex: HexCoord)
			-- uproszczone na razie: znajdź element w sourceHex, nadpisz element w targetHex
			local sourceElement: string? = nil
			for _, mol in pairs(engine.molecules) do
				for _, atom in ipairs(mol.atoms) do
					local rotatedOffset = HexCoord.rotate(atom.offset, mol.rotation)
					local atomHex = HexCoord.add(mol.position, rotatedOffset)
					if HexCoord.equals(atomHex, sourceHex) then
						sourceElement = atom.element
					end
				end
			end
			if not sourceElement then
				return
			end
			for _, mol in pairs(engine.molecules) do
				for _, atom in ipairs(mol.atoms) do
					local rotatedOffset = HexCoord.rotate(atom.offset, mol.rotation)
					local atomHex = HexCoord.add(mol.position, rotatedOffset)
					if HexCoord.equals(atomHex, targetHex) then
						atom.element = sourceElement :: any
					end
				end
			end
		end,

		unbondAt = function(hexA: HexCoord, hexB: HexCoord)
			-- TODO: implementacja usuwania wiązania i ewentualnego splitu molekuły na dwie
			warn("unbondAt: split molekuły jeszcze nie zaimplementowany")
		end,
	}
end

-- === Sprawdzenie kolizji PRZED wykonaniem ruchu (kluczowe dla poprawności symulacji) ===
-- Sprawdza czy hexy docelowe ruchu są zajęte przez COKOLWIEK innego niż sama poruszana molekuła

function SimulationEngine.checkMoveCollision(
	self: SimulationEngineData,
	molecule: MoleculeData,
	move: any
): boolean
	local targetHexes = molecule:getWorldHexesAfterMove(move)

	for _, hex in ipairs(targetHexes) do
		-- kolizja z nieruchomymi piecami na planszy (Arm base, Track, Bonder...)
		if self.grid:isOccupied(hex) then
			return true
		end
		-- kolizja z INNĄ molekułą (nie tą, którą właśnie ruszamy)
		for id, otherMol in pairs(self.molecules) do
			if id ~= molecule.id and otherMol:occupiesHex(hex) then
				return true
			end
		end
		if not self.grid:isInBounds(hex) then
			return true
		end
	end

	return false
end

-- === Wykonanie JEDNEGO cyklu symulacji ===

function SimulationEngine.runCycle(self: SimulationEngineData, cycleNumber: number, log: { string }): (boolean, string?)
	local ctx = self:buildContext()

	-- Owijamy ctx.moveMolecule tak, żeby dodatkowo sprawdzał kolizję PRZED zatwierdzeniem
	local originalMoveMolecule = ctx.moveMolecule
	local collisionDetected = false

	ctx.moveMolecule = function(moleculeId: string, move: any)
		local mol = self.molecules[moleculeId]
		if not mol then
			return
		end
		if self:checkMoveCollision(mol, move) then
			collisionDetected = true
			table.insert(log, ("Cykl %d: KOLIZJA przy ruchu molekuły %s"):format(cycleNumber, moleculeId))
			return
		end
		originalMoveMolecule(moleculeId, move)
	end

	-- 1. Wykonaj instrukcje ramion (w kolejności rejestracji - id rosnąco)
	for _, arm in ipairs(self.arms) do
		local instruction = self.program[arm.id] and self.program[arm.id][cycleNumber]
		if instruction then
			arm:step(instruction, ctx)
			table.insert(log, ("Cykl %d: Arm %s wykonuje %s"):format(cycleNumber, arm.id, instruction))
		end

		if collisionDetected then
			return false, "Collision"
		end
	end

	-- 2. Wykonaj reaktywne piece (Bonder, Glyph) - zawsze na końcu cyklu, po ruchu ramion
	for _, piece in ipairs(self.reactivePieces) do
		piece:step(ctx)
	end

	return true
end

-- === Uruchomienie pełnej symulacji do zadanej liczby cykli (albo do końca programu) ===

function SimulationEngine.run(self: SimulationEngineData, maxCycles: number): SimulationResult
	local log = {}

	for cycle = 1, maxCycles do
		local ok, failReason = self:runCycle(cycle, log)
		if not ok then
			return {
				success = false,
				failReason = failReason,
				failCycle = cycle,
				cyclesRun = cycle - 1,
				log = log,
			}
		end
	end

	return {
		success = true,
		failReason = nil,
		failCycle = nil,
		cyclesRun = maxCycles,
		log = log,
	}
end

return SimulationEngine