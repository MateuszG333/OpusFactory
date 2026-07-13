--!strict
-- Arm.lua
-- Ramię - chwyta, obraca, przesuwa i puszcza cząsteczki (atomy/molekuły).
-- Najbardziej złożony piece: łączy rotację, ruch po torze i zmianę długości (piston arm).

local HexCoord = require(script.Parent.Parent.Hex.HexCoord)
type HexCoord = HexCoord.HexCoord

local PieceBase = require(script.Parent.PieceBase)
type Piece = PieceBase.Piece

local Track = require(script.Parent.Track)
type TrackData = Track.TrackData

local Arm = setmetatable({}, { __index = PieceBase })
Arm.__index = Arm

export type ArmKind = "Arm" | "DoubleArm" | "TripleArm" | "HexArm" | "PistonArm"

export type Instruction =
	"Grab"
	| "Drop"
	| "RotateCW"
	| "RotateCCW"
	| "Extend"
	| "Retract"
	| "Forward"
	| "Backward"
	| "Wait"

export type ArmData = typeof(setmetatable(
	{} :: {
		armKind: ArmKind,
		length: number, -- 1 = normalna długość, >1 dla PistonArm po Extend
		maxLength: number, -- limit dla PistonArm
		track: TrackData?, -- opcjonalny tor, po którym baza ramienia się przesuwa
		grabbedMoleculeId: string?, -- id molekuły aktualnie trzymanej (nil = puste)
	},
	Arm
))

-- === Konstruktor ===

function Arm.new(position: HexCoord, rotation: number, armKind: ArmKind?, track: TrackData?): ArmData
	local base = PieceBase.new("Arm", position, rotation)
	local self = setmetatable(base, Arm) :: any

	self.armKind = armKind or "Arm"
	self.length = 1
	self.maxLength = if self.armKind == "PistonArm" then 3 else 1
	self.track = track
	self.grabbedMoleculeId = nil

	return self :: ArmData
end

-- === Footprint - baza ramienia zajmuje tylko swój własny hex ===
-- (hex, który ramię "chwyta" na końcu, NIE jest blokowany na stałe - to dynamiczny zasięg)

function Arm.getFootprint(self: ArmData): { HexCoord }
	return { self.position }
end

-- === Zasięg ramienia - który hex aktualnie "chwyta" na końcu ===

local function scaledDirection(direction: number, length: number): HexCoord
	local dir = HexCoord.direction(direction)
	return HexCoord.new(dir.x * length, dir.y * length, dir.z * length)
end

function Arm.getReachHexes(self: ArmData): { HexCoord }
	-- Arm: 1 hex; DoubleArm: 2 przeciwległe; TripleArm: 3 co 120°; HexArm: wszystkie 6
	local reachCount = ({
		Arm = 1,
		PistonArm = 1,
		DoubleArm = 2,
		TripleArm = 3,
		HexArm = 6,
	})[self.armKind] or 1

	local step = 6 / reachCount
	local hexes = {}
	for i = 0, reachCount - 1 do
		local dir = (self.rotation + i * step) % 6
		local offset = scaledDirection(dir, self.length)
		table.insert(hexes, HexCoord.add(self.position, offset))
	end
	return hexes
end

-- === Instrukcje - każda mutuje stan ramienia i/lub trzymanej molekuły przez ctx ===
-- ctx to SimulationContext dostarczany przez SimulationEngine, oczekiwany interfejs:
--   ctx.grid: HexGrid
--   ctx.getMoleculeAt(coord): string? (zwraca id molekuły na danym hexie, jeśli jest)
--   ctx.moveMolecule(id, deltaOrRotation): przesuwa/obraca atomy molekuły o danej id

function Arm.step(self: ArmData, instruction: Instruction, ctx: any)
	if instruction == "Grab" then
		self:doGrab(ctx)
	elseif instruction == "Drop" then
		self:doDrop(ctx)
	elseif instruction == "RotateCW" then
		self:doRotate(1, ctx)
	elseif instruction == "RotateCCW" then
		self:doRotate(-1, ctx)
	elseif instruction == "Extend" then
		self:doExtend(ctx)
	elseif instruction == "Retract" then
		self:doRetract(ctx)
	elseif instruction == "Forward" then
		self:doTrackMove(1, ctx)
	elseif instruction == "Backward" then
		self:doTrackMove(-1, ctx)
	elseif instruction == "Wait" then
		-- nic nie rób
	end
end

function Arm.doGrab(self: ArmData, ctx: any)
	if self.grabbedMoleculeId then
		return -- już coś trzyma, Grab nie robi nic (zgodnie z zasadami Opus Magnum)
	end
	local reach = self:getReachHexes()
	-- prosty Arm chwyta z pierwszego trafionego hexa; multi-arm chwyta z wszystkich naraz
	for _, hex in ipairs(reach) do
		local moleculeId = ctx.getMoleculeAt(hex)
		if moleculeId then
			self.grabbedMoleculeId = moleculeId
			break
		end
	end
end

function Arm.doDrop(self: ArmData, ctx: any)
	self.grabbedMoleculeId = nil
	-- molekuła zostaje po prostu tam gdzie jest - fizycznie "leży" na planszy
end

function Arm.doRotate(self: ArmData, steps: number, ctx: any)
	self:rotate(steps) -- odziedziczone z PieceBase - zmienia self.rotation

	if self.grabbedMoleculeId then
		ctx.moveMolecule(self.grabbedMoleculeId, {
			kind = "rotate",
			center = self.position,
			steps = steps,
		})
	end
end

function Arm.doExtend(self: ArmData, ctx: any)
	if self.armKind ~= "PistonArm" then
		return -- tylko PistonArm może się wydłużać
	end
	if self.length >= self.maxLength then
		return
	end

	local oldReach = self:getReachHexes()
	self.length += 1
	local newReach = self:getReachHexes()

	if self.grabbedMoleculeId then
		local delta = HexCoord.sub(newReach[1], oldReach[1])
		ctx.moveMolecule(self.grabbedMoleculeId, { kind = "translate", delta = delta })
	end
end

function Arm.doRetract(self: ArmData, ctx: any)
	if self.armKind ~= "PistonArm" then
		return
	end
	if self.length <= 1 then
		return
	end

	local oldReach = self:getReachHexes()
	self.length -= 1
	local newReach = self:getReachHexes()

	if self.grabbedMoleculeId then
		local delta = HexCoord.sub(newReach[1], oldReach[1])
		ctx.moveMolecule(self.grabbedMoleculeId, { kind = "translate", delta = delta })
	end
end

function Arm.doTrackMove(self: ArmData, direction: number, ctx: any)
	if not self.track then
		return -- ramię nie jest na torze, Forward/Backward nic nie robi
	end

	local nextPos = self.track:nextPosition(self.position, direction)
	if not nextPos then
		return -- koniec toru
	end

	local delta = HexCoord.sub(nextPos, self.position)
	self.position = nextPos

	if self.grabbedMoleculeId then
		ctx.moveMolecule(self.grabbedMoleculeId, { kind = "translate", delta = delta })
	end
end

return Arm