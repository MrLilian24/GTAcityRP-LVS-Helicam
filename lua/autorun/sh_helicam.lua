-- sh_helicam.lua - Shared
-- Created by Rémi.L (https://steamcommunity.com/id/lilian24)

-- Get direction from an angle (driver seat = direction of the heli)
function GetDirection(angle)
    local directions = {
        {0, "N ↑"},
        {45, "NE ↗"},
        {90, "E →"},
        {135, "SE ↘"},
        {180, "S ↓"},
        {-135, "SW ↙"},
        {-90, "W ←"},
        {-45, "NW ↖"}
    }

    -- Get the closest corresponding direction
    for _, dir in ipairs(directions) do
        if math.abs(angle - dir[1]) <= 22.5 then
            return dir[2]
        end
    end

    return ""
end

-- Check if a player is in an valid helicopter
function IsInHeli(ply)
    return ply and ply:GetVehicle():GetParent().Base:find("lvs_base") 
end
