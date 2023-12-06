--[[
    @Author: https://github.com/Fernando-A-Rocha (Edit by THEGizmo)
]]--

local resourceName = "GizmoPack_v2"

_getElementModel = getElementModel
_setElementModel = setElementModel
_createObject = createObject
_createVehicle = createVehicle
_createPed = createPed
_createPickup = createPickup
_setPickupType = setPickupType

local resources = {}
local isClientFile = isElement(localPlayer)
local dataNames = {
	['object'] = exports[resourceName]:getDataNameFromType('object'),
	['vehicle'] = exports[resourceName]:getDataNameFromType('vehicle'),
	['ped'] = exports[resourceName]:getDataNameFromType('ped'),
	['player'] = exports[resourceName]:getDataNameFromType('player'),
	['pickup'] = exports[resourceName]:getDataNameFromType('pickup'),
}

local baseDataName = exports[resourceName]:getBaseModelDataName()

function setElementResource(element, theResource)
	if isElement(element) then
		theResource = theResource or resource
		if type(resources[theResource]) ~= "table" then
			resources[theResource] = {}
		end
		table.insert(resources[theResource], element)
		setElementParent(element, getResourceDynamicElementRoot(theResource))
	end
end

local function outputCustomError(errorCode, id, elementType)
	if errorCode == "INVALID_MODEL" then
		outputDebugString("[editor_engine] ID "..id.." doesn't exist", 4, 255,200,0)
	elseif errorCode == "WRONG_MOD" then
		outputDebugString("[editor_engine] Mod ID "..id.." is not a "..elementType.." model", 4, 255,200,0)
	else
		outputDebugString("[editor_engine] Unknown error", 4, 255,200,0)
	end
end

local function createElementWithModel(elementType, modelid, ...)
	if elementType == "object" then
		return _createObject(modelid, ...)
	elseif elementType == "vehicle" then
		return _createVehicle(modelid, ...)
	elseif elementType == "ped" then
		return _createPed(modelid, ...)
	elseif elementType == "pickup" then
		local x, y, z, respawnTime, ammo = unpack({...})
		return _createPickup(x, y, z, 3, modelid, respawnTime, ammo)
	end
	return false
end

local function createElementSafe(elementType, id, ...)

	local baseModel, isCustom = exports[resourceName]:checkModelID(id, elementType)
	if tonumber(baseModel) then
		
		local element = createElementWithModel(elementType, baseModel, ...)
		if not isElement(element) then
			return false
		end

		if isCustom then
			setElementData(element, dataNames[elementType], id, not isClientFile)
			setElementData(element, baseDataName, baseModel, not isClientFile)
		end
		
		return element
	end

	outputCustomError(baseModel, id, elementType)
	return false
end

function createObject(id, ...)
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local object = createElementSafe("object", id, ...)
	setElementResource(object, sourceResource)
	return object
end

function createVehicle(id, ...)
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local vehicle = createElementSafe("vehicle", id, ...)
	setElementResource(vehicle, sourceResource)
	return vehicle
end

function createPed(id, ...)
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local ped = createElementSafe("ped", id, ...)
	setElementResource(ped, sourceResource)
	return ped
end

function createPickup(x, y, z, theType, id, respawnTime, ammo)
	local pickup
	theType = tonumber(theType)
	if theType and theType == 3 then
		assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
		pickup = createElementSafe("pickup", id, x, y, z, respawnTime, ammo)
	else
		pickup = _createPickup(x, y, z, theType, id, respawnTime, ammo)
	end
	setElementResource(pickup, sourceResource)
	return pickup
end

function setPickupType(thePickup, theType, id, ammo)
    assert(isElement(thePickup), "Invalid element passed: "..tostring(thePickup))
    local elementType = getElementType(thePickup)
    assert(elementType == "pickup",
        "Invalid element type passed: "..tostring(elementType))
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local dataName = dataNames["pickup"]
	theType = tonumber(theType)
	if theType and theType == 3 then
		local baseModel, isCustom = exports[resourceName]:checkModelID(id, elementType)
		if not tonumber(baseModel) then
			outputCustomError(baseModel, id, elementType)
			return false
		end
		if isCustom then
			setElementData(thePickup, baseDataName, baseModel, not isClientFile)
			setElementData(thePickup, dataName, id, not isClientFile)
			return true
		end
	end

	setElementData(thePickup, baseDataName, nil, not isClientFile)
	setElementData(thePickup, dataName, nil, not isClientFile)
	return _setPickupType(thePickup, theType, id, ammo)
end

function getElementModel(element)
	assert(isElement(element), "Invalid element passed: "..tostring(element))
	local et = getElementType(element)
	assert((et == "object" or et == "vehicle" or et == "ped" or et == "player" or et == "pickup"),
		"Invalid element type passed: "..tostring(et))
	return getElementData(element, dataNames[getElementType(element)]) or _getElementModel(element)
end

function setElementModel(element, id)
	assert(isElement(element), "Invalid element passed: "..tostring(element))
	local elementType = getElementType(element)
	assert((elementType == "ped" or elementType == "player" or elementType == "object" or elementType == "vehicle"),
		"Invalid element type passed: "..tostring(elementType))
	assert(tonumber(id), "Non-number ID passed")
	local dataName = dataNames[elementType]

	local baseModel, isCustom = exports[resourceName]:checkModelID(id, elementType)
	if not tonumber(baseModel) then
		outputCustomError(baseModel, id, elementType)
		return false
	end
	
	local currModel = _getElementModel(element)
	if currModel ~= baseModel then
		_setElementModel(element, baseModel)
	end

	if isCustom then
		setElementData(element, baseDataName, baseModel, not isClientFile)
		setElementData(element, dataName, id, not isClientFile)
	
	else
		setElementData(element, baseDataName, nil, not isClientFile)
		setElementData(element, dataName, nil, not isClientFile)
	end

	return true
end

function handleResourceStop(stoppedRes)
	if resources[stoppedRes] then
		for i=1,#resources[stoppedRes] do
			local element = resources[stoppedRes][i]
			if isElement(element) then
				destroyElement(element)
			end
		end
	end
end

if isClientFile then
	addEventHandler("onClientResourceStop", root, handleResourceStop)
else
	addEventHandler("onResourceStop", root, handleResourceStop)
end