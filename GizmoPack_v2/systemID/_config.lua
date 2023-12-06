--[[
    @Author: https://github.com/Fernando-A-Rocha (Edit by THEGizmo)
]]--

dataNames = {
	ped = "skinCustomID",
	vehicle = "vehicleCustomID",
	object = "objectCustomID",
}

dataNames.player = dataNames.ped
dataNames.pickup = dataNames.object

baseDataName = "baseCustomID"

STARTUP_VERIFICATIONS = true

LINKED_RESOURCES = {
	--{name = "resource_name", start = true, stop = true},
}

SHOW_DOWNLOADING = true
KICK_ON_DOWNLOAD_FAILS = true
DOWNLOAD_MAX_TRIES = 3

ENABLE_NANDOCRYPT = true
NANDOCRYPT_EXT = ".gp"

ASYNC_PRIORITY = "normal"

DATANAME_VEH_HANDLING = "customID:savedHandling"
DATANAME_VEH_UPGRADES = "customID:savedUpgrades"
DATANAME_VEH_PAINTJOB = "customID:savedPaintjob"