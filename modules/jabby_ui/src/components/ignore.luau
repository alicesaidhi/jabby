local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local create = vide.create

return function(p: {[any]: any})
    return create ("Folder" :: "Folder")(p)
end