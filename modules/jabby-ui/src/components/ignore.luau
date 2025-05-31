local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage.roblox_packages.vide)

local create = vide.create

return function(p: {[any]: any})
    return create ("Folder" :: "Folder")(p)
end