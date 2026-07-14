--!strict
-- PuzzleDefinitions.lua
-- Central database for handcrafted puzzle definitions.
-- This module is pure data + deterministic helper functions.
-- It does not depend on UI, rendering, player state, or Roblox services.

local PuzzleDefinitions = {}

export type Difficulty = "Easy" | "Medium" | "Hard" | "Expert"

export type Element =
	"Salt"
	| "Water"
	| "Fire"
	| "Earth"
	| "Air"
	| "Vitae"
	| "Mors"
	| "Quicksilver"
	| "Gold"
	| "Silver"
	| "Copper"
	| "Iron"
	| "Tin"
	| "Lead"

export type PieceType =
	"Arm"
	| "Track"
	| "Bonder"
	| "Glyph"
	| "Input"
	| "Output"

export type HexPosition = {
	x: number,
	y: number,
	z: number,
}

export type AtomPattern = {
	element: Element,
	position: HexPosition,
}

export type BondPattern = {
	fromIndex: number,
	toIndex: number,
}

export type MoleculePattern = {
	atoms: { AtomPattern },
	bonds: { BondPattern },
}

export type StarThresholds = {
	cycles: number,
	cost: number,
	area: number,
}

export type PuzzleMetrics = {
	threeStars: StarThresholds,
	twoStars: StarThresholds,
	oneStar: StarThresholds,
}

export type PuzzleDefinition = {
	id: number,
	name: string,
	description: string,

	-- Hand-authored display difficulty.
	-- This is what the UI should show by default.
	difficulty: Difficulty,

	-- Used by campaign progression.
	unlockedByDefault: boolean,

	-- Board size in hex radius.
	gridRadius: number,

	-- Pieces the player is allowed to use in this puzzle.
	availablePieces: { PieceType },

	-- Input/output molecule patterns.
	inputs: { MoleculePattern },
	outputs: { MoleculePattern },

	-- Optional scoring targets.
	metrics: PuzzleMetrics,

	-- Optional tags used by UI, analytics, or future filtering.
	tags: { string },
}

