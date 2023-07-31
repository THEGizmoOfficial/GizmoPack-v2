--[[
    @Author: https://github.com/Fernando-A-Rocha (Edit by THEGizmo)
]]--

local resourceName = "editor_engine"

_getElementModel = getElementModel
_setElementModel = setElementModel
_createObject = createObject

function getElementModel(...)
	return exports[resourceName]:getElementModel(...)
end

function setElementModel(...)
	return exports[resourceName]:setElementModel(...)
end

function createObject(...)
	return exports[resourceName]:createObject(...)
end