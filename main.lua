local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local flying = false
local speed = 60

local bv
local bg

local keys = {
	W = false,
	A = false,
	S = false,
	D = false,
	Q = false,
	E = false
}

UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if keys[i.KeyCode
