--!strict
-- CameraController.lua
-- Handles the top-down board camera for puzzle gameplay.
-- Supports default centering and mouse wheel zoom.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local CameraController = {}

local DEFAULT_FIELD_OF_VIEW = 48

local MIN_HEIGHT = 45
local MAX_HEIGHT = 260
local ZOOM_STEP = 10

local currentRadius = 8
local currentHeight = 120
local zoomConnection: RBXScriptConnection? = nil

local HEX_SIZE_APPROX = 4
local PAN_SPEED = 0.6

local panOffsetX = 0
local panOffsetZ = 0
local isPanning = false
local lastPanMousePos: Vector2? = nil
local panBeginConnection: RBXScriptConnection? = nil
local panMoveConnection: RBXScriptConnection? = nil
local panEndConnection: RBXScriptConnection? = nil

local function isPointerOverUI(position: Vector2): boolean
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return false
	end
	local hits = playerGui:GetGuiObjectsAtPosition(position.X, position.Y)
	return #hits > 0
end

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

	local cameraPosition = Vector3.new(panOffsetX, currentHeight, panOffsetZ)
	local targetPosition = Vector3.new(panOffsetX, 0, panOffsetZ)

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = DEFAULT_FIELD_OF_VIEW
	camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition, Vector3.new(0, 0, -1))
end

local function clampPan()
	local maxDistance = currentRadius * HEX_SIZE_APPROX * 0.85
	local offset = Vector3.new(panOffsetX, 0, panOffsetZ)

	if offset.Magnitude > maxDistance then
		offset = offset.Unit * maxDistance
		panOffsetX = offset.X
		panOffsetZ = offset.Z
	end
end

function CameraController.focusOnBoard(radius: number)
	currentRadius = radius
	currentHeight = getDefaultHeight(radius)
	panOffsetX = 0
	panOffsetZ = 0
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

		if isPointerOverUI(UserInputService:GetMouseLocation()) then
			return
		end

		if input.Position.Z > 0 then
			CameraController.zoomIn()
		elseif input.Position.Z < 0 then
			CameraController.zoomOut()
		end
	end)
end

function CameraController.enablePan()
	if panBeginConnection then
		return
	end

	panBeginConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.MouseButton2 then
			return
		end
		if gameProcessed then
			return
		end
		if isPointerOverUI(UserInputService:GetMouseLocation()) then
			return
		end

		isPanning = true
		lastPanMousePos = UserInputService:GetMouseLocation()
	end)

	panMoveConnection = UserInputService.InputChanged:Connect(function(input)
		if not isPanning then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local camera = getCamera()
		if not camera or not lastPanMousePos then
			return
		end

		local currentPos = UserInputService:GetMouseLocation()
		local delta = currentPos - lastPanMousePos
		lastPanMousePos = currentPos

		local rightVector = camera.CFrame.RightVector
		local upVector = camera.CFrame.UpVector
		local worldDelta = (rightVector * -delta.X + upVector * delta.Y) * PAN_SPEED

		panOffsetX += worldDelta.X
		panOffsetZ += worldDelta.Z

		clampPan()
		applyCamera()
	end)

	panEndConnection = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isPanning = false
			lastPanMousePos = nil
		end
	end)
end

function CameraController.disablePan()
	isPanning = false
	lastPanMousePos = nil

	if panBeginConnection then
		panBeginConnection:Disconnect()
		panBeginConnection = nil
	end
	if panMoveConnection then
		panMoveConnection:Disconnect()
		panMoveConnection = nil
	end
	if panEndConnection then
		panEndConnection:Disconnect()
		panEndConnection = nil
	end
end

function CameraController.disableZoom()
	if zoomConnection then
		zoomConnection:Disconnect()
		zoomConnection = nil
	end
end

function CameraController.resetToDefault()
	CameraController.disableZoom()
	CameraController.disablePan()

	panOffsetX = 0
	panOffsetZ = 0

	local camera = getCamera()

	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
end

return CameraController