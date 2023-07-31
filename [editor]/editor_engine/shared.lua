--[[
    @Author: https://github.com/Fernando-A-Rocha (Edit by THEGizmo)
]]--

local resourceName = "GizmoPack_v2"

_getElementModel = getElementModel
_setElementModel = setElementModel
_createObject = createObject

local resources = {}
local isClientFile = isElement(localPlayer)
local dataNames = {
	['object'] = exports[resourceName]:getDataNameFromType('object')
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

function getElementModel(element)
	assert(isElement(element), "Invalid element passed: "..tostring(element))
	local et = getElementType(element)
	assert((et == "object"), "Invalid element type passed: "..tostring(et))
	return getElementData(element, dataNames[getElementType(element)]) or _getElementModel(element)
end

function setElementModel(element, id)
	assert(isElement(element), "Invalid element passed: "..tostring(element))
	local elementType = getElementType(element)
	assert((elementType == "object"), "Invalid element type passed: "..tostring(elementType))
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