-- sv_helicam.lua - Server side
-- Created by Rémi.L (https://steamcommunity.com/id/lilian24)

util.AddNetworkString("SendLicensePlate")
util.AddNetworkString("RequestVehiclePlate")

local PLATE = LL_PLATES_SYSTEM or {}

net.Receive("RequestVehiclePlate", function(len, ply)
    local player = net.ReadEntity()
    local vehicle = net.ReadEntity()

    if IsValid(player) and IsValid(vehicle) then
        PLATE:GetLicensePlate(player, vehicle, function(err, plate)
            if not err then
                net.Start("SendLicensePlate")
                net.WriteString(plate)
                net.Send(player)
            end
        end)
    end
end)
