--!strict
print("[Client] Rojo sync is active on the client.")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainMenu = require(script.Parent.UI.MainMenu)
local LevelSelect = require(script.Parent.UI.LevelSelect)
local HUD = require(script.Parent.UI.HUD)

local BoardController = require(script.Parent.BoardController)
local CameraController = require(script.Parent.CameraController)

local PuzzleDefinitions = require(ReplicatedStorage.Shared.Puzzles.PuzzleDefinitions)

local mainMenuGui: ScreenGui? = nil
local levelSelectGui: ScreenGui? = nil
local hudGui: ScreenGui? = nil

local function destroyHud()
	if hudGui then
		hudGui:Destroy()
		hudGui = nil
	end
end

local function destroyLevelSelect()
	if levelSelectGui then
		levelSelectGui:Destroy()
		levelSelectGui = nil
	end
end

local function destroyMainMenu()
	if mainMenuGui then
		mainMenuGui:Destroy()
		mainMenuGui = nil
	end
end

local function showLevelSelect()
	destroyMainMenu()
	destroyHud()
	BoardController.clear()

	levelSelectGui = LevelSelect.build(function(levelId: number)
		local puzzle = PuzzleDefinitions.getById(levelId)

		if not puzzle then
			warn("Missing puzzle definition for level:", levelId)
			return
		end

		print("Selected level:", levelId)

		destroyLevelSelect()

		BoardController.loadPuzzle(puzzle)

		local visualRadius = math.max(18, puzzle.gridRadius + 8)
		CameraController.focusOnBoard(visualRadius)
		CameraController.enableZoom()
		CameraController.enablePan()

		hudGui = HUD.build(puzzle, function()
			destroyHud()
			BoardController.clear()
			CameraController.resetToDefault()
			showLevelSelect()
		end, function()
			CameraController.centerOnBoard()
		end)

		print("[Client] Puzzle board loaded.")
	end, function()
		destroyLevelSelect()
		BoardController.clear()
		CameraController.resetToDefault()
		showMainMenu()
	end)

	print("[Client] Level select screen built.")
end

function showMainMenu()
	destroyLevelSelect()
	destroyHud()
	BoardController.clear()
	CameraController.resetToDefault()

	mainMenuGui = MainMenu.build({
		onTutorial = function()
			if mainMenuGui then
				MainMenu.showPlaceholder(
					mainMenuGui,
					"Tutorial",
					"Tutorial is not connected yet. Later, this will teach the grid, arms, instructions, bonding, and outputs."
				)
			end
		end,

		onDailyChallenge = function()
			if mainMenuGui then
				MainMenu.showPlaceholder(
					mainMenuGui,
					"Daily Challenge",
					"Daily Challenge is not connected yet. Later, this will load one shared puzzle of the day for all players."
				)
			end
		end,

		onLevelSelect = function()
			showLevelSelect()
		end,

		onGlobalLeaderboard = function()
			if mainMenuGui then
				MainMenu.showPlaceholder(
					mainMenuGui,
					"Global Leaderboard",
					"Global Leaderboard is not connected yet. Later, this will show the best solutions by cycles, cost, and area."
				)
			end
		end,
	})
end

showMainMenu()

print("[Client] Main menu built.")	