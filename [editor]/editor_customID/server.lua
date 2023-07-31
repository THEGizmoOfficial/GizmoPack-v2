--[[
    @Author: https://github.com/Fernando-A-Rocha (Edit by THEGizmo)
]]--

local resourceName = "GizmoPack_v2"

commandName = "editor_update"

function canUseTool(player)
    return hasObjectPermissionTo(player, "command.start", false) and hasObjectPermissionTo(player, "command.stop", false)
end

local EDITOR_GUI_XML_GROUP_NAMES = {
    ["objects"] = "GizmoPack v2"
}

local waitingEditorStop = nil

local function getModelGroupNames(rootChildrenNodes, theType)
    local groupNames = {} -- [model] = name
    local function getGroupNames(node)
        if xmlNodeGetName(node) == "group" then
            local children = xmlNodeGetChildren(node)
            if children then
                local parentName = "Walls, floors and others" -- xmlNodeGetAttribute(node, "name")
                if parentName then
                    for i, child in ipairs(children) do
                        local model = tonumber(xmlNodeGetAttribute(child, "model"))
                        if model then
                            if groupNames[model] then
                                -- outputDebugString("Model "..model.." is already in group "..groupNames[model]..", skipping.", 2)
                                return
                            end
                            groupNames[model] = parentName
                        end
                        if xmlNodeGetName(child) == "group" then
                            getGroupNames(child)
                        end
                    end
                end
            end
        end
    end
    for i, node in ipairs(rootChildrenNodes) do
        getGroupNames(node)
    end
    return groupNames
end

local function updateEditorGUIFiles()
    local OBJECTS_PATH = ":editor_gui/client/browser/objects.xml"

    local groupNames = {}
    if not EDITOR_GUI_XML_GROUP_NAMES then
        return false, "The editor GUI group names are not defined."
    end
    if not EDITOR_GUI_XML_GROUP_NAMES["objects"] then
        return false, "The editor GUI object group name is not defined."
    end
    groupNames["objects"] = EDITOR_GUI_XML_GROUP_NAMES["objects"]

    if not fileExists(OBJECTS_PATH) then
        return false, "The editor GUI files could not be found."
    end

    local allMods = exports[resourceName]:getModList()
    if not allMods then
        return false, "Failed to get the mod list."
    end

    local modsList = {
        ["objects"] = {}
    }

    for elementType, mods in pairs(allMods) do
        if type(elementType) ~= "string" or type(mods) ~= "table" then
            return false, "The mod list is not valid."
        end
        for i, mod in ipairs(mods) do
            if type(mod) ~= "table" then
                return false, "Mod #"..i.." is not a table."
            end
            local modID = mod.id
            local modBaseID = mod.base_id
            local modName = mod.name

            if type(modID) ~= "number" or type(modBaseID) ~= "number" or type(modName) ~= "string" then
                return false, "Mod #"..i.." is not valid."
            end

            if elementType == "object" then
                table.insert(modsList["objects"], {id = modID, base_id = modBaseID, name = modName})
            end
        end
    end

    local function addNewModels(theType)
        
        local path = OBJECTS_PATH
        
        local xmlRoot = xmlLoadFile(path)
        if not xmlRoot then
            return false, "Failed to load file: "..path
        end
        local groupNodes = xmlNodeGetChildren(xmlRoot)
        if not groupNodes then
            return false, "Failed to get the group nodes from file: "..path
        end
        for i, groupNode in ipairs(groupNodes) do
            local groupName = xmlNodeGetAttribute(groupNode, "name")
            if groupName and groupName == groupNames[theType] then
                xmlDestroyNode(groupNode)
                break
            end
        end
        groupNodes = xmlNodeGetChildren(xmlRoot)
        if not groupNodes then
            return false, "Failed to get the group nodes from file: "..path
        end
        local defaultGroupNames = getModelGroupNames(groupNodes, xmlNodeGetAttribute(xmlRoot, "type"))

        local parentGroupNode = xmlCreateChild(xmlRoot, "group")
        xmlNodeSetAttribute(parentGroupNode, "name", groupNames[theType])
        local usedGroupNames = {}
        local usedModelGroupNames = {}
        for i, mod in ipairs(modsList[theType]) do
            local modelBaseID = mod.base_id
            local groupName = defaultGroupNames[modelBaseID]
            if not groupName then
                groupName = "Other"
            end
            if not usedGroupNames[groupName] then
                usedGroupNames[groupName] = true
            end
            usedModelGroupNames[modelBaseID] = groupName
        end
        local usedGroupNodes = {}
        for groupName, _ in pairs(usedGroupNames) do
            local groupNode = xmlCreateChild(parentGroupNode, "group")
            xmlNodeSetAttribute(groupNode, "name", groupName)
            usedGroupNodes[groupName] = groupNode
        end

        local count = 0
        for i, mod in ipairs(modsList[theType]) do
            local modelID = mod.id
            local modelBaseID = mod.base_id
            local modelName = mod.name
            local groupName = usedModelGroupNames[modelBaseID]
            local groupNode = usedGroupNodes[groupName]
            local tagName = string.sub(theType, 1, -2)
            local modelNode = xmlCreateChild(groupNode, tagName)
            xmlNodeSetAttribute(modelNode, "model", modelID)
            xmlNodeSetAttribute(modelNode, "base_model", modelBaseID)
            xmlNodeSetAttribute(modelNode, "name", modelName)
            xmlNodeSetAttribute(modelNode, "keywords", '')
            count = count + 1
        end

        xmlSaveFile(xmlRoot)
        xmlUnloadFile(xmlRoot)

        return count
    end

    local theTypeCounts = {}
    for theType, _ in pairs(modsList) do
        local count, errorMessage = addNewModels(theType)
        if not count then
            return false, errorMessage
        end

        theTypeCounts[theType] = count
    end

    return theTypeCounts