local PUZZLES: { PuzzleDefinition } = {
	{
		id = 1,
		name = "First Mechanism",
		description = "Move a single salt atom from the input to the output.",
		difficulty = "Easy",
		unlockedByDefault = true,
		gridRadius = 4,

		availablePieces = {
			"Arm",
			"Input",
			"Output",
		},

		inputs = {
			{
				atoms = {
					{
						element = "Salt",
						position = { x = -2, y = 2, z = 0 },
					},
				},
				bonds = {},
			},
		},

		outputs = {
			{
				atoms = {
					{
						element = "Salt",
						position = { x = 2, y = -2, z = 0 },
					},
				},
				bonds = {},
			},
		},

		metrics = {
			threeStars = {
				cycles = 8,
				cost = 20,
				area = 8,
			},
			twoStars = {
				cycles = 12,
				cost = 26,
				area = 12,
			},
			oneStar = {
				cycles = 18,
				cost = 34,
				area = 18,
			},
		},

		tags = {
			"tutorial",
			"single-atom",
			"movement",
		},
	},

	{
		id = 2,
		name = "Rotation",
		description = "Use arm rotation to move an atom into the correct position.",
		difficulty = "Easy",
		unlockedByDefault = true,
		gridRadius = 4,

		availablePieces = {
			"Arm",
			"Input",
			"Output",
		},

		inputs = {
			{
				atoms = {
					{
						element = "Salt",
						position = { x = -1, y = 1, z = 0 },
					},
				},
				bonds = {},
			},
		},

		outputs = {
			{
				atoms = {
					{
						element = "Salt",
						position = { x = 1, y = -1, z = 0 },
					},
				},
				bonds = {},
			},
		},

		metrics = {
			threeStars = {
				cycles = 10,
				cost = 20,
				area = 9,
			},
			twoStars = {
				cycles = 15,
				cost = 26,
				area = 13,
			},
			oneStar = {
				cycles = 22,
				cost = 34,
				area = 18,
			},
		},

		tags = {
			"tutorial",
			"rotation",
			"single-atom",
		},
	},

	{
		id = 3,
		name = "Bonding",
		description = "Create a simple two-atom molecule using a bonder.",
		difficulty = "Medium",
		unlockedByDefault = false,
		gridRadius = 5,

		availablePieces = {
			"Arm",
			"Bonder",
			"Input",
			"Output",
		},

		inputs = {
			{
				atoms = {
					{
						element = "Salt",
						position = { x = -2, y = 2, z = 0 },
					},
				},
				bonds = {},
			},
			{
				atoms = {
					{
						element = "Water",
						position = { x = -2, y = 1, z = 1 },
					},
				},
				bonds = {},
			},
		},

		outputs = {
			{
				atoms = {
					{
						element = "Salt",
						position = { x = 1, y = -1, z = 0 },
					},
					{
						element = "Water",
						position = { x = 2, y = -2, z = 0 },
					},
				},
				bonds = {
					{
						fromIndex = 1,
						toIndex = 2,
					},
				},
			},
		},

		metrics = {
			threeStars = {
				cycles = 18,
				cost = 35,
				area = 16,
			},
			twoStars = {
				cycles = 26,
				cost = 46,
				area = 22,
			},
			oneStar = {
				cycles = 36,
				cost = 60,
				area = 30,
			},
		},

		tags = {
			"bonding",
			"two-atoms",
			"bonder",
		},
	},

	{
		id = 4,
		name = "Trackwork",
		description = "Use a track to reposition an arm base while carrying an atom.",
		difficulty = "Medium",
		unlockedByDefault = false,
		gridRadius = 5,

		availablePieces = {
			"Arm",
			"Track",
			"Input",
			"Output",
		},

		inputs = {
			{
				atoms = {
					{
						element = "Earth",
						position = { x = -3, y = 3, z = 0 },
					},
				},
				bonds = {},
			},
		},

		outputs = {
			{
				atoms = {
					{
						element = "Earth",
						position = { x = 3, y = -3, z = 0 },
					},
				},
				bonds = {},
			},
		},

		metrics = {
			threeStars = {
				cycles = 20,
				cost = 38,
				area = 18,
			},
			twoStars = {
				cycles = 30,
				cost = 50,
				area = 26,
			},
			oneStar = {
				cycles = 42,
				cost = 66,
				area = 34,
			},
		},

		tags = {
			"track",
			"movement",
			"arm-positioning",
		},
	},

	{
		id = 5,
		name = "Calcification",
		description = "Transform quicksilver into a required metal using a glyph.",
		difficulty = "Hard",
		unlockedByDefault = false,
		gridRadius = 5,

		availablePieces = {
			"Arm",
			"Glyph",
			"Input",
			"Output",
		},

		inputs = {
			{
				atoms = {
					{
						element = "Quicksilver",
						position = { x = -2, y = 2, z = 0 },
					},
				},
				bonds = {},
			},
		},

		outputs = {
			{
				atoms = {
					{
						element = "Lead",
						position = { x = 2, y = -2, z = 0 },
					},
				},
				bonds = {},
			},
		},

		metrics = {
			threeStars = {
				cycles = 24,
				cost = 44,
				area = 20,
			},
			twoStars = {
				cycles = 36,
				cost = 58,
				area = 28,
			},
			oneStar = {
				cycles = 50,
				cost = 76,
				area = 38,
			},
		},

		tags = {
			"glyph",
			"calcification",
			"transmutation",
		},
	},

	{
		id = 6,
		name = "Animismus",
		description = "A complex puzzle involving advanced glyph logic and multi-step planning.",
		difficulty = "Expert",
		unlockedByDefault = false,
		gridRadius = 6,

		availablePieces = {
			"Arm",
			"Track",
			"Bonder",
			"Glyph",
			"Input",
			"Output",
		},

		inputs = {
			{
				atoms = {
					{
						element = "Vitae",
						position = { x = -3, y = 3, z = 0 },
					},
					{
						element = "Mors",
						position = { x = -2, y = 2, z = 0 },
					},
				},
				bonds = {},
			},
		},

		outputs = {
			{
				atoms = {
					{
						element = "Gold",
						position = { x = 2, y = -2, z = 0 },
					},
					{
						element = "Silver",
						position = { x = 3, y = -3, z = 0 },
					},
				},
				bonds = {
					{
						fromIndex = 1,
						toIndex = 2,
					},
				},
			},
		},

		metrics = {
			threeStars = {
				cycles = 48,
				cost = 80,
				area = 32,
			},
			twoStars = {
				cycles = 70,
				cost = 110,
				area = 46,
			},
			oneStar = {
				cycles = 96,
				cost = 150,
				area = 62,
			},
		},

		tags = {
			"expert",
			"glyph",
			"bonding",
			"multi-step",
		},
	},
}

