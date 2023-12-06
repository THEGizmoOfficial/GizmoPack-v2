--[[
    @Author: https://github.com/Fernando-A-Rocha (Edit by THEGizmo)
]]--

local resourceName = "editor_engine"

_getElementModel = getElementModel
_setElementModel = setElementModel
_createObject = createObject
_createPed = createPed
_createVehicle = createVehicle
_createPickup = createPickup
_setPickupType = setPickupType

function getElementModel(...)
	return exports[resourceName]:getElementModel(...)
end

function setElementModel(...)
	return exports[resourceName]:setElementModel(...)
end

function createObject(...)
	return exports[resourceName]:createObject(...)
end

function createPed(...)
	return exports[resourceName]:createPed(...)
end

function createVehicle(...)
	return exports[resourceName]:createVehicle(...)
end

function createPickup(...)
	return exports[resourceName]:createPickup(...)
end

function setPickupType(...)
	return exports[resourceName]:setPickupType(...)
end