end

function editorGuiStopped()
    if not waitingEditorStop then return end

    setTimer(function()

        local thePlayer, cmd = waitingEditorStop[1], waitingEditorStop[2]
        waitingEditorStop = nil

        if thePlayer~="SYSTEM" and isElement(thePlayer) then
            updateEditorNewModels(thePlayer, cmd)
        else
            updateEditorNewModels()
        end

    end, 50, 1)
end

function updateEditorNewModels(thePlayer, cmd)
    if (waitingEditorStop ~= nil) then
        if isElement(thePlayer) then
            outputChatBox("Please wait for the previous editor to stop.", thePlayer, 255, 22, 22)
        end
        return 
    end

    local editor = getResourceFromName("editor")
    if not editor then
        if isElement(thePlayer) then
            outputChatBox("The 'editor' resource could not be found.", thePlayer, 255, 22, 22)
        end
        return
    end

    local editor_gui = getResourceFromName("editor_gui")
    if not editor_gui then
        if isElement(thePlayer) then
            outputChatBox("The 'editor_gui' resource could not be found.", thePlayer, 255, 22, 22)
        end
        return
    end
    
    if getResourceState(editor_gui) == "running" then
        if getResourceState(editor) ~= "running" then
            if isElement(thePlayer) then
                outputChatBox("Unexpected: 'editor_gui' is running but 'editor' is not.", thePlayer, 255, 22, 22)
            else
                outputDebugString("Unexpected: 'editor_gui' is running but 'editor' is not.", 1)
            end
            return
        end
        local editorGuiRoot = getResourceRootElement(editor_gui)
        addEventHandler("onResourceStop", editorGuiRoot, editorGuiStopped)

        if isElement(thePlayer) then
            waitingEditorStop = {thePlayer, cmd}
        else
            waitingEditorStop = {"SYSTEM"}
        end

        if not stopResource(editor) then

            if isElement(thePlayer) then
                outputChatBox("Failed to stop the 'editor' resource.", thePlayer, 255, 22, 22)
                outputChatBox("  Try to stop the Map Editor manually (/stop editor).", thePlayer, 255, 22, 22)
            else
                outputDebugString("Failed to stop the 'editor' resource.", 1)
            end
            
            removeEventHandler("onResourceStop", editorGuiRoot, editorGuiStopped)
            waitingEditorStop = nil
            return
        end
        for _, player in ipairs(getElementsByType("player")) do
            playSoundFrontEnd(player, 40)
            outputChatBox("[Editor] The editor resources are now restarting to apply changes...", player, 255, 255, 22)
        end
        return
    end

    local result, reason = updateEditorGUIFiles()
    if not result then
        if isElement(thePlayer) then
            outputChatBox("Failed to update the editor GUI files: "..reason, thePlayer, 255, 22, 22)
        else
            outputDebugString("Failed to update the editor GUI files: "..reason, 1)
        end
        return
    end

    if isElement(thePlayer) then
        outputChatBox("The editor GUI files have been updated.", thePlayer, 22, 255, 22)

        local added = {}
        for theType, count in pairs(result) do
            added[#added+1] = count.." new "..theType
        end
        outputChatBox("  Added: "..(table.concat(added, ", ")), thePlayer, 222, 222, 222)
    else
        outputDebugString("Updated the editor GUI files:", 3)
        outputDebugString(inspect(result), 3)
    end

    local editorState = getResourceState(editor)
    if editorState == "loaded" then
        if not startResource(editor, true) then
            if isElement(thePlayer) then
                outputChatBox("Failed to start the resource 'editor'.", thePlayer, 255, 22, 22)
            else
                outputDebugString("Failed to start the resource 'editor'.", 1)
            end
            return 
        end
    else
        if isElement(thePlayer) then
            outputChatBox("The 'editor' resource is currently "..editorState..".", thePlayer, 255, 255, 22)
            outputChatBox("  Try to start the Map Editor manually (/start editor).", thePlayer, 255, 255, 22)
        else
            outputDebugString("The 'editor' resource is currently "..editorState..".", 2)
        end
    end
end
addEventHandler("onResourceStart", resourceRoot, updateEditorNewModels)

function newModelsEditorCmd(thePlayer, cmd)
    if not canUseTool(thePlayer) then
        return outputChatBox("You don't have permission to use /"..cmd..".", thePlayer, 255, 22, 22)
    end
    updateEditorNewModels(thePlayer, cmd)
end
addCommandHandler(commandName, newModelsEditorCmd, false, false)