local function countAtoms(puzzle: PuzzleDefinition): number
	local total = 0

	for _, molecule in ipairs(puzzle.outputs) do
		total += #molecule.atoms
	end

	return total
end

local function countBonds(puzzle: PuzzleDefinition): number
	local total = 0

	for _, molecule in ipairs(puzzle.outputs) do
		total += #molecule.bonds
	end

	return total
end

local function hasPiece(puzzle: PuzzleDefinition, pieceType: PieceType): boolean
	for _, availablePiece in ipairs(puzzle.availablePieces) do
		if availablePiece == pieceType then
			return true
		end
	end

	return false
end

local function hasTag(puzzle: PuzzleDefinition, tag: string): boolean
	for _, puzzleTag in ipairs(puzzle.tags) do
		if puzzleTag == tag then
			return true
		end
	end

	return false
end

local function scoreToDifficulty(score: number): Difficulty
	if score <= 5 then
		return "Easy"
	elseif score <= 11 then
		return "Medium"
	elseif score <= 18 then
		return "Hard"
	end

	return "Expert"
end

function PuzzleDefinitions.estimateDifficultyScore(puzzle: PuzzleDefinition): number
	local score = 0

	score += countAtoms(puzzle)
	score += countBonds(puzzle) * 2

	if puzzle.gridRadius >= 5 then
		score += 1
	end

	if puzzle.gridRadius >= 6 then
		score += 2
	end

	if hasPiece(puzzle, "Track") then
		score += 2
	end

	if hasPiece(puzzle, "Bonder") then
		score += 2
	end

	if hasPiece(puzzle, "Glyph") then
		score += 3
	end

	if hasTag(puzzle, "transmutation") then
		score += 2
	end

	if hasTag(puzzle, "multi-step") then
		score += 3
	end

	if hasTag(puzzle, "expert") then
		score += 4
	end

	return score
end

function PuzzleDefinitions.estimateDifficulty(puzzle: PuzzleDefinition): Difficulty
	return scoreToDifficulty(PuzzleDefinitions.estimateDifficultyScore(puzzle))
end

function PuzzleDefinitions.getDisplayDifficulty(puzzle: PuzzleDefinition): Difficulty
	return puzzle.difficulty
end

function PuzzleDefinitions.getAll(): { PuzzleDefinition }
	return PUZZLES
end

function PuzzleDefinitions.getById(id: number): PuzzleDefinition?
	for _, puzzle in ipairs(PUZZLES) do
		if puzzle.id == id then
			return puzzle
		end
	end

	return nil
end

function PuzzleDefinitions.getUnlockedByDefault(): { PuzzleDefinition }
	local result = {}

	for _, puzzle in ipairs(PUZZLES) do
		if puzzle.unlockedByDefault then
			table.insert(result, puzzle)
		end
	end

	return result
end

function PuzzleDefinitions.isUnlockedByDefault(id: number): boolean
	local puzzle = PuzzleDefinitions.getById(id)

	if not puzzle then
		return false
	end

	return puzzle.unlockedByDefault
end

return PuzzleDefinitions