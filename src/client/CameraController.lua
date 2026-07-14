--!strict
-- CameraController.lua
-- Handles the top-down board camera for puzzle gameplay.
-- Supports default centering and mouse wheel zoom.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CameraController = {}

local DEFAULT_FIELD_OF_VIEW = 48

local MIN_HEIGHT = 45
local MAX_HEIGHT = 260
local ZOOM_STEP = 10

local currentRadius = 8
local currentHeight = 120
local zoomConnection: RBXScriptConnection? = nil

local function getCamera(): Camera?
	return Workspace.CurrentCamera
end

local function getDefaultHeight(radius: number): number
	return math.clamp(100 + radius * 8, MIN_HEIGHT, MAX_HEIGHT)
end

local function applyCamera()
	local camera = getCamera()

	if not camera then
		return
	end

	local cameraPosition = Vector3.new(0, currentHeight, 0)
	local targetPosition = Vector3.new(0, 0, 0)

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = DEFAULT_FIELD_OF_VIEW
	camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition, Vector3.new(0, 0, -1))
end

function CameraController.focusOnBoard(radius: number)
	currentRadius = radius
	currentHeight = getDefaultHeight(radius)
	applyCamera()
end

function CameraController.centerOnBoard()
	currentHeight = getDefaultHeight(currentRadius)
	applyCamera()
end

function CameraController.zoomIn()
	currentHeight = math.clamp(currentHeight - ZOOM_STEP, MIN_HEIGHT, MAX_HEIGHT)
	applyCamera()
end

function CameraController.zoomOut()
	currentHeight = math.clamp(currentHeight + ZOOM_STEP, MIN_HEIGHT, MAX_HEIGHT)
	applyCamera()
end

function CameraController.enableZoom()
	if zoomConnection then
		return
	end

	zoomConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end

		if input.Position.Z > 0 then
			CameraController.zoomIn()
		elseif input.Position.Z < 0 then
			CameraController.zoomOut()
		end
	end)
end

function CameraController.disableZoom()
	if zoomConnection then
		zoomConnection:Disconnect()
		zoomConnection = nil
	end
end

function CameraController.resetToDefault()
	CameraController.disableZoom()

	local camera = getCamera()

	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
end

return CameraController